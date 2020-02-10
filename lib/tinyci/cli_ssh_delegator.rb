# frozen_string_literal: true

require 'tinyci/git_utils'
require 'git_clone_url'
require 'net/ssh'
require 'pry'

module TinyCI
  class CLISSHDelegator
    include GitUtils

    def initialize(argv, dir:, remote:)
      @argv = argv
      @working_dir = dir
      @remote = remote
    end

    def run!
      Net::SSH.start(url.host, url.user) do |ssh|
        ssh.open_channel do |ch|
          puts command
          ch.exec command do |ch, success|
            abort "could not execute command" unless success
            ch.on_data do |_ch, data|
              print data
            end
            ch.on_extended_data do |_ch, type, data|
              print data
            end
          end
        end

        ssh.loop
      end
    end

    def command
      (['tinyci', '--dir', url.path] + scrubbed_args).join ' '
    end

    def url
      push_url @remote
    end

    def scrubbed_args
      scrubbed = @argv.clone

      [
        %w[--remote -r],
        %w[--dir -D]
      ].each do |(short, long)|
        index = scrubbed.index(short) || scrubbed.index(long)
        2.times { scrubbed.delete_at index } if index
      end

      scrubbed
    end
  end
end
