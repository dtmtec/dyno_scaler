# DynoScaler

[![alt build status][1]][2]

[1]: https://travis-ci.org/dtmconsultoria/dyno_scaler.png?branch=master
[2]: http://travis-ci.org/dtmconsultoria/dyno_scaler

Scale your dyno workers on Heroku as needed, pay only for what you use!

## Installation

Add this line to your application's Gemfile:

    gem 'dyno_scaler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dyno_scaler

## Usage

Just include this module in your Resque job and you're good to go:

    class MyJob
      include DynoScaler::Workers::Resque

      ...
    end

You can access the configuration with (for example):

    DynoScaler.configuration.max_workers = 3

In Rails, you can access it easily in your application.rb:

    config.dyno_scaler.max_workers = 3

If you want to scale up or down your workers manually, you can use the manager
directly:

    DynoScaler.manager.scale_up(options)
    DynoScaler.manager.scale_down(options)

You must pass an options hash with the number of workers, the number of pending
jobs, and the number of running jobs, like so:

    {
      workers: 10,
      working: 3,
      pending: 5
    }

`Resque.info` returns a hash with these keys, so you may just pass it instead:

    DynoScaler.manager.scale_up(Resque.info)

## Async

Whenever DynoScaler needs to scale workers up it will perform a request to the
Heroku API. This request may sometimes take longer to return than one would want.
Because of this we have a async option that uses
[GirlFriday](https://github.com/mperham/girl_friday) to handle this call
asynchronously. To enable it, just set it to `true`:

    config.dyno_scaler.async = true

You can also give it a block to better customize it. It will receive an options
hash that can be passed to the `DynoScaler::Manager#scale_with` method, like so:

    MY_QUEUE = GirlFriday::WorkQueue.new(:my_queue, size: 5) do |options|
      DynoScaler.manager.scale_with(options)
    end

    config.dyno_scaler.async { MY_QUEUE << options }

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
