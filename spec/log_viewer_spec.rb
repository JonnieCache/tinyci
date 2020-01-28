# frozen_string_literal: true

require 'timeout'
require 'tinyci/log_viewer'
require 'tinyci/multi_logger'
require 'tinyci/scheduler'

RSpec.describe TinyCI::LogViewer do
  let(:log_viewer) { TinyCI::LogViewer.new({ working_dir: repo_path(repo) }.merge(opts)) }
  let(:repo) { :with_logfiles }
  let(:opts) { {} }
  let(:regex) do
    r = <<~REGEX
      ^.+Commit:.*$
      ^.+Cleaning\.\.\.\s*$
      ^.+Exporting\.\.\.\s*$
      ^.+Building\.\.\.\s*$
      ^.+LOL\s*$
      ^.+Testing\.\.\.\s*$
      ^.+LMAO\s*$
      ^.+Finished.*$
    REGEX
    Regexp.new r
  end
  before { extract_repo(repo) }

  context 'with a specific commit' do
    let(:opts) { { commit: '9ba9832af4d16199bcff108e388fefd1c5d30e80' } }

    it 'prints the log' do
      expect { log_viewer.view! }.to output(regex).to_stdout
    end

    context 'with num_lines' do
      let(:opts) { { commit: '9ba9832af4d16199bcff108e388fefd1c5d30e80', num_lines: 2 } }
      let(:regex_one) do
        r = <<~REGEX
          ^.+Commit:.*$
          ^.+Cleaning\.\.\.\s*$
          ^.+Exporting\.\.\.\s*$
          ^.+Building\.\.\.\s*$
          ^.+LOL\s*$
          ^.+Testing\.\.\.\s*$
        REGEX
        Regexp.new r
      end
      let(:regex_two) do
        r = <<~REGEX
          ^.+LMAO\s*$
          ^.+Finished.*$
        REGEX
        Regexp.new r
      end

      it 'doesnt print the first lines' do
        expect { log_viewer.view! }.to_not output(regex_one).to_stdout
      end

      it 'prints the last 2 lines' do
        expect { log_viewer.view! }.to output(regex_two).to_stdout
      end
    end
  end

  context 'all commits' do
    let(:regex) do
      r = <<~REGEX
        ^.+Commit:.*$
        ^.+Cleaning\.\.\.\s*$
        ^.+Exporting\.\.\.\s*$
        ^.+Building\.\.\.\s*$
        ^.+LOL\s*$
        ^.+Testing\.\.\.\s*$
        ^.+LMAO\s*$
        ^.+Finished.*$
        ^.+Commit:.*$
        ^.+Cleaning\.\.\.\s*$
        ^.+Exporting\.\.\.\s*$
        ^.+Building\.\.\.\s*$
        ^.+LOL\s*$
        ^.+Testing\.\.\.\s*$
        ^.+LMAO\s*$
        ^.+test: `/bin/sh -c 'echo LMAO && false'` failed with status 1$
      REGEX
      Regexp.new r
    end

    it 'prints the logs' do
      expect { log_viewer.view! }.to output(regex).to_stdout
    end
  end

  describe 'follow mode' do
    let(:repo) { :slow_build }
    let(:commit) { 'd8638bc7c457d2722b8a1a6a58de6d21ff618c3d' }
    let(:scheduler) do
      TinyCI::Scheduler.new(
        working_dir: repo_path(repo),
        commit: commit,
        logger: TinyCI::MultiLogger.new(quiet: true)
      )
    end
    let(:regex) { Regexp.new((1..5).each_with_object(String.new) { |n, r| r << "^.+#{n}$\n" }) }
    let(:opts) { { commit: commit, follow: true} }

    it 'follows' do
      t = Thread.new { scheduler.run! }
      sleep 1 until File.exist?(repo_path(repo, 'builds', 'tinyci.log'))

      expect do
        Timeout.timeout(6) { log_viewer.view! }
      rescue Timeout::Error
      end.to output(regex).to_stdout
      t.join
    end

    context 'with num_lines' do
      let(:commit) { '78e3d75300e6b53e15e59933b1d0ac5f0fbbfead' }
      let(:repo) { :slow_build_preexisting_log }
      let(:opts) { { follow: true, num_lines: 2 } }
      let(:regex) do
        s = <<~REGEX
          ^.+Testing\.\.\.\s*$
          ^.+Finished.*$
          ^.+Commit:.*$
          ^.+Cleaning\.\.\.\s*$
          ^.+Exporting\.\.\.\s*$
          ^.+Building\.\.\.\s*$
        REGEX
        s += (1..5).each_with_object(String.new) { |n, r| r << "^.+#{n}$\n" }
        Regexp.new s
      end

      it 'prints the last num_lines and then follows' do
        t = Thread.new { scheduler.run! }
        # sleep 1 until File.exist?(repo_path(repo, 'builds', '1579710923_78e3d75300e6b53e15e59933b1d0ac5f0fbbfead', 'tinyci.log'))

        expect do
          Timeout.timeout(6) { log_viewer.view! }
        rescue Timeout::Error
        end.to output(regex).to_stdout
        # expect { log_viewer.view! }.to output(regex).to_stdout
        t.join
      end
    end
  end
end
