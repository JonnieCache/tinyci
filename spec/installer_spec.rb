# frozen_string_literal: true

require 'tinyci/installer'

RSpec.describe TinyCI::Installer do
  context 'with normal repo' do
    before(:each) { extract_repo(:single_commit) }
    let(:installer) { TinyCI::Installer.new working_dir: repo_path(:single_commit) }

    it 'installs the hook' do
      installer.install!

      hook_path = "#{repo_path(:single_commit)}/.git/hooks/post-update"
      hook_content = File.read hook_path

      expect(hook_content).to match(/^tinyci run --all/)
    end

    context 'with absolute path setting' do
      let(:installer) { TinyCI::Installer.new working_dir: repo_path(:single_commit), absolute_path: true }

      it 'install the hook' do
        installer.install!

        hook_path = "#{repo_path(:single_commit)}/.git/hooks/post-update"
        hook_content = File.read hook_path
        bin_path = File.join(GitSpecHelper::PROJECT_ROOT, 'bin', 'tinyci')

        expect(hook_content).to match(/#{bin_path} run --all/)
      end
    end
  end

  context 'with bare repo' do
    before(:each) { extract_repo(:bare) }
    let(:installer) { TinyCI::Installer.new working_dir: repo_path(:bare) }

    it 'installs the hook' do
      installer.install!

      hook_path = "#{repo_path(:bare)}/hooks/post-update"
      hook_content = File.read hook_path

      expect(hook_content).to match(/^tinyci run --all/)
    end
  end
end
