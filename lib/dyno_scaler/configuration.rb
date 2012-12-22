# encoding: utf-8

module DynoScaler
  class Configuration
    ##
    # Contains the max amount of workers that are allowed to run concurrently
    #
    # @return [Fixnum] default: 1
    attr_accessor :max_workers

    ##
    # Contains the min amount of workers that should always be running
    #
    # @return [Fixnum] default: 0
    attr_accessor :min_workers

    ##
    # Contains the ratio used to spawn more workers given a number of jobs.
    #
    # The given hash should have the number of workers as a key, and the number
    # of queued jobs that are needed in order to spawn that number of workers
    # as the value.
    #
    # For example, if you wanted to spawn a second worker once 6 jobs are queued
    # then spawn another third worker once 10 jobs are queued you could configure
    # this option as:
    #
    #   config.job_worker_ratio = {
    #     1 => 1,
    #     2 => 6,
    #     3 => 10
    #   }
    #
    # @param [Hash] with job worker ratio
    # @return [Hash] default to { 1 => 1, 2 => 25, 3 => 50, 4 => 75, 5 => 100 }
    attr_accessor :job_worker_ratio

    ##
    # Default is false when HEROKU_API_KEY environment variable is not set,
    # otherwise defaults to true.
    #
    # @param [Boolean] whether to enable scaling or not
    # @return [Boolean] default: false
    attr_accessor :enabled
    alias enabled? enabled

    ##
    # Default is nil when HEROKU_APP environment variable is not set,
    # otherwise defaults to its value.
    #
    # @param [String] the name of the Heroku application used when scaling workers
    # @return [String] default: nil
    attr_accessor :application

    def initialize
      self.max_workers      = 1
      self.min_workers      = 0
      self.enabled          = !ENV['HEROKU_API_KEY'].nil?
      self.application      = ENV['HEROKU_APP']

      self.job_worker_ratio = {
        1 => 1,
        2 => 25,
        3 => 50,
        4 => 75,
        5 => 100
      }
    end

    # Returns the current configured async Proc or configures one.
    def async(&block)
      @async = block if block_given?
      @async
    end
    alias_method :async?, :async

    ##
    # When set to true it will use GirlFriday to asynchronous process the scaling,
    # otherwise you may pass a Proc that will be called whenever scaling is needed.
    #
    # Defaults to false, meaning that scaling is processed synchronously.
    def async=(value)
      @async = value == true ? default_async_processor : value
    end

    private
      def default_async_processor
        require 'girl_friday'

        queue = GirlFriday::WorkQueue.new(nil, :size => 1) do |options|
          DynoScaler.manager.scale_with(options)
        end

        Proc.new { |options| queue << options }
      end
  end
end