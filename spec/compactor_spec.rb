# frozen_string_literal: true

require 'tinyci/compactor'
require 'digest'

RSpec.describe TinyCI::Compactor do
  let!(:repo) do
    create_repo_single_commit(:multiple_exports).build do |f|
      f.file 'builds/a/a', 'foo'
      f.file 'builds/b/b', 'bar'
      f.file 'builds/c/c', 'baz'
    end
  end
  let(:compactor) { TinyCI::Compactor.new(working_dir: repo.path) }

  it 'compresses the builds correctly' do
    compactor.compact!

    shas = {
      'a' => 'b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c',
      'b' => '7d865e959b2466918c9863afca942d0fb89d7c9ac0c99bafc3749504ded97730'
    }

    shas.each_pair do |build, correct_sha|
      archive_path = repo.path('builds', "#{build}.tar.gz")
      archive_content = `tar -xOzf #{archive_path}`
      sha = Digest::SHA256.hexdigest archive_content

      expect(sha).to eq correct_sha
    end
  end

  context 'with the num_builds_to_leave option' do
    let(:compactor) { TinyCI::Compactor.new(working_dir: repo.path, num_builds_to_leave: 2) }

    it 'respects the option' do
      compactor.compact!

      entries = repo.path('builds').children.sort.map { |p| p.basename.to_s }

      expect(entries).to eq %w[
        a.tar.gz
        b
        c
      ]
    end
  end

  context 'with the builds_to_leave option' do
    let(:compactor) { TinyCI::Compactor.new(working_dir: repo.path, builds_to_leave: 'a') }

    it 'respects the option' do
      compactor.compact!

      entries = repo.path('builds').children.sort.map { |p| p.basename.to_s }

      expect(entries).to eq %w[
        a
        b.tar.gz
        c
      ]
    end

    context 'with absolute path' do
      let(:compactor) do
        TinyCI::Compactor.new(
          working_dir: repo.path,
          builds_to_leave: repo.path('builds', 'a')
        )
      end

      it 'respects the option' do
        # binding.pry;
        compactor.compact!

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
