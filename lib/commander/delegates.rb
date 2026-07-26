# frozen_string_literal: true

module Commander
  ##
  # = Delegates
  #
  # Mixed into Commander::Methods to expose the singleton
  # Commander::Runner instance's DSL (+command+, +program+, +run!+, etc.)
  # as top-level methods, so scripts can call them directly instead of
  # reaching through <tt>Commander::Runner.instance</tt>.
  module Delegates
    %w(
      add_command
      command
      program
      run!
      global_option
      alias_command
      default_command
      always_trace!
      never_trace!
    ).each do |meth|
      eval <<-END, binding, __FILE__, __LINE__ + 1
        def #{meth}(*args, &block)
          ::Commander::Runner.instance.#{meth}(*args, &block)
        end
      END
    end

    ##
    # Delegates to Commander::Runner#commands, returning the hash of
    # registered command name => Commander::Command pairs.

    def defined_commands(...)
      ::Commander::Runner.instance.commands(...)
    end
  end
end
