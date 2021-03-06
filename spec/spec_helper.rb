# frozen_string_literal: true

ENV['TINYCI_ENV'] = 'test'

require 'bundler/setup'

require 'simplecov'
SimpleCov.start

require 'fileutils'
require 'pry'

require 'support/repo_factory'

Thread.report_on_exception = true

module GitSpecHelper
  PROJECT_ROOT = File.expand_path('..', __dir__)
  SUPPORT_ROOT = File.expand_path('spec/support', PROJECT_ROOT)
  REPO_ROOT = File.expand_path('repos', SUPPORT_ROOT)

  def create_repo_single_commit(name = :single_commit)
    RepoFactory.new(name) do |f|
      f.stub_config
      f.file 'file', 'stuff'
      f.add
      f.commit 'init', time: Time.new(2020, 1, 1, 10)
    end
  end

  def create_repo_bare
    create_repo_single_commit.build(:bare, &:make_bare)
  end

  def support_path(filename)
    File.join SUPPORT_ROOT, filename
  end

  def repo_path(*parts)
    File.join REPO_ROOT, "#{parts[0]}.git", *parts[1..-1]
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  # config.profile_examples = 10
  config.order = :random

  config.include GitSpecHelper

  Kernel.srand config.seed

  config.before(:each) do
    entries = Dir.entries GitSpecHelper::REPO_ROOT
    entries = entries.reject { |e| e.start_with? '.' }.map { |e| File.join(GitSpecHelper::REPO_ROOT, e) }
    FileUtils.rm_rf entries
  end
end
