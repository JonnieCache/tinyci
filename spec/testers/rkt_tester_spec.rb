require 'tinyci/testers/rkt_tester'

RSpec.describe TinyCI::Testers::RktTester do
  let(:tester) {TinyCI::Testers::RktTester.new(config)}
  let(:config) do
    {
      target: 'test-target',
      image: 'test-image',
      src_path: '/test_path',
      command: 'test_command',
      env: {
        'FOO': 'bar',
        abc: 'def'
      }
    }
  end
  
  it 'runs the right command' do
    args = %w{
      sudo
      rkt
      run
      --net=host
      --insecure-options=image
      --volume
      src,kind=host,source=test-target/src,readOnly=false
      --mount
      volume=src,target=/test_path
      test-image
      --working-dir
      /test_path
      --set-env=FOO=bar
      --set-env=ABC=def
      --exec
      test_command
    }
    
    expect(tester).to receive(:execute_stream).with(*args, label: 'test')

    tester.test
  end
  
  context 'with no env config key' do
    let(:config) do
      {
        target: 'test-target',
        image: 'test-image',
        src_path: '/test_path',
        command: 'test_command'
      }
    end
    it 'runs the right command' do
      args = %w{
        sudo
        rkt
        run
        --net=host
        --insecure-options=image
        --volume
        src,kind=host,source=test-target/src,readOnly=false
        --mount
        volume=src,target=/test_path
        test-image
        --working-dir
        /test_path
        --exec
        test_command
      }
      
      expect(tester).to receive(:execute_stream).with(*args, label: 'test')

      tester.test
    end
  end
end
