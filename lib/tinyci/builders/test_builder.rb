# frozen_string_literal: true

require 'tinyci/executor'

module TinyCI
  module Builders
    class TestBuilder < TinyCI::Executor
      def build
        raise 'Simulated build failed' if @config[:result] == false
      end
    end
  end
end
