# frozen_string_literal: true

require 'spec_helper'

describe Commander::Platform do
  describe '.jruby?' do
    it 'reflects whether the current engine is JRuby' do
      expect(Commander::Platform.jruby?).to eq(RUBY_ENGINE == 'jruby')
    end
  end
end
