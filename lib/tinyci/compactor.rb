require 'fileutils'
require 'tinyci/git_utils'
require 'tinyci/subprocesses'

module TinyCI
  
  # Responsible for writing the git hook file
  class Compactor
    include GitUtils
    include Subprocesses
    
    # Constructor
    # 
    # @param [String] working_dir The directory from which to run. Does not have to be the root of the repo
    # @param [Logger] logger Logger object
    def initialize(working_dir: nil, logger: nil)
      @logger = logger
      @working_dir = working_dir || repo_root
    end
    
    # Write the hook to the relevant path and make it executable
    def compact!
      directories_to_compress.each do |dir|
        archive_path = File.join(builds_dir, dir+".tar.gz")
        execute 'tar', '-zcf', archive_path, '-C', builds_dir, dir
        
        FileUtils.rm_rf File.join(builds_dir, dir)
        
        log_info "Compacted #{archive_path}"
      end
    end
    
    private
    
    def directories_to_compress
      builds = Dir.entries builds_dir
      builds.select! {|e| File.directory? File.join(builds_dir, e) }
      builds.reject! {|e| %w{. ..}.include? e }
      
      builds.sort!
      
      builds[0..-2]
    end
    
    def builds_dir
      File.join @working_dir, 'builds/'
    end
  end
end
