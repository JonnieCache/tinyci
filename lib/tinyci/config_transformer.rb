module TinyCI
  # Transforms the configuration format from the condensed format to the
  # more verbose format accepted by the rest of the system
  class ConfigTransformer
    
    # Constructor
    # 
    # @param [Hash] input The configuration object, in the condensed format
    def initialize(input)
      @input = input
    end
    
    # Transforms the config object
    # 
    # @return [Hash] The config object in the verbose form
    def transform!
      @input.inject({}) do |acc, (key, value)|
        method_name = "transform_#{key}"
        
        if respond_to? method_name, true
          
          acc.merge! send(method_name, value)
        else
          acc[key] = value
        end
        
        acc
      end
    end
    
    private
    
    def transform_build(value)
      {
        builder: {
          :class => "ScriptBuilder",
          config: {
            command: value
          }
        }
      }
    end
    
    def transform_test(value)
      {
        tester: {
          :class => "ScriptTester",
          config: {
            command: value
          }
        }
      }
    end
    
    def transform_hooks(value)
      {
        hooker: {
          :class => "ScriptHooker",
          config: value
        }
      }
    end
  end
end
