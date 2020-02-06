# frozen_string_literal: true

require 'tinyci/cli'

RSpec.describe TinyCI::CLI do
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

      it 'produces the right output' do
        expect { TinyCI::CLI.parse! %W[--dir #{single_commit_repo.path} run --all] }.to output(regex).to_stdout
      end
    end

    context 'bare repo' do
      let!(:bare_repo) { create_repo_bare }

      it 'produces the right output' do
        expect { TinyCI::CLI.parse! %W[--dir #{bare_repo.path} run --all] }.to output(regex).to_stdout
      end
    end

    context 'with specified commit' do
      let!(:single_commit_repo) { create_repo_single_commit }

      it 'produces the right output' do
        expect { TinyCI::CLI.parse! %W[--dir #{single_commit_repo.path} run --commit #{single_commit_repo.head}] }.to output(regex).to_stdout
      end
    end
  end

  describe 'install' do
    context 'with normal repo' do
      let!(:single_commit_repo) { create_repo_single_commit }

      it 'prints the message' do
        expect { TinyCI::CLI.parse! %W[--dir #{single_commit_repo.path} install] }.to output(/installed successfully/).to_stdout
      end
    end

    context 'with bare repo' do
      let!(:bare_repo) { create_repo_bare }

      it 'prints the message' do
        expect { TinyCI::CLI.parse! %W[--dir #{bare_repo.path} install] }.to output(/installed successfully/).to_stdout
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
    it 'compacts the correct builds' do
      TinyCI::CLI.parse! %W[-q --dir #{repo.path} compact -b a]

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

      it 'compacts the correct builds' do
        TinyCI::CLI.parse! %W[-q --dir #{repo.path} compact -b a]
        entries = repo.path('builds').children.sort.map { |p| p.basename.to_s }

        expect(entries).to eq %w[
          a
          b.tar.gz
          c
        ]
      end
    end
  end
end
