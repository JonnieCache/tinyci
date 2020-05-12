# frozen_string_literal: true

require 'timeout'
require 'tinyci/log_viewer'
require 'tinyci/multi_logger'
require 'tinyci/scheduler'

RSpec.describe TinyCI::LogViewer do
  let(:log_viewer) { TinyCI::LogViewer.new(**{ working_dir: repo.path }.merge(opts)) }
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
  let!(:repo) do
    RepoFactory.new(:with_log) do |f|
      f.file '.tinyci.yml', <<~CONFIG
        build: echo LOL
        test: echo LMAO
      CONFIG
      f.add
      f.commit 'init', time: Time.new(2020, 1, 1, 10)

      f.file '.tinyci.yml', <<~CONFIG
        build: echo LOL
        test: echo LMAO && false
      CONFIG
      f.add
      f.commit 'fail', time: Time.new(2020, 1, 1, 11)

      f.file "builds/#{Time.new(2020, 1, 1, 10).to_i}_#{f.rev('HEAD^1')}/tinyci.log", <<~LOG
        [17:49:52] Commit: 9ba9832af4d16199bcff108e388fefd1c5d30e80
        [17:49:52] Cleaning...
        [17:49:52] Exporting...
        [17:49:52] Building...
        [17:49:52] LOL
        [17:49:52] Testing...
        [17:49:52] LMAO
        [17:49:52] Finished 9ba9832af4d16199bcff108e388fefd1c5d30e80
      LOG

      f.file "builds/#{Time.new(2020, 1, 1, 11).to_i}_#{f.rev('HEAD')}/tinyci.log", <<~LOG
        [17:49:52] Commit: ad6193a90e80706abb2ba2d3fcfec2fae4ac5090
        [17:49:52] Cleaning...
        [17:49:52] Exporting...
        [17:49:52] Building...
        [17:49:52] LOL
        [17:49:52] Testing...
        [17:49:52] LMAO
        [17:49:52] test: `/bin/sh -c 'echo LMAO && false'` failed with status 1
      LOG

      f.file 'builds/tinyci.log', <<~LOG
        [17:49:52] Commit: 9ba9832af4d16199bcff108e388fefd1c5d30e80
        [17:49:52] Cleaning...
        [17:49:52] Exporting...
        [17:49:52] Building...
        [17:49:52] LOL
        [17:49:52] Testing...
        [17:49:52] LMAO
        [17:49:52] Finished 9ba9832af4d16199bcff108e388fefd1c5d30e80
        [17:49:52] Commit: ad6193a90e80706abb2ba2d3fcfec2fae4ac5090
        [17:49:52] Cleaning...
        [17:49:52] Exporting...
        [17:49:52] Building...
        [17:49:52] LOL
        [17:49:52] Testing...
        [17:49:52] LMAO
        [17:49:52] test: `/bin/sh -c 'echo LMAO && false'` failed with status 1
      LOG
    end
  end

  describe 'with a specific commit' do
    let(:opts) { { commit: repo.rev('HEAD^1') } }

    it 'prints the log' do
      expect { log_viewer.view! }.to output(regex).to_stdout
    end

    context 'with num_lines' do
      let(:opts) { { commit: repo.rev('HEAD^1'), num_lines: 2 } }
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

  describe 'all commits' do
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

  describe 'follow mode', :slow do
    let!(:repo) do
      RepoFactory.new(:slow_build) do |f|
        f.file '.tinyci.yml', <<~CONFIG
          build: for i in {1..5}; do echo $i && sleep 1; done
          test: 'true'
        CONFIG
        f.file 'file', 'lol'
        f.add
        f.commit 'init'
      end
    end
    let(:scheduler) do
      TinyCI::Scheduler.new(
        working_dir: repo.path,
        commit: repo.head,
        logger: TinyCI::MultiLogger.new(quiet: true)
      )
    end
    let(:regex) { Regexp.new((1..5).each_with_object(String.new) { |n, r| r << "^.+#{n}$\n" }) }
    let(:opts) { { commit: repo.head, follow: true } }

    it 'follows' do
      t = Thread.new { scheduler.run! }
      sleep 1 until File.exist?(repo.path('builds', 'tinyci.log'))

      expect do
        Timeout.timeout(6) { log_viewer.view! }
      rescue Timeout::Error
      end.to output(regex).to_stdout
      t.join
    end

    context 'with num_lines' do
      let!(:repo) do
        RepoFactory.new(:slow_build_preexisting_log) do |f|
          f.file '.tinyci.yml', <<~CONFIG
            build: for i in {1..5}; do echo $i && sleep 1; done
            test: 'true'
          CONFIG
          f.file 'file', 'lol'
          f.add
          f.commit 'init'

          f.file 'builds/tinyci.log', <<~LOG
            [16:33:10] Commit: d8638bc7c457d2722b8a1a6a58de6d21ff618c3d
            [16:33:10] Cleaning...
            [16:33:10] Exporting...
            [16:33:10] Building...
            [16:33:10] 1
            [16:33:11] 2
            [16:33:12] 3
            [16:33:13] 4
            [16:33:14] 5
            [16:33:15] Testing...
            [16:33:15] Finished d8638bc7c457d2722b8a1a6a58de6d21ff618c3d
          LOG
        end
      end
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

        expect do
          Timeout.timeout(6) { log_viewer.view! }
        rescue Timeout::Error
        end.to output(regex).to_stdout
        t.join
      end
    end
  end

  describe 'with no logs' do
    let!(:repo) { create_repo_single_commit }

    it 'doesnt throw an exception' do
      allow(Warning).to receive :warn

      expect { log_viewer.view! }.to_not raise_error
    end

    it 'prints a message' do
      expect { log_viewer.view! }.to output(/Logfile does not exist/).to_stderr
    end
  end
end
