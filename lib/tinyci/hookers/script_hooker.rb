# frozen_string_literal: true

require 'tinyci/executor'

module TinyCI
  module Hookers
    class ScriptHooker < TinyCI::Executor
      # All the hooks
      HOOKS = %w[
        before_build

        after_build_success
        after_build_failure

        after_build

        before_test

        after_test_success
        after_test_failure

        after_test

        after_all
      ].freeze

      # Those hooks that will halt exectution if they fail
      BLOCKING_HOOKS = %w[
        before_build
        before_test
      ].freeze

      HOOKS.each do |hook|
        define_method hook + '_present?' do
          @config.key? hook.to_sym
        end

        define_method hook + '!' do
          return unless send("#{hook}_present?")

          log_info "executing #{hook} hook..."
          begin
            execute_stream(script_location(hook), label: hook, pwd: @config[:export])

            return true
          rescue SubprocessError => e
            return true unless BLOCKING_HOOKS.include? hook

            raise e if ENV['TINYCI_ENV'] == 'test'

            log_error e
            return false
          end
        end
      end

      def script_location(hook)
        ['/bin/sh', '-c', "'#{interpolate(@config[hook.to_sym])}'"]
      end
    end
  end
end
