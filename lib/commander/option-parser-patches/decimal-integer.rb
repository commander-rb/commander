# Patches the underling OptionParser DecimalInteger type so that it doesn't
# convert numbers starting with a '0' as if they are an Octal number
module Commander
  module OptionParserPatches
    module DecimalInteger
      decimal = '\d+(?:_\d+)*'
      DecimalInteger = /\A[-+]?#{decimal}\z/io
      ::OptionParser::accept(DecimalInteger, DecimalInteger) {|s,|
        begin
          Integer(s, 10)
        rescue ArgumentError
          raise ::OptionParser::InvalidArgument, s
        end if s
      }
    end
  end
end