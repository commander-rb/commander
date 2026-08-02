# frozen_string_literal: true

##
# Commander is the top-level namespace for the whole gem: see
# Commander::Methods for the DSL mixin, Commander::Runner for the engine
# that drives it, and Commander::Command for individual commands.
module Commander
  ##
  # Runs a Commander program within an isolated, anonymous module rather
  # than polluting the including object (as Commander::Methods normally
  # does when included directly). Useful for embedding a Commander CLI
  # inside a larger application without leaking its DSL methods. Calls
  # Runner#run! once the block has finished configuring commands.
  #
  # Any _configuration_opts_ are passed through as block arguments.
  #
  # === Examples
  #
  #   Commander.configure do
  #     program :name, 'my-tool'
  #     program :version, '1.0.0'
  #     program :description, 'Does something useful'
  #
  #     command :greet do |c|
  #       c.action { |args, _options| say "Hello, #{args.first}!" }
  #     end
  #   end
  #
  #   Commander.configure(default_name) do |name|
  #     program :name, name
  #   end
  def configure(*configuration_opts, &)
    configuration_module = Module.new
    configuration_module.extend Commander::Methods

    configuration_module.class_exec(*configuration_opts, &)

    configuration_module.class_exec do
      run!
    end
  end

  module_function :configure
end
