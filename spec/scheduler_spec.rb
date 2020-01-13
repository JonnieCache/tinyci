# frozen_string_literal: true

require 'tinyci/scheduler'
require 'tinyci/multi_logger'
require 'barrier'

RSpec.describe TinyCI::Scheduler do
  let(:runner_class) { class_double('Runner') }

  context 'with single commit' do
    let(:scheduler) { TinyCI::Scheduler.new(working_dir: repo_path(:single_commit), runner_class: runner_class) }
    before(:each) { extract_repo(:single_commit) }

    context 'with working_dir unspecified' do
      let(:scheduler) { TinyCI::Scheduler.new(runner_class: runner_class) }

      it 'determines working_dir correctly' do
        Dir.chdir(File.join(repo_path(:single_commit), '.git')) do
          expect(scheduler.working_dir).to eq repo_path(:single_commit)
        end
      end
    end

    it 'creates one Runner' do
      mock = instance_double('Runner')
      expect(runner_class).to receive(:new)
        .once.
        # with(hash_including(commit: '5c770890e9dd664028c508d1365c6f29443640f5')).
        and_return(mock)

      allow(mock).to receive(:run!).and_return true

      scheduler.run!
    end

    it 'calls #run! on the Runner' do
      mock = instance_double('Runner')
      allow(runner_class).to receive(:new).and_return(mock).once
      expect(mock).to receive(:run!).and_return true

      scheduler.run!
    end

    describe 'setting note' do
      it 'sets the right note' do
        mock = instance_double('Runner')
        allow(runner_class).to receive(:new).and_return(mock).once
        allow(mock).to receive(:run!).and_return true

        scheduler.run!

        note = `git -C #{repo_path(:single_commit)} notes --ref=tinyci-result show 5c770890e9dd664028c508d1365c6f29443640f5`.chomp
        expect(note).to eq 'success'
      end
    end
  end

  context 'with two commits' do
    let(:scheduler) { TinyCI::Scheduler.new(working_dir: repo_path(:two_commits), runner_class: runner_class) }
    before(:each) { extract_repo(:two_commits) }

    it 'creates two Runners' do
      mock = instance_double('Runner')
      mock2 = instance_double('Runner')

      expect(runner_class).to receive(:new)
        .once
        .with(hash_including(commit: '5c770890e9dd664028c508d1365c6f29443640f5'))
        .and_return(mock)
        .ordered

      expect(runner_class).to receive(:new)
        .once
        .with(hash_including(commit: '8bba70a3f72be8330f6c8c636a0bf166c17313e0'))
        .and_return(mock2)
        .ordered

      allow(mock).to receive(:run!).and_return true
      allow(mock2).to receive(:run!).and_return true

      scheduler.run!
    end

    it 'calls #run! on each Runner' do
      mock = instance_double('Runner')
      mock2 = instance_double('Runner')

      allow(runner_class).to receive(:new)
        .twice
        .and_return(mock, mock2)

      expect(mock).to receive(:run!).once.and_return true
      expect(mock2).to receive(:run!).once.and_return true

      scheduler.run!
    end
  end

  context 'with three commits, one success' do
    let(:scheduler) { TinyCI::Scheduler.new(working_dir: repo_path(:three_commits_one_success), runner_class: runner_class) }
    before(:each) { extract_repo(:three_commits_one_success) }

    it 'skips the commit with the success note' do
      mock = instance_double('Runner')
      mock2 = instance_double('Runner')

      expect(runner_class).to receive(:new)
        .once
        .with(hash_including(commit: '5c770890e9dd664028c508d1365c6f29443640f5'))
        .and_return(mock)
        .ordered

      expect(runner_class).to receive(:new)
        .once
        .with(hash_including(commit: 'd3139ba6d1c9d974d0caa8b3b29e8ee837309ffb'))
        .and_return(mock2)
        .ordered

      allow(mock).to receive(:run!).and_return true
      allow(mock2).to receive(:run!).and_return true

      scheduler.run!
    end

    context 'with another commit during the test run' do
      it 'runs three times' do
        mock = instance_double('Runner')
        mock2 = instance_double('Runner')
        mock3 = instance_double('Runner')

        # to rendezvoux the threads
        barrier = Barrier.new(2)

        expect(runner_class).to receive(:new)
          .once
          .with(hash_including(commit: '5c770890e9dd664028c508d1365c6f29443640f5'))
          .and_return(mock)
          .ordered

        expect(runner_class).to receive(:new)
          .once
          .with(hash_including(commit: 'd3139ba6d1c9d974d0caa8b3b29e8ee837309ffb'))
          .and_return(mock2)
          .ordered do
            barrier.wait
          end

        expect(runner_class).to receive(:new)
          .once.
          # with(hash_including(commit: 'd3139ba6d1c9d974d0caa8b3b29e8ee837309ffb')).
          and_return(mock3)
          .ordered

        allow(mock).to  receive(:run!).and_return true
        allow(mock2).to receive(:run!).and_return true
        allow(mock3).to receive(:run!).and_return true

        scheduler_thread = Thread.new { scheduler.run! }

        File.open(File.join(repo_path(:three_commits_one_success), 'new'), 'w') { |f| f.write 'test' }
        system("git -C #{repo_path(:three_commits_one_success)} add new")
        system("git -C #{repo_path(:three_commits_one_success)} commit -m 'new' --quiet")

        barrier.wait
        scheduler_thread.join
      end
    end
  end
end
