# frozen_string_literal: true

require 'commander/patches/validate_inputs'

# These specs inspired by those in Commander gem in `spec/runner_spec.rb`.

RSpec.describe Commander::Patches::ValidateInputs do
  include Commander::Delegates

  def mock_terminal
    @input = StringIO.new
    @output = StringIO.new
    $terminal = HighLine.new @input, @output
  end

  def create_test_command
    command :test do |c|
      c.syntax = 'metal test ARG1 ARG2 [OPTIONAL_ARG3] [options]'
      c.description = 'test description'
      c.example 'description', 'command'
      c.option '-o', '--some-option', 'Some option that does things'
      c.when_called do |args, _options|
        format('test %<foo>s', foo: args.join(' '))
      end
    end
    @command = command :test
  end

  def create_multi_word_test_command
    command :'test do' do |c|
      c.syntax = 'metal test do ARG1 ARG2 [options]'
      c.when_called do |args, _options|
        format('test do %<foo>s', foo: args.join(' '))
      end
    end
    @command = command :'test do'
  end

  before do
    $stderr = StringIO.new
    mock_terminal
    create_test_command
  end

  describe '#call' do
    describe 'syntax validating' do
      it 'raises if first word is not CLI name' do
        command :test do |c|
          c.syntax = 'not_metal test [options]'
        end

        expect do
          command(:test).call
        end.to raise_error(Commander::Patches::CommandDefinitionError)
      end

      it 'raises if second word is not command name' do
        command :test do |c|
          c.syntax = 'metal not_test [options]'
        end

        expect do
          command(:test).call
        end.to raise_error(Commander::Patches::CommandDefinitionError)
      end

      it 'raises if last word is not [options]' do
        command :test do |c|
          c.syntax = 'metal test [not_options]'
        end

        expect do
          command(:test).call
        end.to raise_error(Commander::Patches::CommandDefinitionError)
      end

      describe 'when multi-word command' do
        it 'raises if corresponding syntax words do not form command name' do
          command :'test do' do |c|
            c.syntax = 'metal test not_do [options]'
          end

          expect do
            command(:'test do').call
          end.to raise_error(
            Commander::Patches::CommandDefinitionError
          ).with_message(
            "Command name(s) should come after CLI name e.g. 'test do'"
          )
        end
      end
    end

    describe 'validating passed arguments against syntax' do
      it 'raises if too many arguments given' do
        expect do
          command(:test).call(['one', 'two', 'three', 'four'])
        end.to raise_error(Commander::Patches::CommandUsageError)
      end

      it 'raises if too few arguments given' do
        expect do
          command(:test).call(['one'])
        end.to raise_error(Commander::Patches::CommandUsageError)
      end

      it 'proceeds as normal if valid number of arguments given' do
        expect(
          command(:test).call(['one', 'two', 'three'])
        ).to eql('test one two three')
      end

      describe 'when multi-word command' do
        before do
          create_multi_word_test_command
        end

        it 'raises if too few arguments given' do
          expect do
            command(:'test do').call
          end.to raise_error(Commander::Patches::CommandUsageError)
        end

        it 'proceeds as normal if valid number of arguments given' do
          expect(
            command(:'test do').call(['one', 'two'])
          ).to eql('test do one two')
        end
      end
    end
  end
end
