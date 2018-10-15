require 'tinyci/runner'
require 'tinyci/builders/test_builder'
require 'tinyci/testers/test_tester'

RSpec.describe TinyCI::Runner do
  let(:runner) do
    TinyCI::Runner.new(
      working_dir: repo_path(:single_commit),                 
      commit: sha,
      config: {}
    )
  end
  let(:builder) { TinyCI::Builders::TestBuilder.new(result: true) }
  let(:tester)  { TinyCI::Testers::TestTester.new(result: true) }
  let(:sha)     { '5c770890e9dd664028c508d1365c6f29443640f5' }
  before(:each) { extract_repo(:single_commit) }
  
  describe 'exporting' do
    it 'exports the right stuff' do
      allow(runner).to receive(:instantiate_builder).and_return builder
      allow(runner).to receive(:instantiate_tester).and_return tester
      
      runner.run!
      
      builds = Dir.entries(File.join(repo_path(:single_commit), 'builds'))
      expect(builds.sort).to eq [".", "..", "1506086916_5c770890e9dd664028c508d1365c6f29443640f5"]
      
      build_content = Dir.entries(File.join(repo_path(:single_commit), 'builds', '1506086916_5c770890e9dd664028c508d1365c6f29443640f5', 'export'))
      build_content.reject! {|c| %w{. ..}.include? c}
      expect(build_content).to eq ["file"]
      
    end
  end
  
  it 'calls build' do
    allow(runner).to receive(:instantiate_builder).and_return builder
    allow(runner).to receive(:instantiate_tester).and_return tester
    
    allow(runner).to receive :export
    expect(builder).to receive :build
    
    runner.run!
  end
  
  it 'calls test' do
    allow(runner).to receive(:instantiate_builder).and_return builder
    allow(runner).to receive(:instantiate_tester).and_return tester
    
    allow(runner).to receive :export
    expect(tester).to receive :test
    
    runner.run!
  end
  
  context 'with config file' do
    let(:runner) do
      TinyCI::Runner.new(
        working_dir: repo_path(:with_config),
        commit: sha
      )
    end
    let(:sha)     { '418b2480c8d2a1252b357f1fe3a1ea7e3e3603b9' }
    before(:each) { extract_repo(:with_config) }
    
    it 'creates the right builder and tester' do
      runner.run!
      
      expect(runner.builder).to be_a TinyCI::Builders::TestBuilder
      expect(runner.tester).to be_a TinyCI::Testers::TestTester
    end
  end
  
end
