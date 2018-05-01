require 'tinyci/version'
require 'tinyci/scheduler'
require 'tinyci/installer'
require 'tinyci/git_utils'
require 'optparse'

module TinyCI
  # Defines the CLI interface. Uses OptionParser.
  class CLI
    extend GitUtils
    
    LOGO = File.read(File.expand_path('logo.txt', __dir__))
    
    def self.parse!(argv = ARGV)
      opts = {}
      
      global = OptionParser.new do |o|
        o.banner = ''
        o.on("-q", "--[no-]quiet", "surpress output") {|q| opts[:quiet] = q}
        o.on("-D <DIR>", "--dir <DIR>", "specify repository location") {|d| opts[:dir] = d}
      end
      
      subcommands = { 
        'run' => OptionParser.new do |o|
          o.banner = "#{LOGO % TinyCI::VERSION}\nGlobal options:\n  #{global.help.slice(3..-1)}\nrun options:"
          o.on("-c <SHA>", "--commit <SHA>", "run against a specific commit") {|c| opts[:commit] = c}
          o.on("-a", "--all", "run against all commits which have not been run against before") {|a| opts[:all] = a}
        end,
        'install' => OptionParser.new do |o|
          o.banner = "Usage: install [options]"
          o.on("-q", "--[no-]quiet", "quietly run") {|v| opts[:quiet] = v}
        end
      }
      
          banner = <<TXT
#{LOGO % TinyCI::VERSION}
Global options:
    #{global.help.strip}

Available commands:
    run      build and test the repo
    install  install the git hook into the current repository
    version  print the TinyCI version number
TXT
      if argv[0] == '--help'
        puts banner
        return false
      end
      
      global.order!(argv)
      command = argv.shift
      
      if command.nil? || subcommands[command].nil?
        puts banner
        return false
      end
      
      subcommands[command].order!(argv)
      
      opts[:dir] ||= begin
        repo_root
      rescue TinyCI::Subprocesses::SubprocessError => e
        if e.message == '`git rev-parse --is-inside-git-dir` failed with code 32768'
          exit 1
        else
          raise e
        end
      end
      
      send "do_#{command}", opts
    end
    
    def self.do_run(opts)
      if PidFile.running?
        puts 'TinyCI is already running!' unless opts[:quiet]
        return false
      end
      
      opts.delete(:commit) if opts[:all]
      
      if !opts[:commit] && !opts[:all]
        puts "You must pass either --commit or --all, or try --help" unless opts[:quiet]
        return false
      end
            
      logger = MultiLogger.new(quiet: opts[:quiet])
      result = Scheduler.new(commit: opts[:commit], logger: logger, working_dir: opts[:dir]).run!
      
      result
    end
    
    def self.do_install(opts)
      logger = MultiLogger.new(quiet: opts[:quiet])
    
      TinyCI::Installer.new(logger: logger, working_dir: opts[:dir]).write!
    end
    
    def do_version(opts)
      puts TinyCI::VERSION
      
      true
    end
  end
end
