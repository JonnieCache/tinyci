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
end
