ENV["TINYCI_ENV"] = 'test'

require "bundler/setup"
require 'fileutils'
require 'pry'

Thread.report_on_exception = true

module GitSpecHelper
  SUPPORT_ROOT = File.expand_path('support/', __dir__)
  REPO_ROOT = File.expand_path('repos/', SUPPORT_ROOT)
  
  def extract_repo(repo)
    system 'tar', '-xzf', repo_archive_path(repo), '-C', REPO_ROOT
  end
  
  def repo_archive_path(repo)
    pathname = File.join REPO_ROOT, "#{repo}.git.tar.gz"
    path(pathname)
  end
  
  def support_path(filename, skip_exist_check: false)
    pathname = File.join SUPPORT_ROOT, filename
    path(pathname, skip_exist_check: skip_exist_check)
  end
  
  def repo_path(repo)
    pathname = File.join REPO_ROOT, "#{repo}.git"
    path(pathname)
  end
  
  private
  
  def path(pathname, skip_exist_check: false)
    raise ArgumentError, "#{pathname} does not exist!" unless skip_exist_check || File.exist?(pathname)
    
    pathname
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
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = "doc" if config.files_to_run.one?
  # config.profile_examples = 10
  config.order = :random
  
  config.include GitSpecHelper
  
  Kernel.srand config.seed
  
  config.before(:each) do
    entries = Dir.entries GitSpecHelper::REPO_ROOT
    entries.delete '.'
    entries.delete '..'
    entries.reject! {|e| e.end_with? '.tar.gz'}.map! {|e| File.join(GitSpecHelper::REPO_ROOT, e)}
    FileUtils.rm_rf entries
  end
end
