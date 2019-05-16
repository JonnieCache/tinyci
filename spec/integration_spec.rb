require 'tinyci/installer'

RSpec.describe 'Integration' do
  let(:config) do
    <<~EOF
      builder:
        class: ScriptBuilder
        config:
          command: echo LOL
      tester:
        class: ScriptTester
        config:
          command: echo LOL
    EOF
  end
  let(:regex) do
    r = <<~EOF
      ^.+Building\.\.\.\s+$
      ^.+LOL\s+$
      ^.+Testing\.\.\.\s+$
      ^.+LOL\s+$
    EOF
    Regexp.new(r)
  end
  
  before(:each) do
    extract_repo(:bare)
    TinyCI::Installer.new(working_dir: repo_path(:bare)).install!
    
    `git clone #{repo_path(:bare)} #{repo_path(:bare_clone)} &> /dev/null`
    
    File.write repo_path(:bare_clone)+'/.tinyci.yml', config
    `git -C #{repo_path(:bare_clone)} add .`
    `git -c 'user.name=A' -c 'user.email=author@example.com' -C #{repo_path(:bare_clone)} commit -m 'foo'`
  end
  
  it 'produces the right output' do
    cmd = "git -C #{repo_path(:bare_clone)} push origin master"
    
    expect{system(cmd)}.to output(regex).to_stderr_from_any_process
  end
  
end
