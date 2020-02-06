# frozen_string_literal: true

require 'tinyci/scheduler'
require 'tinyci/multi_logger'
require 'barrier'

RSpec.describe TinyCI::Scheduler do
  let(:runner_class) { class_double('Runner') }

  context 'with single commit' do
    let(:scheduler) { TinyCI::Scheduler.new(working_dir: single_commit_repo.path, runner_class: runner_class) }
    let!(:single_commit_repo) { create_repo_single_commit }

    context 'with working_dir unspecified' do
      let(:scheduler) { TinyCI::Scheduler.new(runner_class: runner_class) }

      it 'determines working_dir correctly' do
        Dir.chdir(single_commit_repo.path('.git')) do
          expect(scheduler.working_dir).to eq single_commit_repo.path.to_s
        end
      end
    end

    it 'creates one Runner' do
      mock = instance_double('Runner')
      expect(runner_class).to receive(:new)
        .once.
        # with(hash_including(commit: commit_1)).
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

        note = `git -C #{single_commit_repo.path} notes --ref=tinyci-result show #{single_commit_repo.head}`.chomp
        expect(note).to eq 'success'
      end
    end
  end

  context 'with two commits' do
    let(:scheduler) { TinyCI::Scheduler.new(working_dir: repo.path, runner_class: runner_class) }
    let!(:repo) do
      create_repo_single_commit(:two_commits).build do |f|
        f.file 'file', "stuff\nmore stuff"
        f.add
        f.commit 'foo'
      end
    end

    it 'creates two Runners' do
      mock = instance_double('Runner')
      mock2 = instance_double('Runner')

      expect(runner_class).to receive(:new)
        .once
        .with(hash_including(commit: repo.rev('HEAD^1')))
        .and_return(mock)
        .ordered

      expect(runner_class).to receive(:new)
        .once
        .with(hash_including(commit: repo.head))
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
    let(:scheduler) { TinyCI::Scheduler.new(working_dir: repo.path, runner_class: runner_class) }
    let!(:repo) { RepoFactory.new(:three_commits_one_success) }
    let!(:commit_1) do
      repo.file 'file', 'stuff'
      repo.add
      repo.commit 'init'
    end
    let!(:commit_2) do
      repo.file 'file', 'stuff2'
      repo.add
      sha = repo.commit 'more'
      repo.success sha
      sha
    end
    let!(:commit_3) do
      repo.file 'file', 'stuff3'
      repo.add
      repo.commit 'moar'
    end

    it 'skips the commit with the success note' do
      mock = instance_double('Runner')
      mock2 = instance_double('Runner')

      expect(runner_class).to receive(:new)
        .once
        .with(hash_including(commit: commit_1))
        .and_return(mock)
        .ordered

      expect(runner_class).to receive(:new)
        .once
        .with(hash_including(commit: commit_3))
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
          .with(hash_including(commit: commit_1))
          .and_return(mock)
          .ordered

        expect(runner_class).to receive(:new)
          .once
          .with(hash_including(commit: commit_3))
          .and_return(mock2)
          .ordered do
            barrier.wait
          end

        expect(runner_class).to receive(:new)
          .once.
          # with(hash_including(commit: commit_3)).
          and_return(mock3)
          .ordered

        allow(mock).to  receive(:run!).and_return true
        allow(mock2).to receive(:run!).and_return true
        allow(mock3).to receive(:run!).and_return true

        scheduler_thread = Thread.new { scheduler.run! }

        repo.file 'foo', 'bar'
        repo.add
        repo.commit 'lol'
        # File.open(File.join(repo.path, 'new'), 'w') { |f| f.write 'test' }
        # system("git -C #{repo.path} add new")
        # system("git -C #{repo.path} commit -m 'new' --quiet")

        barrier.wait
        scheduler_thread.join
      end
    end
  end
end
