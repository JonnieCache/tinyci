# frozen_string_literal: true

require 'tinyci/runner'
require 'tinyci/builders/test_builder'
require 'tinyci/testers/test_tester'

RSpec.describe TinyCI::Runner do
  let(:runner) do
    TinyCI::Runner.new(
      working_dir: single_commit_repo.path,
      commit: single_commit_repo.head,
      config: {}
    )
  end
  let(:builder) { TinyCI::Builders::TestBuilder.new(result: true) }
  let(:tester)  { TinyCI::Testers::TestTester.new(result: true) }
  let!(:single_commit_repo) { create_repo_single_commit }

  describe 'exporting' do
    it 'exports the right stuff' do
      allow(runner).to receive(:instantiate_builder).and_return builder
      allow(runner).to receive(:instantiate_tester).and_return tester

      runner.run!

      builds = Dir.entries(single_commit_repo.path('builds'))
      build_dirname = "1577872800_#{single_commit_repo.head}"
      expect(builds.sort).to eq ['.', '..', build_dirname]

      export_path = single_commit_repo.path('builds', build_dirname, 'export')
      build_content = Dir.entries(export_path).sort
      build_content.reject! { |c| %w[. ..].include? c }
      expect(build_content).to eq ['.tinyci.yml', 'file']
    end
  end

  it 'calls build' do
    allow(runner).to receive(:instantiate_builder).and_return builder
    allow(runner).to receive(:instantiate_tester).and_return tester

    allow(runner).to receive :export
    expect(builder).to receive :build

    runner.run!
  end

  it 'calls test' do
    allow(runner).to receive(:instantiate_builder).and_return builder
    allow(runner).to receive(:instantiate_tester).and_return tester

    allow(runner).to receive :export
    expect(tester).to receive :test

    runner.run!
  end

  context 'with config file' do
    let(:runner) do
      TinyCI::Runner.new(
        working_dir: single_commit_repo.path,
        commit: single_commit_repo.head
      )
    end

    it 'creates the right builder and tester' do
      runner.run!

      expect(runner.builder).to be_a TinyCI::Builders::ScriptBuilder
      expect(runner.tester).to be_a TinyCI::Testers::ScriptTester
    end
  end
end
