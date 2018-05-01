require 'tinyci/config'

RSpec.describe TinyCI::Config do
  let(:config) {TinyCI::Config.new(config_path: support_path('test_config.yml'))}
  
  it 'returns the config data' do
    expect(config[:foo][:bar]).to eq 'baz'
  end
end
