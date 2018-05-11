# frozen_string_literal: true

module Commander
  module Patches
    # An error in the usage of a command; will happen in practise and error
    # message should be shown along with command usage info.
    class CommandUsageError < StandardError; end

    module ValidateInputs
      # This is used to switch the Patch off during the original test of
      # Commander. It is VERY MUCH a hack but it works
      PatchEnabled = true

      def run(*args)
        super(*args)
      rescue CommandUsageError => error
        abort "error: #{error}. Usage: #{syntax}"
      end

      def call(args = [])
        return super unless PatchEnabled
        return super if syntax_parts[0..1] == ['commander', 'help']

        # Use defined syntax to validate how many args this command can be
        # passed.
        validate_correct_number_of_args!(args)

        # Invoke original method.
        super(args)
      end

      private

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
