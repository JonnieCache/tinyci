module TinyCI
  class ConfigTransformer
    def initialize(input)
      @input = input
    end
    
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
