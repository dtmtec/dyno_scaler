source 'https://rubygems.org'

# Specify your gem's dependencies in dyno_scaler.gemspec
gemspec

group(:development) do
  platforms :ruby do
    gem 'byebug'
  end

  platforms :jruby do
    gem 'ruby-debug'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end

group(:test) do
  gem 'simplecov', require: false
  gem 'rspec'
  gem 'rspec-its'
  gem 'resque'
  gem 'girl_friday'
  gem 'rails'
end
