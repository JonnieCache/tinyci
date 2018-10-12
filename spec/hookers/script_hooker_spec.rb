require 'tinyci/hookers/script_hooker'
require 'tinyci/runner'

RSpec.describe TinyCI::Hookers::ScriptHooker do
  let(:base_config) do
    {
      target: runner.export_path,
      
      before_build: 'echo 1 > before_build',
      
      after_build: 'echo 1 > after_build',
      after_build_success: 'echo 1 > after_build_success',
      after_build_failure: 'echo 1 > after_build_failure',
      
      before_test: 'echo 1 > before_test',
      
      after_test: 'echo 1 > after_test',
      after_test_success: 'echo 1 > after_test_success',
      after_test_failure: 'echo 1 > after_test_failure'
    }
  end
  let(:config) {base_config}
  let(:hooker) {TinyCI::Hookers::ScriptHooker.new(config)}
  let(:runner) do
    TinyCI::Runner.new(
      working_dir: repo_path(:single_commit),
      commit: '5c770890e9dd664028c508d1365c6f29443640f5',
      config: {}
    )
  end
  before(:each) do
    extract_repo(:single_commit)
    runner.builder = builder
    runner.tester = tester
    runner.hooker = hooker
  end
    
  let(:builder) { TinyCI::Builders::TestBuilder.new(result: true) }
  let(:tester)  { TinyCI::Testers::TestTester.new(result: true) }
  
  def hook_result(hook)
    File.exist?(runner.export_path+'/'+hook)
  end
  
  describe 'full success' do
    let(:config) {base_config}
    
    it 'runs the right hooks' do
      runner.run!
      
      expect(hook_result('/before_build')).to eq true
      
      expect(hook_result('/after_build_success')).to eq true
      expect(hook_result('/after_build_failure')).to eq false
      expect(hook_result('/after_build')).to eq true
      
      expect(hook_result('/before_test')).to eq true
      
      expect(hook_result('/after_test_success')).to eq true
      expect(hook_result('/after_test_failure')).to eq false
      expect(hook_result('/after_test')).to eq true

    end
  end
  
  describe 'build failure' do
    let(:config) {base_config}
    let(:builder) { TinyCI::Builders::TestBuilder.new(result: false) }
    
    it 'runs the right hooks' do
      expect {runner.run!}.to raise_exception 'Simulated build failed'
            
      expect(hook_result('/before_build')).to eq true
      
      expect(hook_result('/after_build_success')).to eq false
      expect(hook_result('/after_build')).to eq true
      expect(hook_result('/after_build_failure')).to eq true
      
      expect(hook_result('/before_test')).to eq false
      
      expect(hook_result('/after_test_success')).to eq false
      expect(hook_result('/after_test')).to eq false
      expect(hook_result('/after_test_failure')).to eq false
    end
    
  end
  
  describe 'before_build hook failure' do
    let(:config) {base_config.merge(before_build: 'exit 1')}
    
    it 'runs the right hooks' do
      expect(builder).to_not receive :build
      expect(tester).to_not receive :test
      expect{runner.run!}.to raise_exception TinyCI::Subprocesses::SubprocessError, '`before_build` failed with status 1'
            
      expect(hook_result('/before_build')).to eq false
      
      expect(hook_result('/after_build_success')).to eq false
      expect(hook_result('/after_build')).to eq false
      expect(hook_result('/after_build_failure')).to eq false
      
      expect(hook_result('/before_test')).to eq false
      
      expect(hook_result('/after_test_success')).to eq false
      expect(hook_result('/after_test')).to eq false
      expect(hook_result('/after_test_failure')).to eq false
    end
    
  end
  
  describe 'test failure' do
    let(:config) {base_config}
    let(:tester) { TinyCI::Testers::TestTester.new(result: false) }
    
    it 'runs the right hooks' do
      expect {runner.run!}.to raise_exception 'Simulated test failed'
      
      expect(hook_result('/before_build')).to eq true
      
      expect(hook_result('/after_build')).to eq true
      expect(hook_result('/after_build_success')).to eq true
      expect(hook_result('/after_build_failure')).to eq false
      
      expect(hook_result('/before_test')).to eq true
      
      expect(hook_result('/after_test_success')).to eq false
      expect(hook_result('/after_test')).to eq true
      expect(hook_result('/after_test_failure')).to eq true

    end
    
  end
  
  describe 'before_test hook failure' do
    let(:config) {base_config.merge(before_test: 'exit 1')}
    
    it 'runs the right hooks' do
      expect(builder).to receive :build
      expect(tester).to_not receive :test
      expect{runner.run!}.to raise_exception TinyCI::Subprocesses::SubprocessError, '`before_test` failed with status 1'
            
      expect(hook_result('/before_build')).to eq true
      
      expect(hook_result('/after_build_success')).to eq true
      expect(hook_result('/after_build')).to eq true
      expect(hook_result('/after_build_failure')).to eq false
      
      expect(hook_result('/before_test')).to eq false
      
      expect(hook_result('/after_test_success')).to eq false
      expect(hook_result('/after_test')).to eq false
      expect(hook_result('/after_test_failure')).to eq false
    end
    
  end
    
end
