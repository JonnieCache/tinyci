# frozen_string_literal: true

require 'tinyci/compactor'

RSpec.describe TinyCI::Compactor do
  before(:each)    { extract_repo(:multiple_exports) }
  let(:compactor)  { TinyCI::Compactor.new(working_dir: repo_path(:multiple_exports)) }

  it 'compresses the builds correctly' do
    compactor.compact!

    sha_command = RUBY_PLATFORM =~ /darwin/ ? 'shasum' : 'sha1sum'

    shas = {
      '1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b' => '69ee385834e4cc7ecbe5f51047b69d72326eb5ce',
      '1539604533_c3add70d640cb339ad19dbb3424b6f1c0c27b17d' => 'a23ecd2ec4d139ff23ced4bd4e20904e8bfa9fca'
    }

    shas.each_pair do |build, correct_sha|
      sha = `tar -xOzf #{repo_path(:multiple_exports)}/builds/#{build}.tar.gz | #{sha_command}`[0..39]

      expect(sha).to eq correct_sha
    end
  end

  context 'with the num_builds_to_leave option' do
    let(:compactor) { TinyCI::Compactor.new(working_dir: repo_path(:multiple_exports), num_builds_to_leave: 2) }

    it 'respects the option' do
      compactor.compact!

      entries = Dir.entries(repo_path(:multiple_exports) + '/builds').reject { |e| %w{. ..}.include? e }.sort

      expect(entries).to eq %w{
        1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b.tar.gz
        1539604533_c3add70d640cb339ad19dbb3424b6f1c0c27b17d
        1539604563_35998f9b3b7ea1bca3c7104111e36bf4e967fcf7
      }
    end
  end

  context 'with the builds_to_leave option' do
    let(:compactor) { TinyCI::Compactor.new(working_dir: repo_path(:multiple_exports), builds_to_leave: '1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b') }

    it 'respects the option' do
      compactor.compact!

      entries = Dir.entries(repo_path(:multiple_exports) + '/builds').reject { |e| %w{. ..}.include? e }.sort

      expect(entries).to eq %w{
        1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b
        1539604533_c3add70d640cb339ad19dbb3424b6f1c0c27b17d.tar.gz
        1539604563_35998f9b3b7ea1bca3c7104111e36bf4e967fcf7
      }
    end

    context 'with absolute path' do
      let(:compactor) do
        TinyCI::Compactor.new(
          working_dir: repo_path(:multiple_exports),
          builds_to_leave: repo_path(:multiple_exports, 'builds', '1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b')
        )
      end

      it 'respects the option' do
        compactor.compact!

        entries = Dir.entries(repo_path(:multiple_exports) + '/builds').reject { |e| %w{. ..}.include? e }.sort

        expect(entries).to eq %w{
          1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b
          1539604533_c3add70d640cb339ad19dbb3424b6f1c0c27b17d.tar.gz
          1539604563_35998f9b3b7ea1bca3c7104111e36bf4e967fcf7
        }
      end
    end
  end
end
