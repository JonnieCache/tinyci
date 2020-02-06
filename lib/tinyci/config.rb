# frozen_string_literal: true

require 'tinyci/config_transformer'
require 'tinyci/symbolize'
require 'yaml'

module TinyCI
  # Represents the Configuration for a repo, parsed from the `.tinyci.yml` file in the repo root.
  # Mainly a wrapper around a the hash object parsed from the yaml in the config file.
  # The keys of the hash are recursively symbolized.
  #
  # As it is loaded, the configuration file data is passed through the {TinyCI::ConfigTransformer}
  # class, which translates any definitions in the concise format into the more verbose format
  class Config
    include Symbolize

    attr_accessor :config_path

    # Constructor
    #
    # @param [String] working_dir The working directory in which to find the config file
    # @param [String] config_path Override the path to the config file
    # @param [String] config Override the config content
    #
    # @raise [ConfigMissingError] if the config file is not found
    def initialize(config_path, config: nil)
      @config_path = config_path
      @config_content = config

      raise ConfigMissingError, "config file #{config_path} not found" unless config_file_exists?
    end

    # Address into the config object
    #
    # @param [Symbol] key The key to address
    def [](key)
      config_content[key]
    end

    # Return the raw hash representation
    #
    # @return [Hash] The configuration as a hash
    def to_hash
      config_content
    end

    private

    def config_file_exists?
      File.exist? config_path
    end

    def config_content
      @config_content ||= begin
        config = YAML.safe_load(File.read(config_path))
        transformed_config = ConfigTransformer.new(config).transform!
        symbolize(transformed_config).freeze
      end
    end
  end

  # Error raised when the config file cannot be found
  class ConfigMissingError < StandardError; end
end
