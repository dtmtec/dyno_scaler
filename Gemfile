source 'https://rubygems.org'

# Specify your gem's dependencies in dyno_scaler.gemspec
gemspec

group(:development) do
  platforms :mri_19 do
    gem 'debugger'
  end

  platforms :jruby do
    gem 'ruby-debug'
    gem 'jruby-openssl'
  end
end

group(:test) do
  gem 'simplecov', require: false
  gem 'rails'
end
