# frozen_string_literal: true

require 'tinyci/hookers/script_hooker'
require 'tinyci/runner'

RSpec.describe TinyCI::Hookers::ScriptHooker do
  let(:base_hooker_config) do
    {
      before_build: 'echo 1 > before_build',

      after_build: 'echo 1 > after_build',
      after_build_success: 'echo 1 > after_build_success',
      after_build_failure: 'echo 1 > after_build_failure',

      before_test: 'echo 1 > before_test',

      after_test: 'echo 1 > after_test',
      after_test_success: 'echo 1 > after_test_success',
      after_test_failure: 'echo 1 > after_test_failure',
      after_all: 'echo 1 > after_all'
    }
  end
  let(:hooker_config) { base_hooker_config }
  let(:config) do
    {
      hooker: {
        class: 'ScriptHooker',
        config: hooker_config
      },
      builder: {
        class: 'TestBuilder',
        config: builder_config
      },
      tester: {
        class: 'TestTester',
        config: tester_config
      }
    }
  end
  let(:builder_config) { { result: true } }
  let(:tester_config) { { result: true } }
  let(:runner) do
    TinyCI::Runner.new(
      working_dir: single_commit_repo.path,
      commit: single_commit_repo.head,
      config: config
    )
  end
  let!(:single_commit_repo) { create_repo_single_commit }

  def hook_result_path(hook)
    runner.export_path + '/' + hook
  end

  def hook_result(hook)
    File.exist?(hook_result_path(hook))
  end

  def hook_result_content(hook)
    File.read(hook_result_path(hook))
  end

  describe 'full success' do
    it 'runs the right hooks' do
      runner.run!

      expect(hook_result('/before_build')).to eq true

      expect(hook_result('/after_build_success')).to eq true
      expect(hook_result('/after_build_failure')).to eq false
      expect(hook_result('/after_build')).to eq true

      expect(hook_result('/before_test')).to eq true

      expect(hook_result('/after_test_success')).to eq true
      expect(hook_result('/after_test_failure')).to eq false
      expect(hook_result('/after_test')).to eq true
      expect(hook_result('/after_build_failure')).to eq false
      expect(hook_result('/after_all')).to eq true
    end
  end

  describe 'build failure' do
    let(:builder_config) { { result: false } }
    let(:builder) { TinyCI::Builders::TestBuilder.new(result: false) }

    it 'runs the right hooks' do
      expect { runner.run! }.to raise_exception 'Simulated build failed'

      expect(hook_result('/before_build')).to eq true

      expect(hook_result('/after_build_success')).to eq false
      expect(hook_result('/after_build')).to eq true
      expect(hook_result('/after_build_failure')).to eq true

      expect(hook_result('/before_test')).to eq false

      expect(hook_result('/after_test_success')).to eq false
      expect(hook_result('/after_test')).to eq false
      expect(hook_result('/after_test_failure')).to eq false
      expect(hook_result('/after_all')).to eq true
    end
  end

  describe 'before_build hook failure' do
    let(:hooker_config) { base_hooker_config.merge(before_build: 'exit 1') }

    it 'runs the right hooks' do
      runner.builder = double
      runner.tester = double
      expect(runner.builder).to_not receive :build
      expect(runner.tester).to_not receive :test
      expect { runner.run! }.to raise_exception TinyCI::Subprocesses::SubprocessError,
                                                "before_build: `/bin/sh -c 'exit 1'` failed with status 1"

      expect(hook_result('/before_build')).to eq false

      expect(hook_result('/after_build_success')).to eq false
      expect(hook_result('/after_build')).to eq false
      expect(hook_result('/after_build_failure')).to eq false

      expect(hook_result('/before_test')).to eq false

      expect(hook_result('/after_test_success')).to eq false
      expect(hook_result('/after_test')).to eq false
      expect(hook_result('/after_test_failure')).to eq false
      expect(hook_result('/after_all')).to eq true
    end
  end

  describe 'test failure' do
    let(:tester_config) { { result: false } }

    it 'runs the right hooks' do
      expect { runner.run! }.to raise_exception 'Simulated test failed'

      expect(hook_result('/before_build')).to eq true

      expect(hook_result('/after_build')).to eq true
      expect(hook_result('/after_build_success')).to eq true
      expect(hook_result('/after_build_failure')).to eq false

      expect(hook_result('/before_test')).to eq true

      expect(hook_result('/after_test_success')).to eq false
      expect(hook_result('/after_test')).to eq true
      expect(hook_result('/after_test_failure')).to eq true
      expect(hook_result('/after_all')).to eq true
    end
  end

  describe 'before_test hook failure' do
    let(:hooker_config) { base_hooker_config.merge(before_test: 'exit 1') }

    it 'runs the right hooks' do
      runner.builder = double
      runner.tester = double
      expect(runner.builder).to receive :build
      expect(runner.tester).to_not receive :test
      expect { runner.run! }.to raise_exception TinyCI::Subprocesses::SubprocessError,
                                                "before_test: `/bin/sh -c 'exit 1'` failed with status 1"

      expect(hook_result('/before_build')).to eq true

      expect(hook_result('/after_build_success')).to eq true
      expect(hook_result('/after_build')).to eq true
      expect(hook_result('/after_build_failure')).to eq false

      expect(hook_result('/before_test')).to eq false

      expect(hook_result('/after_test_success')).to eq false
      expect(hook_result('/after_test')).to eq false
      expect(hook_result('/after_test_failure')).to eq false
      expect(hook_result('/after_all')).to eq true
    end
  end

  describe 'interpolation' do
    let(:hooker_config) { base_hooker_config.merge(before_build: 'echo <%= commit %> > before_build') }

    it 'interpolates' do
      runner.run!

      expect(hook_result_content('/before_build').chomp).to eq single_commit_repo.head
    end
  end
end
