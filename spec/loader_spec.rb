require 'spec_helper'

describe Commander::Loader do

  describe '.instance' do
    it 'should return an instance of the class' do
      expect(described_class.instance).to be_an_instance_of(described_class)
    end

    it 'should return a singleton instance' do
      expect(described_class.instance).to equal(described_class.instance)
    end
  end

  describe '#with_command_context' do
    context 'with a block' do
      it 'should return the yielded result' do
        expect(subject.with_command_context { 'foo' }).to eq('foo')
      end
    end

    context 'without a block' do
      it 'should return nil' do
        expect(subject.with_command_context).to be_nil
      end
    end
  end

  describe '#load_file' do
    context 'when the file exists' do
      it 'should not raise an error' do
        expect { subject.load_file(File.expand_path('../support/commands/loaded_test.rb', __FILE__)) }.to_not raise_error
      end

      it 'should load the command defined in the file into the runner instance' do
        subject.load_file File.expand_path('../support/commands/loaded_test.rb', __FILE__)
        expect(Commander::Runner.instance.command_exists?(:loaded_test)).to be_truthy
      end
    end

    context 'when the file does not exist' do
      it 'should raise a LoadError' do
        expect { subject.load_file(File.expand_path('../support/commands/doesnt_exist.rb', __FILE__)) }.to raise_error(LoadError)
      end
    end
  end

  describe '#load_files' do
    context 'when the files exist' do
      it 'should not raise an error' do
        expect { subject.load_files([File.expand_path('../support/commands/loaded_test.rb', __FILE__)]) }.to_not raise_error
      end

      it 'should load the commands defined in the files into the runner instance' do
        subject.load_files [File.expand_path('../support/commands/loaded_test.rb', __FILE__)]
        expect(Commander::Runner.instance.command_exists?(:loaded_test)).to be_truthy
      end
    end

    context 'when the files do not exist' do
      it 'should raise a LoadError' do
        expect { subject.load_files([File.expand_path('../support/commands/doesnt_exist.rb', __FILE__)]) }.to raise_error(LoadError)
      end
    end
  end
end
