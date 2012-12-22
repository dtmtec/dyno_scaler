# encoding: utf-8

require 'active_support/concern'

module DynoScaler
  module Workers
    module Resque
      extend ActiveSupport::Concern

      included do
        class_attribute :scale_up_enabled
        class_attribute :scale_down_enabled

        enable_scaling_up
        enable_scaling_down
      end

      module ClassMethods
        def after_perform_scale_down(*args)
          info = ::Resque.info
          working = info[:working] > 0 ? info[:working] - 1 : 0

          manager.scale_down(info[:workers], info[:pending], working) if scale_down_enabled?
        end

        def after_enqueue_scale_up(*args)
          info = ::Resque.info

          manager.scale_up(info[:workers], info[:pending]) if scale_up_enabled?
        end

        def enable_scaling_up
          self.scale_up_enabled = true
        end

        def enable_scaling_down
          self.scale_down_enabled = true
        end

        def disable_scaling_up
          self.scale_up_enabled = false
        end

        def disable_scaling_down
          self.scale_down_enabled = false
        end

        def manager
          @manager ||= DynoScaler::Manager.new
        end
      end
    end
  end
end
