# frozen_string_literal: true

require 'tinyci/path_utils'
require 'fileutils'

class RepoFactory
  include TinyCI::PathUtils
  include TinyCI::GitUtils

  SUPPORT_ROOT = __dir__

  attr_reader :name

  def initialize(name, &block)
    @name = name
    @working_dir = path
    init

    build(&block) if block
  end

  def name=(new_name)
    old_path = path
    @name = new_name
    FileUtils.mv old_path, path
  end

  def build(new_name = nil, &block)
    self.name = new_name if new_name
    block&.call(self)

    self
  end

  def dirname
    "#{@name}.git"
  end

  def path(*parts)
    Pathname.new(SUPPORT_ROOT).join('repos', dirname, *parts)
  end

  def init
    path.mkdir
    execute git_cmd 'init'
  end

  def file(file_path, content = nil)
    file_path = path(file_path)
    ensure_path file_path.dirname
    file = File.new(file_path, File::RDWR | File::CREAT)
    file.puts content if content
    yield file if block_given?
    file.close
  end

  def stub_config
    file('.tinyci.yml') do |c|
      c.puts "build: 'true'"
      c.puts "test: 'true'"
    end
  end

  def add(path = '.')
    execute git_cmd 'add', path
  end

  def make_bare
    tmp_path = path.to_s + '.bare'
    execute 'git', 'clone', '--bare', '--quiet', path.to_s, tmp_path
    FileUtils.rm_rf path
    FileUtils.mv tmp_path, path
  end

  def commit(message, time: Time.now, author: 'John Doe', email: 'johndoe@example.com')
    execute git_cmd '-c', "user.name=#{author}",
                    '-c', "user.email=#{email}",
                    'commit',
                    '-m', message,
                    '--date', time.strftime('%Y-%m-%dT%H:%M:%S')

    head
  end

  def success(sha)
    mark_result sha, true
  end

  def failure(sha)
    mark_result sha, false
  end

  def mark_result(sha, result)
    result_message = result ? 'success' : 'failure'
    execute git_cmd 'notes', '--ref', 'tinyci-result', 'add', '-m', result_message, sha
  end

  def head
    rev 'HEAD'
  end

  def rev(rev_name)
    execute git_cmd 'rev-parse', rev_name
  end

  def children(*parts)
    path(*parts).children.reject { |p| p.basename.to_s == '.git' }
  end
end
