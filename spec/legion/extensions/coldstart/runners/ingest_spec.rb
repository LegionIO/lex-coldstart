# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Coldstart::Runners::Ingest do
  let(:runner) { Object.new.extend(described_class) }
  let(:fixture_dir) { File.expand_path('../../../../fixtures', __dir__) }
  let(:memory_path) { File.join(fixture_dir, 'sample_memory.md') }
  let(:claude_path) { File.join(fixture_dir, 'sample_claude.md') }

  describe '#ingest_file' do
    it 'parses a MEMORY.md file' do
      result = runner.ingest_file(file_path: memory_path, store_traces: false)
      expect(result[:file]).to eq(memory_path)
      expect(result[:file_type]).to eq(:memory)
      expect(result[:traces_parsed]).to be > 0
    end

    it 'parses a CLAUDE.md file' do
      result = runner.ingest_file(file_path: claude_path, store_traces: false)
      expect(result[:file]).to eq(claude_path)
      expect(result[:file_type]).to eq(:claude_md)
      expect(result[:traces_parsed]).to be > 0
    end

    it 'returns error for missing file' do
      result = runner.ingest_file(file_path: '/nonexistent/file.md')
      expect(result[:error]).to eq('file not found')
    end

    it 'returns traces when store_traces is false' do
      result = runner.ingest_file(file_path: memory_path, store_traces: false)
      expect(result[:traces]).to be_an(Array)
      expect(result[:traces]).not_to be_empty
      expect(result[:traces].first).to have_key(:trace_type)
    end

    it 'includes firmware traces from Hard Rules' do
      result = runner.ingest_file(file_path: memory_path, store_traces: false)
      firmware = result[:traces].select { |t| t[:trace_type] == :firmware }
      expect(firmware.size).to eq(2)
    end
  end

  describe '#ingest_directory' do
    it 'finds and parses files in a directory' do
      result = runner.ingest_directory(dir_path: fixture_dir, pattern: '*.md', store_traces: false)
      expect(result[:files_found]).to be >= 2
      expect(result[:total_parsed]).to be > 0
    end

    it 'returns error for missing directory' do
      result = runner.ingest_directory(dir_path: '/nonexistent/dir')
      expect(result[:error]).to eq('directory not found')
    end

    it 'lists processed files' do
      result = runner.ingest_directory(dir_path: fixture_dir, pattern: '*.md', store_traces: false)
      expect(result[:files]).to be_an(Array)
      expect(result[:files].any? { |f| f.include?('sample_memory') }).to be true
    end
  end

  describe '#preview_ingest' do
    it 'returns traces without storing' do
      result = runner.preview_ingest(file_path: memory_path)
      expect(result[:traces]).to be_an(Array)
      expect(result[:traces]).not_to be_empty
      expect(result[:file_type]).to eq(:memory)
    end

    it 'returns error for missing file' do
      result = runner.preview_ingest(file_path: '/nonexistent/file.md')
      expect(result[:error]).to eq('file not found')
    end
  end
end
