# frozen_string_literal: true

require 'tinyci/subprocesses'
require 'tinyci/git_utils'
require 'fileutils'

module TinyCI
  # Methods for computing paths.
  module PathUtils
    def builds_path
      File.absolute_path("#{@working_dir}/builds")
    end

    # Build the absolute target path
    def target_path
      File.join(builds_path, "#{time.to_i}_#{@commit}")
    end

    # Build the export path
    def export_path
      File.join(target_path, 'export')
    end

    private

    def logfile_path
      File.join(target_path, 'tinyci.log')
    end

    def repo_logfile_path
      File.join(builds_path, 'tinyci.log')
    end

    # Ensure a path exists
    def ensure_path(path)
      FileUtils.mkdir_p path
    end

    def self.included(base)
      base.include TinyCI::Subprocesses
      base.include TinyCI::GitUtils
    end
  end
end
