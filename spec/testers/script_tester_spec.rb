require 'tinyci/testers/script_tester'

RSpec.describe TinyCI::Testers::ScriptTester do
  let(:tester) {TinyCI::Testers::ScriptTester.new(config)}
  let(:config) do
    {
      target: 'test-target',
      command: 'test-command'
    }
  end
  
  it 'runs the right command' do
    expect(tester).to receive(:execute_stream).with('test-target/test-command', label: 'test', pwd: 'test-target')

    tester.test
  end
end
