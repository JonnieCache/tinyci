require 'tinyci/builders/script_builder'

RSpec.describe TinyCI::Builders::ScriptBuilder do
  let(:builder) {TinyCI::Builders::ScriptBuilder.new(config)}
  let(:config) do
    {
      target: 'test-target',
      command: 'test-command'
    }
  end
  
  it 'runs the right command' do
    expect(builder).to receive(:execute_stream).with('test-target/test-command', label: 'build', pwd: 'test-target')

    builder.build
  end
end
