require 'tinyci/compactor'

RSpec.describe TinyCI::Compactor do
  before(:each)    { extract_repo(:multiple_exports) }
  let(:compactor) { TinyCI::Compactor.new(working_dir: repo_path(:multiple_exports)) }
  
  it 'works' do
    compactor.compact!
    
    sha_command = RUBY_PLATFORM =~ /darwin/ ? 'shasum' : 'sha1sum'
    
    shas = {
      "1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b" => '847c0dd94608fdb743720fb48813fa16806a738f',
      "1539604533_c3add70d640cb339ad19dbb3424b6f1c0c27b17d" => '3f75c26cd7b45d8178c9be24d9029e6993818e0b'
    }
    
    shas.each_pair do |build, correct_sha|
      sha = `tar -xOzf #{repo_path(:multiple_exports)}/builds/#{build}.tar.gz | #{sha_command}`[0..39]
      
      expect(sha).to eq correct_sha
    end
  end
end
