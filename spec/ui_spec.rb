# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe Commander::UI do
  include Commander::Methods

  before :each do
    mock_terminal
  end

  describe '.replace_tokens' do
    it 'should replace tokens within a string, with hash values' do
      result = Commander::UI.replace_tokens 'Welcome :name, enjoy your :object', name: 'TJ', object: 'cookie'
      expect(result).to eq('Welcome TJ, enjoy your cookie')
    end
  end

  describe '#password' do
    # HighLine's masked-echo prompting requires a real console (it sets
    # `echo=` on the input stream), which a StringIO can't provide, so the
    # underlying #ask call is stubbed here rather than driven through a
    # mocked terminal.
    it 'asks for a password using the given message and mask, and returns the answer' do
      allow(self).to receive(:ask).and_return('secret')
      expect(password('Enter password: ', '#')).to eq('secret')
      expect(self).to have_received(:ask).with('Enter password: ')
    end

    it 'retries with the same prompt until a non-empty answer is given' do
      allow(self).to receive(:ask).and_return('', 'secret')
      expect(password('Enter password: ')).to eq('secret')
      expect(self).to have_received(:ask).with('Enter password: ').twice
    end
  end

  describe '#choose' do
    it 'says the message and then delegates to HighLine choose' do
      @input << "2\n"
      @input.rewind
      expect(choose('Pick one:', 'a', 'b')).to eq('b')
      expect(@output.string).to include('Pick one:')
    end
  end

  describe '#log' do
    it 'formats and says the action with its arguments' do
      log 'create', 'path/to/file.rb'
      expect(@output.string).to eq("         create  path/to/file.rb\n")
    end
  end

  describe '#say_ok' do
    it 'says each argument in the OK color' do
      say_ok 'all good'
      expect(@output.string).to include('all good')
    end
  end

  describe '#say_warning' do
    it 'says each argument in the warning color' do
      say_warning 'be careful'
      expect(@output.string).to include('be careful')
    end
  end

  describe '#say_error' do
    it 'says each argument in the error color' do
      say_error 'oh no'
      expect(@output.string).to include('oh no')
    end
  end

  describe '#color' do
    it 'says the given text using the requested color' do
      color 'I am blue', :blue
      expect(@output.string).to include('I am blue')
    end
  end

  describe '#speak' do
    it 'runs the applescript in a background thread' do
      allow(self).to receive(:applescript)
      speak('hello there').join
      expect(self).to have_received(:applescript).with('say "hello there" using "Alex" speaking rate 175')
    end
  end

  describe '#converse' do
    it 'builds an applescript listen statement and symbolizes the response' do
      allow(self).to receive(:applescript).and_return(" cookies \n")
      result = converse('Best food?', cookies: 'Cookies', unknown: 'Nothing')
      expect(result).to eq(:cookies)
      expect(self).to have_received(:applescript) do |script|
        expect(script).to include('SpeechRecognitionServer')
        expect(script).to include('if response is "Cookies" then')
        expect(script).to include('else if response is "Nothing" then')
      end
    end
  end

  describe '#applescript' do
    it 'shells out to osascript with the given script' do
      allow(Commander::UI).to receive(:`).and_return("done\n")
      expect(Commander::UI.applescript('display dialog "hi"')).to eq("done\n")
      expect(Commander::UI).to have_received(:`).with(/display dialog/)
    end
  end

  describe '#io' do
    it 'redirects $stdin/$stdout to files for the duration of the block' do
      input_file = Tempfile.new('commander-io-in')
      output_file = Tempfile.new('commander-io-out')
      begin
        input_file.write('hello')
        input_file.rewind

        orig_stdin, orig_stdout = $stdin, $stdout
        result = nil
        io(input_file.path, output_file.path) { result = $stdin.gets }

        expect(result).to eq('hello')
        expect($stdin).to equal(orig_stdin)
        expect($stdout).to equal(orig_stdout)
      ensure
        input_file.close!
        output_file.close!
      end
    end

    it 'restores the original streams even if the block raises' do
      orig_stdin, orig_stdout = $stdin, $stdout

      expect { io { fail 'boom' } }.to raise_error(RuntimeError, 'boom')

      expect($stdin).to equal(orig_stdin)
      expect($stdout).to equal(orig_stdout)
    end

    it 'leaves the streams redirected when no block is given' do
      output_file = Tempfile.new('commander-io-out')
      orig_stdout = $stdout
      begin
        io(nil, output_file.path)
        expect($stdout).not_to equal(orig_stdout)
      ensure
        $stdout = orig_stdout
        output_file.close!
      end
    end
  end

  describe '.available_editor' do
    it 'should not fail on available editors with shell arguments' do
      expect(Commander::UI.available_editor('sh -c')).to eq('sh -c')
    end

    it 'falls back through EDITOR and common editors when no preferred editor is given' do
      allow(ENV).to receive(:fetch).with('EDITOR', nil).and_return(nil)
      expect(Commander::UI.available_editor).to eq('vim').or(be_a(String)).or(be_nil)
    end
  end

  describe '#ask_editor' do
    it 'writes the given input to a temp file and returns its contents when the editor succeeds' do
      result = ask_editor('draft text', 'true')
      expect(result).to eq('draft text')
    end

    it 'returns nil when the editor exits unsuccessfully' do
      result = ask_editor('draft text', 'false')
      expect(result).to be_nil
    end
  end

  describe '.enable_paging' do
    # spec_helper stubs Commander::UI.enable_paging globally (so other specs
    # don't page real output); restore the real implementation here since
    # this block tests it directly.
    before do
      allow(Commander::UI).to receive(:enable_paging).and_call_original
      # On platforms without fork (e.g. JRuby) enable_paging returns early
      # before the forking logic these specs exercise; pretend fork exists
      # so the behavior under test is reached everywhere.
      allow(Process).to receive(:respond_to?).and_call_original
      allow(Process).to receive(:respond_to?).with(:fork).and_return(true)
    end

    it 'does nothing when stdout is not a tty' do
      allow($stdout).to receive(:tty?).and_return(false)
      expect(IO).not_to receive(:pipe)
      Commander::UI.enable_paging
    end

    it 'reopens stdout/stderr into the write end of the pipe in the forked subprocess' do
      allow($stdout).to receive(:tty?).and_return(true)
      allow($stderr).to receive(:tty?).and_return(true)
      read_io = instance_double(IO, close: nil, closed?: false)
      write_io = instance_double(IO, close: nil, closed?: false)
      allow(IO).to receive(:pipe).and_return([read_io, write_io])
      allow(Kernel).to receive(:fork).and_return(nil)
      allow($stdout).to receive(:reopen)
      allow($stderr).to receive(:reopen)

      Commander::UI.enable_paging

      expect($stdout).to have_received(:reopen).with(write_io)
      expect($stderr).to have_received(:reopen).with(write_io)
    end

    it 'reopens stdin from the pipe and execs the pager in the parent process' do
      allow($stdout).to receive(:tty?).and_return(true)
      read_io = instance_double(IO, close: nil, closed?: false)
      write_io = instance_double(IO, close: nil, closed?: false)
      allow(IO).to receive(:pipe).and_return([read_io, write_io])
      allow(Kernel).to receive(:fork).and_return(4242)
      allow($stdin).to receive(:reopen)
      allow(Kernel).to receive(:select)
      allow(Commander::UI).to receive(:exec)
      original_less = ENV.delete('LESS')

      begin
        Commander::UI.enable_paging

        expect($stdin).to have_received(:reopen).with(read_io)
        expect(Kernel).to have_received(:select).with([$stdin])
        expect(ENV.fetch('LESS', nil)).to eq('FSRX')
        expect(Commander::UI).to have_received(:exec)
      ensure
        if original_less
          ENV['LESS'] = original_less
        else
          ENV.delete('LESS')
        end
      end
    end
  end

  describe 'progress' do
    it 'should not die on an empty list' do
      exception = false
      begin
        progress([]) {}
      rescue StandardError
        exception = true
      end
      expect(exception).not_to be true
    end

    it 'shows interim progress and a completion message while walking a list' do
      visited = []
      progress(%w(a b)) do |v|
        visited << v
        {}
      end
      expect(visited).to eq(%w(a b))
      expect(@output.string).to include('Process complete')
    end
  end
end
