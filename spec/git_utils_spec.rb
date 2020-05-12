# frozen_string_literal: true

require 'tinyci/git_utils'

RSpec.describe TinyCI::GitUtils do
  class Dummy
    include TinyCI::GitUtils

    def initialize(remote, working_dir)
      @remote = remote
      @working_dir = working_dir
    end
  end

  subject { Dummy.new(remote, repo.path) }
  let(:remote) { 'origin' }
  let!(:repo) { create_repo_single_commit.build { |r| r.add_remote remote, url } }

  context 'with github url' do
    let(:url) { 'git@github.com:foo/bar.git' }

    it { should be_github_remote }
  end

  context 'with https url' do
    let(:url) { 'https://foobar.com/foo/bar.git' }

    it { should_not be_ssh_remote }
  end

  context 'with ssh url' do
    let(:url) { 'example.com:/home/foo' }

    it { should be_ssh_remote }
  end

  context 'with ambiguous url' do
    let(:url) { 'example.com/foo' }

    it { should_not be_ssh_remote }
  end
end
