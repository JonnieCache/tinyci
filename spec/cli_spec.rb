require 'tinyci/cli'

RSpec.describe TinyCI::CLI do
  
  describe 'run' do
    let(:regex) do
      %r{^.+Commit: 418b2480c8d2a1252b357f1fe3a1ea7e3e3603b9$
^.+Cleaning\.\.\.$
^.+Exporting\.\.\.$
^.+Building\.\.\.$
^.+Testing\.\..$
^.+Finished 418b2480c8d2a1252b357f1fe3a1ea7e3e3603b9$}
    end
    
    context 'when run from hook' do
      before(:each) {extract_repo(:with_config)}
      
      it 'produces the right output' do
        expect{TinyCI::CLI.parse! %W[--dir #{repo_path(:with_config)} run --all]}.to output(regex).to_stdout
      end
    end
    
    context 'bare repo' do
      before(:each) {extract_repo(:bare)}
      
      it 'produces the right output' do
        expect{TinyCI::CLI.parse! %W[--dir #{repo_path(:bare)} run --all]}.to output(regex).to_stdout      
      end
    end
  end
  
  describe 'install' do
    
    context 'with normal repo' do
      before(:each) {extract_repo(:single_commit)}
      
      it 'prints the message' do
        expect{TinyCI::CLI.parse! %W[--dir #{repo_path(:single_commit)} install]}.to output(/installed/).to_stdout
      end
      
      it 'installs the hook' do
        TinyCI::CLI.parse! %W[-q --dir #{repo_path(:single_commit)} install]
        
        hook_path = "#{repo_path(:single_commit)}/.git/hooks/post-update"
        hook_content = File.read hook_path
        
        expect(hook_content).to match(/tinyci run --all/)
      end
    end
    
    context 'with bare repo' do
      before(:each) {extract_repo(:bare)}
      
      it 'prints the message' do
        expect{TinyCI::CLI.parse! %W[--dir #{repo_path(:bare)} install]}.to output(/installed/).to_stdout
      end
      
      it 'installs the hook' do
        TinyCI::CLI.parse! %W[-q --dir #{repo_path(:bare)} install]
        
        hook_path = "#{repo_path(:bare)}/hooks/post-update"
        hook_content = File.read hook_path
        
        expect(hook_content).to match(/tinyci run --all/)
      end
    end
    
  end
  
  describe 'compact' do
    before(:each) { extract_repo(:multiple_exports) }
      
    it 'compacts the correct builds' do
      TinyCI::CLI.parse! %W[-q --dir #{repo_path(:multiple_exports)} compact -b 1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b]
      
      entries = Dir.entries(repo_path(:multiple_exports)+'/builds').reject {|e| %w{. ..}.include? e}.sort
      
      expect(entries).to eq %w{
        1539604024_55431d9fd55d5fc507c09297ad2a11c7451b9e7b
        1539604533_c3add70d640cb339ad19dbb3424b6f1c0c27b17d.tar.gz
        1539604563_35998f9b3b7ea1bca3c7104111e36bf4e967fcf7
      }
    end
    
  end
end
