# frozen_string_literal: true

module TinyCI
  module Symbolize
    # recursively make all keys of `hash` into symbols
    # @param [Hash] hash The hash
    def symbolize(hash)
      {}.tap do |h|
        hash.each { |key, value| h[key.to_sym] = map_value(value) }
      end
    end

    def map_value(thing)
      case thing
      when Hash
        symbolize thing
      when Array
        thing.map { |v| map_value(v) }
      else
        thing
      end
    end
  end
end
