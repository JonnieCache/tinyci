# frozen_string_literal: true
# rubocop:disable all

require 'tinyci/version'
require 'tinyci/scheduler'
require 'tinyci/installer'
require 'tinyci/compactor'
require 'tinyci/log_viewer'
require 'tinyci/git_utils'
require 'optparse'
require 'pidfile'

module TinyCI
  # Defines the CLI interface. Uses OptionParser.
  class CLI
    extend GitUtils

    LOGO = File.read(File.expand_path('logo.txt', __dir__))

    def self.parse!(argv = ARGV)
      opts = {}

      global = OptionParser.new do |o|
        o.banner = ''
        o.on('-q', '--[no-]quiet', 'surpress output') { |q| opts[:quiet] = q }
        o.on('-D <DIR>', '--dir <DIR>', 'specify repository location') { |d| opts[:dir] = d }
        o.on('-r <REMOTE>', '--remote <REMOTE>', 'specify remote') { |r| opts[:remote] = r }
      end

      subcommands = {
        'run' => OptionParser.new do |o|
          o.banner = "#{LOGO % TinyCI::VERSION}\nGlobal options:\n  #{global.help.slice(3..-1)}\nrun options:"
          o.on('-c <SHA>', '--commit <SHA>', 'run against a specific commit') { |c| opts[:commit] = c }
          o.on('-a', '--all', 'run against all commits which have not been run against before') { |a| opts[:all] = a }
        end,
        'install' => OptionParser.new do |o|
          o.banner = 'Usage: install [options]'
          o.on('-a', '--[no-]absolute-path', 'install hook with absolute path to specific tinyci version (not recommended)') { |v| opts[:absolute_path] = v }
        end,
        'compact' => OptionParser.new do |o|
          o.banner = 'Usage: compact [options]'
          o.on('-n', '--num-builds-to-leave <NUM>', 'number of builds to leave in place, starting from the most recent') { |n| opts[:num_builds_to_leave] = n }
          o.on('-b', '--builds-to-leave <BUILDS>', 'specific build directories to leave in place, comma-separated') { |b| opts[:builds_to_leave] = b.split(',') }
        end,
        'log' => OptionParser.new do |o|
          o.banner = 'Usage: log [options]'
          o.on('-f', '--follow', 'follow the logfile') {|f| opts[:follow] = f}
          o.on('-n', '--num-lines', 'number of lines to print') {|n| opts[:num_lines] = n}
          o.on('-c <SHA>', '--commit <SHA>', 'run against a specific commit') { |c| opts[:commit] = c }
        end
      }

      banner = <<~TXT
        #{LOGO % TinyCI::VERSION}
        Global options:
            #{global.help.strip}

        Available commands:
            run      build and test the repo
            install  install the git hook into the current repository
            compact  compress old build artifacts
            log      print the logfile
            version  print the TinyCI version number
      TXT
      if argv[0] == '--help'
        puts banner
        return false
      end

      original_argv = argv.clone
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

      if opts[:remote]
        do_remote original_argv
      else
        send "do_#{command}", opts
      end
    end

    def self.do_run(opts)
      if PidFile.running?
        puts 'TinyCI is already running!' unless opts[:quiet]
        return false
      end

      opts.delete(:commit) if opts[:all]

      if !opts[:commit] && !opts[:all]
        unless opts[:quiet]
          puts 'You must pass either --commit or --all, or try --help'
        end
        return false
      end

      logger = MultiLogger.new(quiet: opts[:quiet])
      result = Scheduler.new(commit: opts[:commit], logger: logger, working_dir: opts[:dir]).run!

      result
    end

    def self.do_install(opts)
      logger = MultiLogger.new(quiet: opts[:quiet])

      TinyCI::Installer.new(logger: logger, working_dir: opts[:dir], absolute_path: opts[:absolute_path]).install!
    end

    def self.do_compact(opts)
      logger = MultiLogger.new(quiet: opts[:quiet])

      TinyCI::Compactor.new(
        logger: logger,
        working_dir: opts[:dir],
        num_builds_to_leave: opts[:num_builds_to_leave],
        builds_to_leave: opts[:builds_to_leave]
      ).compact!
    end

    def self.do_log(opts)
      TinyCI::LogViewer.new(
        working_dir: opts[:dir],
        follow: opts[:follow],
        num_lines: opts[:num_lines]
      ).view!
    end

    def do_version(_opts)
      puts TinyCI::VERSION

      true
    end
  end
end

# rubocop:enable all
