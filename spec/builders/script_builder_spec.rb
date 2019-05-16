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
    expect(builder).to receive(:execute_stream).with("/bin/sh -c 'test-command'", {label: "build", pwd: "test-target"})

    builder.build
  end
  
  context('for_real') do
    let(:config) do
      {
        target: support_path('tmp'),
        command: 'printf <%= commit %> > foo',
        commit: 'abcdef'
      }
    end
    
    it 'slaps' do
      builder.build
      output = File.read support_path('tmp/foo')
      expect(output).to eq 'abcdef'
    end
  end
end
