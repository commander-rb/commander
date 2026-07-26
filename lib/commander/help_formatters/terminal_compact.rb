# frozen_string_literal: true

require 'erb'

module Commander
  module HelpFormatter
    ##
    # A condensed variant of HelpFormatter::Terminal, using the ERB
    # templates in the neighboring +terminal_compact/+ directory. Enable
    # it with <tt>program :help_formatter, :compact</tt>.
    class TerminalCompact < Terminal
      ##
      # Compile the ERB template named _name_ (+:help+ or
      # +:command_help+) from this formatter's template directory.

      def template(name)
        ERB.new(File.read(File.join(File.dirname(__FILE__), 'terminal_compact', "#{name}.erb")), trim_mode: '-')
      end
    end
  end
end
