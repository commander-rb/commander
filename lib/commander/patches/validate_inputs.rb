# frozen_string_literal: true

module Commander
  module Patches
    # An error in the definition of a command, which we cannot recover from and
    # should be fixed in the code.
    class CommandDefinitionError < StandardError; end

    # An error in the usage of a command; will happen in practise and error
    # message should be shown along with command usage info.
    class CommandUsageError < StandardError; end

    module ValidateInputs
      def run(*args)
        super(*args)
      rescue CommandUsageError => error
        abort "error: #{error}. Usage: #{syntax}"
      end

      def call(args = [])
        # Use defined syntax to validate how many args this command can be
        # passed.
        validate_syntax!
        validate_correct_number_of_args!(args)

        # Invoke original method.
        super(args)
      end

      private

      def validate_syntax!
        cli_name = 'metal'
        command_syntax = command_syntax_parts.join(' ')

        if syntax_parts.first != cli_name
          raise CommandDefinitionError,
                "Expected CLI name first ('#{cli_name}')"
        elsif command_syntax != name
          raise CommandDefinitionError,
                "Command name(s) should come after CLI name e.g. '#{name}'"
        elsif syntax_parts.last != '[options]'
          raise CommandDefinitionError, <<-EOF.squish
                Last word in 'syntax' should be '[options]',
                got '#{syntax_parts.last}'
          EOF
        end
      end

      def validate_correct_number_of_args!(args)
        if too_many_args?(args)
          raise CommandUsageError, 'Too many arguments given'
        elsif too_few_args?(args)
          raise CommandUsageError, 'Too few arguments given'
        end
      end

      def syntax_parts
        syntax.split
      end

      def command_syntax_parts
        number_command_words = name.split.length
        syntax_parts[1, number_command_words]
      end

      def arguments_syntax_parts
        args_start_index = 1 + command_syntax_parts.length
        args_end_index = syntax_parts.length - 1
        syntax_parts[args_start_index...args_end_index]
      end

      def total_arguments
        arguments_syntax_parts.length
      end

      def optional_arguments
        arguments_syntax_parts.select do |part|
          part[0] == '[' && part[-1] == ']'
        end.length
      end

      def required_arguments
        total_arguments - optional_arguments
      end

      def too_many_args?(args)
        args.length > total_arguments
      end

      def too_few_args?(args)
        args.length < required_arguments
      end
    end
  end
end
