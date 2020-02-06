# frozen_string_literal: true

require 'tinyci/installer'

RSpec.describe TinyCI::Installer do
  context 'with normal repo' do
    let!(:single_commit_repo) { create_repo_single_commit }
    let(:installer) { TinyCI::Installer.new working_dir: single_commit_repo.path }

    it 'installs the hook' do
      installer.install!

      hook_path = single_commit_repo.path '.git', 'hooks', 'post-update'
      hook_content = File.read hook_path

      expect(hook_content).to match(/^tinyci run --all/)
    end

    context 'with absolute path setting' do
      let(:installer) { TinyCI::Installer.new working_dir: single_commit_repo.path, absolute_path: true }

      it 'install the hook' do
        installer.install!

        hook_path = "#{single_commit_repo.path}/.git/hooks/post-update"
        hook_content = File.read hook_path
        bin_path = File.join(GitSpecHelper::PROJECT_ROOT, 'bin', 'tinyci')

        expect(hook_content).to match(/#{bin_path} run --all/)
      end
    end
  end

  context 'with bare repo' do
    let!(:bare_repo) { create_repo_bare }
    let(:installer) { TinyCI::Installer.new working_dir: bare_repo.path }

    it 'installs the hook' do
      installer.install!

      hook_path = bare_repo.path('hooks', 'post-update')
      hook_content = File.read hook_path

      expect(hook_content).to match(/^tinyci run --all/)
    end
  end
end
