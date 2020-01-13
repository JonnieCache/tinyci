# frozen_string_literal: true

require 'fileutils'
require 'tinyci/git_utils'
require 'zlib'
require 'rubygems/package'
require 'find'

module TinyCI
  # Tool for compressing old builds into .tar.gz files
  class Compactor
    include GitUtils
    include Subprocesses

    BLOCKSIZE_TO_READ = 1024 * 1000

    # Constructor
    #
    # @param [String] working_dir The directory from which to run.
    # @param [Integer] num_builds_to_leave How many builds not to compact, starting from the newest
    # @param [String] builds_to_leave Comma-separated list of build directory names not to compact
    # @param [Logger] logger Logger object
    def initialize(working_dir: nil, num_builds_to_leave: nil, builds_to_leave: nil, logger: nil)
      @logger = logger
      @working_dir = working_dir || repo_root
      @num_builds_to_leave = (num_builds_to_leave || 1).to_i
      @builds_to_leave = builds_to_leave || []
    end

    # Compress and delete the build directories
    def compact!
      unless inside_repository?
        log_error 'not currently in a git repository'
        return false
      end

      directories_to_compact.each do |dir|
        compress_directory dir
        FileUtils.rm_rf builds_dir(dir)

        log_info "Compacted #{archive_path(dir)}"
      end
    end

    private

    # Build the list of directories to compact according to the options
    def directories_to_compact
      builds = Dir.entries builds_dir
      builds.select! { |e| File.directory? builds_dir(e) }
      builds.reject! { |e| %w[. ..].include? e }
      builds.sort!

      builds = builds[0..-(@num_builds_to_leave + 1)]
      builds.reject! { |e| @builds_to_leave.include?(e) || @builds_to_leave.include?(builds_dir(e, 'export')) }

      builds
    end

    # Get the location of the builds directory
    def builds_dir(*path_segments)
      File.join @working_dir, 'builds/', *path_segments
    end

    # Build the path for a compressed archive
    def archive_path(dir)
      File.join(builds_dir, dir + '.tar.gz')
    end

    # Create a .tar.gz file from a directory
    # Done in pure ruby to ensure portability
    def compress_directory(dir)
      File.open archive_path(dir), 'wb' do |oarchive_path|
        Zlib::GzipWriter.wrap oarchive_path do |gz|
          Gem::Package::TarWriter.new gz do |tar|
            Find.find "#{builds_dir}/" + dir do |f|
              relative_path = f.sub "#{builds_dir}/", ''
              mode = File.stat(f).mode
              size = File.stat(f).size

              if File.directory? f
                tar.mkdir relative_path, mode
              else
                tar.add_file_simple relative_path, mode, size do |tio|
                  File.open f, 'rb' do |rio|
                    while (buffer = rio.read(BLOCKSIZE_TO_READ))
                      tio.write buffer
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
