# frozen_string_literal: true

ENV['TINYCI_ENV'] = 'test'

require 'bundler/setup'

require 'simplecov'
SimpleCov.start

require 'fileutils'
require 'pry'

Thread.report_on_exception = true

module GitSpecHelper
  PROJECT_ROOT = File.expand_path('..', __dir__)
  SUPPORT_ROOT = File.expand_path('spec/support', PROJECT_ROOT)
  REPO_ROOT = File.expand_path('repos', SUPPORT_ROOT)

  def extract_repo(repo)
    system 'tar', '-xzf', repo_archive_path(repo), '-C', REPO_ROOT
  end

  def repo_archive_path(repo)
    File.join REPO_ROOT, "#{repo}.git.tar.gz"
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
    entries.delete '.'
    entries.delete '..'
    entries.reject! { |e| e.end_with? '.tar.gz' }.map! { |e| File.join(GitSpecHelper::REPO_ROOT, e) }
    FileUtils.rm_rf entries
  end
end
