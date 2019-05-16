require 'fileutils'
require 'tinyci/git_utils'

module TinyCI
  
  # Responsible for writing the git hook file
  class Installer
    include GitUtils
    
    # Constructor
    # 
    # @param [String] working_dir The directory from which to run. Does not have to be the root of the repo
    # @param [Logger] logger Logger object
    def initialize(working_dir: nil, logger: nil)
      @logger = logger
      @working_dir = working_dir || repo_root
    end
    
    # Write the hook to the relevant path and make it executable
    def install!
      unless inside_repository?
        log_error "not currently in a git repository"
        return false
      end
      
      if hook_exists?
        log_error "post-update hook already exists in this repository"
        return false
      end
      
      File.open(hook_path, 'a') {|f| f.write hook_content}
      FileUtils.chmod('u+x', hook_path)
      
      log_info 'tinyci post-update hook installed successfully'
    end
    
    private
    
    def hook_exists?
      File.exist? hook_path
    end
    
    def hook_path
      File.expand_path('hooks/post-update', git_directory_path)
    end
    
    def hook_content
      <<-EOF
#!/bin/sh

#{Gem.bin_path('tinyci', 'tinyci')} run --all
      EOF
    end
  end
end
