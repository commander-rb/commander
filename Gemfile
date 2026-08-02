# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'bundler-audit', '~> 0.9'
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.88'
  # 1.x requires Ruby >= 3.2; allow the last 0.x on Ruby 3.1 while newer
  # rubies still resolve to 1.x.
  gem 'simplecov', '>= 0.22', '< 2'
end
