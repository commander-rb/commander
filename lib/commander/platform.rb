# frozen_string_literal: true

module Commander
  ##
  # = Platform
  #
  # Small helpers for detecting the running Ruby engine.
  module Platform
    ##
    # Whether the current process is running under JRuby.
    def self.jruby?
      defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'jruby')
    end
  end
end
