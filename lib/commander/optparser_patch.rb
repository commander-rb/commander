class OptionParser
  def parse_in_order(argv = default_argv, setter = nil, &nonopt)  # :nodoc:
    opt, arg, val, rest = nil
    nonopt ||= proc {|a| throw :terminate, a}
    argv.unshift(arg) if arg = catch(:terminate) {
      while arg = argv.shift
        case arg
        # long option
        when /\A--([^=]*)(?:=(.*))?/m
          opt, rest = $1, $2
          opt.tr!('_', '-')
          begin
            sw, = complete(:long, opt, true)
          rescue ParseError
            raise $!.set_option(arg, true)
          end
          begin
            opt, cb, val = sw.parse(rest, argv) {|*exc| raise(*exc)}
            val = cb.call(val) if cb
            setter.call(sw.switch_name, val) if setter
          rescue ParseError
            raise $!.set_option(arg, rest)
          end

        # short option
        when /\A-(.)((=).*|.+)?/m
          eq, rest, opt = $3, $2, $1
          has_arg, val = eq, rest
          begin
            sw, = search(:short, opt)
            unless sw
              sw, = complete(:short, opt)
              # short option matched.
              val = arg.sub(/\A-/, '')
              has_arg = true
            end
          rescue ParseError
            raise $!.set_option(arg, true)
          end
          begin
            opt, cb, val = sw.parse(val, argv) {|*exc| raise(*exc) if eq}
            raise InvalidOption, arg if has_arg and !eq and arg == "-#{opt}"
            argv.unshift(opt) if opt and (!rest or (opt = opt.sub(/\A-*/, '-')) != '-')
            val = cb.call(val) if cb
            setter.call(sw.switch_name, val) if setter
          rescue ParseError
            raise $!.set_option(arg, arg.length > 2)
          end

        # non-option argument
        else
          catch(:prune) do
            visit(:each_option) do |sw0|
              sw = sw0
              sw.block.call(arg) if Switch === sw and sw.match_nonswitch?(arg)
            end
            nonopt.call(arg)
          end
        end
      end

      nil
    }

    visit(:search, :short, nil) {|sw| sw.block.call(*argv) if !sw.pattern}

    argv
  end
end