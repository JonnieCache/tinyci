# frozen_string_literal: true

require 'tinyci/multi_logger'
require 'tinyci/logging'
require 'fileutils'

RSpec.describe TinyCI::MultiLogger do
  let(:log_path) { support_path('test.log') }
  let(:logger) { TinyCI::MultiLogger.new(quiet: false, path: log_path) }
  before { FileUtils.rm_f log_path }

  it 'outputs to both stdout and a file' do
    regex = /foo$/

    expect { logger.info('foo') }.to output(regex).to_stdout
    expect(File.read(log_path)).to match regex
  end

  describe 'with second logger' do
    let(:log_path) { Tempfile.new.path }
    let(:second_path) { Tempfile.new.path }
    let(:logger) { TinyCI::MultiLogger.new(quiet: false, paths: [log_path, second_path]) }

    it 'apends to the second log' do
      File.write second_path, "lol\n"
      regex = /foo$/

      expect { logger.info('foo') }.to output(regex).to_stdout
      expect(File.read(log_path)).to match regex

      second_output_one, second_output_two = File.read(second_path).split("\n")
      expect(second_output_one).to eq 'lol'
      expect(second_output_two).to match regex
    end
  end

  describe 'logging' do
    class WithLogging
      include TinyCI::Logging
      attr_accessor :logger

      def foo
        log_info 'bar'
      end
    end

    let(:dummy) { WithLogging.new }

    it 'returns false with no logger' do
      expect(dummy.foo).to eq false
    end

    it 'logs with logger' do
      regex = /foo$/

      expect { dummy.logger = TinyCI::MultiLogger.new; dummy.log_info('foo') }.to output(regex).to_stdout
    end
  end
end
