# frozen_string_literal: true

require 'tinyci/cli_ssh_delegator'

RSpec.describe TinyCI::CLISSHDelegator do

  context 'with remote specified by name' do
    let(:delegator) { TinyCI::CLISSHDelegator.new(argv, working_dir: dir, remote: 'origin') }
    let(:argv) { %W[--dir #{dir} --remote origin log -f] }
    let(:dir) { '/home/lol/lmao' }
    let(:url) { 'foo@bar.com:/home/foo/' }
    before(:each) do
      allow(delegator).to receive(:remote_exists?).and_return true
      allow(delegator).to receive(:raw_push_url).and_return url
    end

    it 'creates the tunnel correctly' do
      host = 'bar.com'
      user = 'foo'
      cmd = 'tinyci --running-remotely --dir /home/foo/ log -f'

      expect(delegator).to receive(:do_tunnel!).with(host, user, cmd)
      delegator.run!
    end

    context 'with github repo' do
      let(:url) { 'git@github.com:foo/bar.git' }

      it 'doesnt do the tunnel' do
        expect(delegator).to_not receive(:do_tunnel!)
        expect { delegator.run! }.to output(/github remote/).to_stderr
      end
    end

    context 'with https repo' do
      let(:url) { 'https://foobar.com/foo/bar.git' }

      it 'doesnt do the tunnel' do
        expect(delegator).to_not receive(:do_tunnel!)
        expect { delegator.run! }.to output(/ssh remote/).to_stderr
      end
    end
  end

  context 'with remote set to true' do
    let!(:repo) { create_repo_single_commit }
    let!(:clone) do
      repo.clone do |r|
        r.set_remote_url 'origin', 'foo@example.com:/home/foo/lol'
      end
    end
    let(:argv) { %W[--dir #{clone.path} --remote log -f] }
    let(:delegator) { TinyCI::CLISSHDelegator.new(argv, working_dir: clone.path, remote: true) }

    it 'uses the upstream of the current branch' do
      host = 'example.com'
      user = 'foo'
      cmd = 'tinyci --running-remotely --dir /home/foo/lol log -f'

      expect(delegator).to receive(:do_tunnel!).with(host, user, cmd)
      delegator.run!
    end
  end
end
