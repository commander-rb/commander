# frozen_string_literal: true

require 'spec_helper'

describe Commander::Delegates do
  include Commander::Methods

  before :each do
    mock_terminal
    new_command_runner
  end

  describe '#defined_commands' do
    it 'delegates to the runner instance and returns its commands' do
      expect(defined_commands).to eq(Commander::Runner.instance.commands)
    end
  end
end
