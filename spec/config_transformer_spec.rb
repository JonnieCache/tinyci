require 'tinyci/config_transformer'

RSpec.describe TinyCI::ConfigTransformer do
  let(:input) do
    {
      build: "foo",
      test: "bar",
      hooks: {
        after_build: "./after_build.sh"
      }
    }
  end
  let(:output) do
    {
      builder: {
        :class => "ScriptBuilder",
        config: {
          command: "foo" 
        }
      },
      hooker: {
        :class => "ScriptHooker",
        config: {
          after_build: "./after_build.sh"
        }
      },
      tester: {
        :class => "ScriptTester",
        config: {
          command: "bar"
        }
      }
    }
  end
  
  it 'transforms correctly' do
    result = TinyCI::ConfigTransformer.new(input).transform!
    expect(result).to eq output
  end
end
