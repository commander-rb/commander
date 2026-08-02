# frozen_string_literal: true

require 'erb'

module Commander
  module HelpFormatter
    ##
    # The default help formatter. Renders full-width, verbosely-labeled
    # help text (examples, per-option descriptions, etc.) from the ERB
    # templates in the neighboring +terminal/+ directory. See
    # HelpFormatter::TerminalCompact for a more condensed alternative.
    class Terminal < Base
      ##
      # Render the global help text for the program.
      def render
        template(:help).result(ProgramContext.new(@runner).get_binding)
      end

      ##
      # Render the help text for a single _command_.
      def render_command(command)
        template(:command_help).result(Context.new(command).get_binding)
      end

      ##
      # Compile the ERB template named _name_ (+:help+ or
      # +:command_help+) from this formatter's template directory.
      def template(name)
        ERB.new(File.read(File.join(File.dirname(__FILE__), 'terminal', "#{name}.erb")), trim_mode: '-')
      end
    end
  end
end
