# frozen_string_literal: true

require 'tinyci/cli'

RSpec.describe TinyCI::CLI do
  let(:cli) { TinyCI::CLI.new(args) }

  describe 'run' do
    let(:regex) do
      Regexp.new <<~REGEX
        ^.+Commit: .+$
        ^.+Cleaning\.\.\.$
        ^.+Exporting\.\.\.$
        ^.+Building\.\.\.$
        ^.+Testing\.\..$
        ^.+Finished .+$
      REGEX
    end

    context 'when run from hook' do
      let!(:single_commit_repo) { create_repo_single_commit }
      let(:args) { %W[--dir #{single_commit_repo.path} run --all] }

      it 'produces the right output' do
        expect { cli.parse! }.to output(regex).to_stdout
      end
    end

    context 'bare repo' do
      let!(:bare_repo) { create_repo_bare }
      let(:args) { %W[--dir #{bare_repo.path} run --all] }

      it 'produces the right output' do
        expect { cli.parse! }.to output(regex).to_stdout
      end
    end

    context 'with specified commit' do
      let!(:single_commit_repo) { create_repo_single_commit }
      let(:args) { %W[--dir #{single_commit_repo.path} run --commit #{single_commit_repo.head}] }

      it 'produces the right output' do
        expect { cli.parse! }.to output(regex).to_stdout
      end
    end
  end

  describe 'install' do
    context 'with normal repo' do
      let!(:single_commit_repo) { create_repo_single_commit }
      let(:args) { %W[--dir #{single_commit_repo.path} install] }

      it 'prints the message' do
        expect { cli.parse! }.to output(/installed successfully/).to_stdout
      end
    end

    context 'with bare repo' do
      let!(:bare_repo) { create_repo_bare }
      let(:args) { %W[--dir #{bare_repo.path} install] }

      it 'prints the message' do
        expect { cli.parse! }.to output(/installed successfully/).to_stdout
      end
    end
  end

  describe 'compact' do
    let(:repo) do
      create_repo_single_commit(:multiple_exports).build do |f|
        f.file 'builds/a/a', 'foo'
        f.file 'builds/b/b', 'foo'
        f.file 'builds/c/c', 'foo'
      end
    end
    let(:args) { %W[-q --dir #{repo.path} compact -b a] }

    it 'compacts the correct builds' do
      cli.parse!

      entries = repo.path('builds').children.sort.map { |p| p.basename.to_s }

      expect(entries).to eq %w[
        a
        b.tar.gz
        c
      ]
    end

    context 'with bare repo' do
      let(:repo) do
        create_repo_single_commit(:multiple_exports_bare).build do |f|
          f.make_bare

          f.file 'builds/a/a', 'foo'
          f.file 'builds/b/b', 'foo'
          f.file 'builds/c/c', 'foo'
        end
      end
      let(:args) { %W[-q --dir #{repo.path} compact -b a] }

      it 'compacts the correct builds' do
        cli.parse!
        entries = repo.path('builds').children.sort.map { |p| p.basename.to_s }

        expect(entries).to eq %w[
          a
          b.tar.gz
          c
        ]
      end
    end
  end

  describe 'remote' do
    let!(:single_commit_repo) { create_repo_single_commit }
    let!(:clone) { single_commit_repo.clone }
    let(:args) { %W[--dir #{clone.path} --remote origin log] }
    let(:delegator) { instance_double('TinyCI::CLISSHDelegator') }

    it 'works' do
      expect(TinyCI::CLISSHDelegator).to receive(:new).with(
        %W[--dir #{clone.path} --remote origin log],
        working_dir: clone.path.to_s,
        remote: 'origin'
      ).and_return delegator
      expect(delegator).to receive :run!

      cli.parse!
    end

    context 'with orphan remote flag' do
      let(:args) { %W[--dir #{single_commit_repo.path} --remote log] }

      it 'interprets orphan remote flag correctly' do
        expect(TinyCI::CLISSHDelegator).to receive(:new).with(
          %W[--dir #{single_commit_repo.path} --remote log],
          working_dir: single_commit_repo.path.to_s,
          remote: true
        ).and_return delegator
        expect(delegator).to receive :run!

        cli.parse!
      end
    end
  end
end
