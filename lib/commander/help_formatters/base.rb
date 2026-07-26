# frozen_string_literal: true

module Commander
  module HelpFormatter
    ##
    # Base class for help formatters. Subclasses receive the
    # Commander::Runner instance being documented and must implement
    # #render (global help) and #render_command (per-command help). This
    # base implementation renders placeholder text and exists mainly for
    # testing and as a minimal example.
    class Base
      def initialize(runner)
        @runner = runner
      end

      ##
      # Render the global help text shown for <tt>--help</tt> with no
      # command, or the +help+ command with no arguments.

      def render
        'Implement global help here'
      end

      ##
      # Render the help text for a single _command_.

      def render_command(command)
        "Implement help for #{command.name} here"
      end
    end
  end
end
