require 'tinyci/executor'

RSpec.describe TinyCI::Executor do
  let(:executor) {TinyCI::Executor.new(config)}
  
  describe 'command interpolation' do
    let(:config) do
      {
        target: support_path('tmp'),
        command: 'printf <%= commit %> > foo',
        commit: 'abcdef'
      }
    end
    
    it 'interpolates' do
      expect(executor.command).to eq ["/bin/sh", "-c", "'printf abcdef > foo'"]
    end
  end
end
