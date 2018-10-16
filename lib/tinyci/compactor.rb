require 'fileutils'
require 'tinyci/git_utils'
require 'zlib'
require 'rubygems/package'
require 'find'

module TinyCI
  
  # Responsible for writing the git hook file
  class Compactor
    include GitUtils
    include Subprocesses
    
    BLOCKSIZE_TO_READ = 1024 * 1000
    
    # Constructor
    # 
    # @param [String] working_dir The directory from which to run. Does not have to be the root of the repo
    # @param [Logger] logger Logger object
    def initialize(working_dir: nil, num_builds_to_leave: nil, builds_to_leave: nil, logger: nil)
      @logger = logger
      @working_dir = working_dir || repo_root
      @num_builds_to_leave = num_builds_to_leave || 1
      @builds_to_leave = builds_to_leave || []
    end
    
    # Write the hook to the relevant path and make it executable
    def compact!
      directories_to_compress.each do |dir|
        compress_directory dir
        FileUtils.rm_rf File.join(builds_dir, dir)
        
        log_info "Compacted #{archive_path(dir)}"
      end
    end
    
    private
    
    def directories_to_compress
      builds = Dir.entries builds_dir
      builds.select! {|e| File.directory? File.join(builds_dir, e) }
      builds.reject! {|e| %w{. ..}.include? e }
      builds.sort!
      
      builds = builds[0..-(@num_builds_to_leave+1)]
      builds.reject! {|e| @builds_to_leave.include? e }

      builds
    end
    
    def builds_dir
      File.join @working_dir, 'builds/'
    end
    
    def archive_path(dir)
      File.join(builds_dir, dir+".tar.gz")
    end
    
    def compress_directory(dir)
      File.open archive_path(dir), 'wb' do |oarchive_path|
        Zlib::GzipWriter.wrap oarchive_path do |gz|
          Gem::Package::TarWriter.new gz do |tar|
            Find.find "#{builds_dir}/"+dir do |f|
              relative_path = f.sub "#{builds_dir}/", ""
              mode = File.stat(f).mode
              size = File.stat(f).size
              if File.directory? f
                tar.mkdir relative_path, mode
              else
                tar.add_file_simple relative_path, mode, size do |tio|
                  File.open f, 'rb' do |rio|
                    while buffer = rio.read(BLOCKSIZE_TO_READ)
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
