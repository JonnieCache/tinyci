# frozen_string_literal: true

class PidFile
  attr_reader :pidfile, :piddir, :pidpath

  class DuplicateProcessError < RuntimeError; end

  VERSION = '0.3.0'

  DEFAULT_OPTIONS = {
    pidfile: File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) + '.pid',
    piddir: '/var/run'
  }.freeze

  def initialize(*args)
    opts = {}

    #----- set options -----#
    if args.empty?
    elsif args.length == 1 && args[0].class == Hash
      arg = args.shift

      opts = arg if arg.class == Hash
    else
      raise ArgumentError, 'new() expects hash or hashref as argument'
    end

    opts = DEFAULT_OPTIONS.merge opts

    @piddir     = opts[:piddir]
    @pidfile    = opts[:pidfile]
    @pidpath    = File.join(@piddir, @pidfile)
    @fh         = nil

    #----- Does the pidfile or pid exist? -----#
    if pidfile_exists?
      if self.class.running?(@pidpath)
        raise DuplicateProcessError, "TinyCI is already running, process #{self.class.pid} will test your commit, don't worry!"

        exit! # exit without removing the existing pidfile
      end

      release
    end

    #----- create the pidfile -----#
    create_pidfile

    at_exit { release }
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
  # Instance Methods
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

  # Returns the PID, if any, of the instantiating process
  def pid
    return @pid unless @pid.nil?

    @pid = (open(pidpath, 'r').read.to_i if pidfile_exists?)
  end

  # Boolean stating whether this process is alive and running
  def alive?
    return false unless pid && (pid == Process.pid)

    self.class.process_exists?(pid)
  end

  # does the pidfile exist?
  def pidfile_exists?
    self.class.pidfile_exists?(pidpath)
  end

  # unlock and remove the pidfile. Sets pid to nil
  def release
    unless @fh.nil?
      @fh.flock(File::LOCK_UN)
      remove_pidfile
    end
    @pid = nil
  end

  # returns the modification time of the pidfile
  def locktime
    File.mtime(pidpath)
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
  # Class Methods
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

  # Returns the PID, if any, of the instantiating process
  def self.pid(path = nil)
    open(path, 'r').read.to_i if pidfile_exists?(path)
  end

  # class method for determining the existence of pidfile
  def self.pidfile_exists?(path = nil)
    path ||= File.join(DEFAULT_OPTIONS[:piddir], DEFAULT_OPTIONS[:pidfile])

    File.exist?(path)
  end

  # boolean stating whether the calling program is already running
  def self.running?(path = nil)
    calling_pid = nil
    path ||= File.join(DEFAULT_OPTIONS[:piddir], DEFAULT_OPTIONS[:pidfile])

    calling_pid = pid(path) if pidfile_exists?(path)

    process_exists?(calling_pid)
  end

  private

  # Writes the process ID to the pidfile and defines @pid as such
  def create_pidfile
    # Once the filehandle is created, we don't release until the process dies.
    @fh = open(pidpath, 'w')
    @fh.flock(File::LOCK_EX | File::LOCK_NB) || raise
    @pid = Process.pid
    @fh.puts @pid
    @fh.flush
    @fh.rewind
  end

  # removes the pidfile.
  def remove_pidfile
    File.unlink(pidpath) if pidfile_exists?
  end

  def self.process_exists?(process_id)
    Process.kill(0, process_id)
    true
  rescue Errno::ESRCH, TypeError # "PID is NOT running or is zombied
    false
  end
end
