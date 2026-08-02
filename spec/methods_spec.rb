# frozen_string_literal: true

require 'spec_helper'
require 'commander/methods'

describe Commander::Methods do
  it 'includes Commander::UI' do
    expect(subject.ancestors).to include(Commander::UI)
  end

  describe 'AskForClass' do
    it 'includes Commander::UI::AskForClass' do
      expect(subject.ancestors).to include(Commander::UI::AskForClass)
    end

    describe 'defining methods' do
      let(:terminal) { double }

      before do
        allow(terminal).to receive(:ask)
        @old_highline = HighLine.default_instance
        HighLine.default_instance = terminal
      end

      after do
        HighLine.default_instance = @old_highline
      end

      subject do
        Class.new do
          include Commander::UI::AskForClass
        end.new
      end

      it 'defines common "ask_for_*" methods' do
        expect(subject.respond_to?(:ask_for_float)).to be_truthy
      end

      it 'implements the common "ask_for_*" methods by asking HighLine for the class' do
        expect(terminal).to receive(:ask).with('Favorite number: ', Float)
        subject.ask_for_float('Favorite number: ')
      end

      it 'responds to "ask_for_*" methods for classes that implement #parse' do
        expect(subject.respond_to?(:ask_for_datetime)).to be_truthy
      end

      it 'fails "ask_for_*" method invocations without a prompt' do
        expect do
          subject.ask_for_datetime
        end.to raise_error(ArgumentError)
      end

      it 'implements "ask_for_*"' do
        expect(terminal).to receive(:ask)
        subject.ask_for_datetime('hi')
      end

      it 'falls through to the default #method_missing when no matching class is found' do
        expect do
          subject.ask_for_not_a_real_class('hi')
        end.to raise_error(NoMethodError)
      end

      it 'falls through to the default #method_missing for unrelated methods' do
        expect { subject.not_an_ask_for_method }.to raise_error(NoMethodError)
      end
    end
  end

  it 'includes Commander::Delegates' do
    expect(subject.ancestors).to include(Commander::Delegates)
  end

  it 'does not change the Object ancestors' do
    expect(Object.ancestors).not_to include(Commander::UI)
  end

  describe 'terminal wrapping' do
    # Both scenarios live in a single example, loading the module file
    # (rather than requiring it) so the tty-dependent code at the bottom
    # of commander/methods.rb re-runs against a stubbed $stdin each time.
    it 'only sets HighLine wrap_at when connected to a wide enough terminal' do
      methods_file = File.expand_path('../lib/commander/methods.rb', __dir__)
      terminal = HighLine.new(StringIO.new, StringIO.new)
      allow(terminal).to receive(:output_cols).and_return(80)
      HighLine.default_instance = terminal

      allow($stdin).to receive(:tty?).and_return(false)
      load methods_file
      expect(terminal.wrap_at).to be_nil

      allow($stdin).to receive(:tty?).and_return(true)
      load methods_file
      expect(terminal.wrap_at).to eq(75)
    end
  end
end
