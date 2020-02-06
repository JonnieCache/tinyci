# frozen_string_literal: true

require 'tinyci/installer'

RSpec.describe 'Integration' do
  let(:config) do
    <<~CONFIG
      build: echo LOL
      test: echo LOL
    CONFIG
  end
  let(:regex) do
    Regexp.new <<~REGEX
      ^.+Commit:.*$
      ^.+Cleaning\.\.\.\s*$
      ^.+Exporting\.\.\.\s*$
      ^.+Building\.\.\.\s*$
      ^.+LOL\s*$
      ^.+Testing\.\.\.\s*$
      ^.+LOL\s*$
      ^.+Finished.*$
    REGEX
  end

  def do_commit
    `git -C #{repo_path(:bare_clone)} add .`
    `git -c 'user.name=A' -c 'user.email=author@example.com' -C #{repo_path(:bare_clone)} commit -m 'foo'`
  end
  let!(:bare_repo) { create_repo_bare }

  before(:each) do
    TinyCI::Installer.new(working_dir: bare_repo.path, absolute_path: true).install!

    `git clone #{bare_repo.path} #{repo_path(:bare_clone)} &> /dev/null`

    File.write repo_path(:bare_clone, '.tinyci.yml'), config
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

    # rarely fails due to some race conditon
    it 'outputs to both log files', :brittle do
      cmd = "git -C #{repo_path(:bare_clone)} push origin master"

      expect { system(cmd) }.to output(regex).to_stderr_from_any_process

      target_dir = bare_repo.path('builds').children.reject { |p| p.basename.to_s == 'tinyci.log' }.max
      build_log_path = target_dir.join 'tinyci.log'
      repo_log_path = bare_repo.path('builds', 'tinyci.log')

      expect(File.read(build_log_path)).to match regex
      expect(File.read(repo_log_path)).to match Regexp.new(regex.source + regex.source)
    end
  end
end
