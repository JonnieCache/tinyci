# frozen_string_literal: true

require 'tinyci/installer'

RSpec.describe 'Integration' do
  let(:config) do
    <<~CONFIG
      builder:
        class: ScriptBuilder
        config:
          command: echo LOL
      tester:
        class: ScriptTester
        config:
          command: echo LOL
    CONFIG
  end
  let(:regex) do
    r = <<~REGEX
      ^.+Commit:.*$
      ^.+Cleaning\.\.\.\s*$
      ^.+Exporting\.\.\.\s*$
      ^.+Building\.\.\.\s*$
      ^.+LOL\s*$
      ^.+Testing\.\.\.\s*$
      ^.+LOL\s*$
      ^.+Finished.*$
    REGEX
    # r = <<~REGEX
    #   ^.+LOL\s*$
    # REGEX
    Regexp.new(r)
  end

  def do_commit
    `git -C #{repo_path(:bare_clone)} add .`
    `git -c 'user.name=A' -c 'user.email=author@example.com' -C #{repo_path(:bare_clone)} commit -m 'foo'`
  end

  before(:each) do
    extract_repo(:bare)
    TinyCI::Installer.new(working_dir: repo_path(:bare), absolute_path: true).install!

    `git clone #{repo_path(:bare)} #{repo_path(:bare_clone)} &> /dev/null`

    File.write repo_path(:bare_clone) + '/.tinyci.yml', config
    do_commit
  end

  it 'produces the right output' do
    cmd = "git -C #{repo_path(:bare_clone)} push origin master"

    expect { system(cmd) }.to output(regex).to_stderr_from_any_process
  end

  describe 'successive commits' do
    before do
      File.write repo_path(:bare_clone) + '/test', 'blah'
      do_commit
    end

    it 'outputs to both log files' do
      cmd = "git -C #{repo_path(:bare_clone)} push origin master"

      expect { system(cmd) }.to output(regex).to_stderr_from_any_process

      target_dir = Dir.entries(repo_path(:bare, '/builds'))
                      .reject { |p| %w[. .. tinyci.log].include? p }.sort.last
      build_log_path = repo_path(:bare, '/builds', target_dir, 'tinyci.log')
      repo_log_path = repo_path(:bare, '/builds', 'tinyci.log')

      expect(File.read(build_log_path)).to match regex
      expect(File.read(repo_log_path)).to match Regexp.new(regex.source + regex.source)
    end
  end
end
