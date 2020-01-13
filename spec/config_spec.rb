# frozen_string_literal: true

require 'tinyci/config'

RSpec.describe TinyCI::Config do
  let(:correct) do
    {
      builder: {
        :class => 'ScriptBuilder',
        config: {
          command: 'foo'
        }
      },
      hooker: {
        :class => 'ScriptHooker',
        config: {
          after_build: './after_build.sh'
        }
      },
      tester: {
        :class => 'ScriptTester',
        config: {
          command: 'bar'
        }
      }
    }
  end
  context 'old config format' do
    let(:config) { TinyCI::Config.new(config_path: support_path('test_config.yml')) }

    it 'returns the config data' do
      expect(config.to_hash).to eq(correct)
    end
  end

  context 'new config format' do
    let(:config) { TinyCI::Config.new(config_path: support_path('test_config_new.yml')) }

    it 'returns the config data' do
      expect(config.to_hash).to eq(correct)
    end
  end
end
