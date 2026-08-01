# frozen_string_literal: true

module Commander
  ##
  # = Help Formatter
  #
  # Commander's help formatters control the output when
  # either the help command, or --help switch are called.
  # The default formatter is Commander::HelpFormatter::Terminal.
  module HelpFormatter
    autoload :Base, 'commander/help_formatters/base'
    autoload :Terminal, 'commander/help_formatters/terminal'
    autoload :TerminalCompact, 'commander/help_formatters/terminal_compact'

    ##
    # Exposes _target_'s binding to an ERB template, letting the template
    # reference _target_'s instance variables and private methods as if
    # they were local variables/bare method calls. Subclasses can inject
    # additional template-local variables by overriding #decorate_binding.
    class Context
      def initialize(target)
        @target = target
      end

      ##
      # The (possibly decorated) binding of _target_, suitable for
      # passing to ERB#result.
      def get_binding
        @target.instance_eval { binding }.tap do |bind|
          decorate_binding(bind)
        end
      end

      # No-op, override in subclasses.
      def decorate_binding(_bind)
      end
    end

    ##
    # A Context for rendering the global help template (see
    # HelpFormatter::Terminal#render), decorating the target Runner's
    # binding with +max_command_length+/+max_aliases_length+ locals so
    # the template can align its columns.
    class ProgramContext < Context
      def decorate_binding(bind)
        bind.eval("max_command_length = #{max_command_length(bind)}")
        bind.eval("max_aliases_length = #{max_aliases_length(bind)}")
      end

      ##
      # Length, in characters, of the longest registered command name.
      def max_command_length(bind)
        max_key_length(bind.eval('@commands'))
      end

      ##
      # Length, in characters, of the longest registered command alias.
      def max_aliases_length(bind)
        max_key_length(bind.eval('@aliases'))
      end

      ##
      # Length of the longest key in _hash_, or _default_ when _hash_ is empty.
      def max_key_length(hash, default = 20)
        longest = hash.keys.max_by(&:size)
        longest ? longest.size : default
      end
    end

    module_function

    ##
    # Indent each line of _text_ (after the first) by _amount_ spaces.
    # Used by the help templates to align multi-line descriptions.
    def indent(amount, text)
      text.to_s.gsub("\n", "\n#{' ' * amount}")
    end
  end
end
