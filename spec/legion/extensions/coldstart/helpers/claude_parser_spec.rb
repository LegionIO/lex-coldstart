# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Coldstart::Helpers::ClaudeParser do
  let(:fixture_dir) { File.expand_path('../../../../fixtures', __dir__) }
  let(:memory_path) { File.join(fixture_dir, 'sample_memory.md') }
  let(:claude_path) { File.join(fixture_dir, 'sample_claude.md') }

  describe '.detect_file_type' do
    it 'detects MEMORY.md files' do
      expect(described_class.detect_file_type('/some/path/MEMORY.md')).to eq(:memory)
    end

    it 'detects CLAUDE.md files' do
      expect(described_class.detect_file_type('/some/path/CLAUDE.md')).to eq(:claude_md)
    end

    it 'returns :markdown for other files' do
      expect(described_class.detect_file_type('/some/path/README.md')).to eq(:markdown)
    end
  end

  describe '.classify_section' do
    it 'maps Hard Rules to firmware' do
      expect(described_class.classify_section('Hard Rules')).to eq(:firmware)
    end

    it 'maps architecture sections to semantic' do
      expect(described_class.classify_section('Key Architecture Facts')).to eq(:semantic)
    end

    it 'maps gotchas to procedural' do
      expect(described_class.classify_section('CLI Gotchas')).to eq(:procedural)
    end

    it 'maps identity sections to identity' do
      expect(described_class.classify_section('Identity Auth Pattern')).to eq(:identity)
    end

    it 'defaults to semantic for unknown sections' do
      expect(described_class.classify_section('Random Stuff')).to eq(:semantic)
    end

    it 'maps development sections to procedural' do
      expect(described_class.classify_section('Development')).to eq(:procedural)
    end

    it 'maps API sections to procedural' do
      expect(described_class.classify_section('REST API Routes')).to eq(:procedural)
    end
  end

  describe '.split_sections' do
    it 'splits on ## headers' do
      content = "## First\nline1\n## Second\nline2\n"
      sections = described_class.split_sections(content)
      expect(sections.size).to eq(2)
      expect(sections[0][:heading]).to eq('First')
      expect(sections[1][:heading]).to eq('Second')
    end

    it 'creates slugs from headings' do
      content = "## Key Architecture Facts\nstuff\n"
      sections = described_class.split_sections(content)
      expect(sections[0][:heading_slug]).to eq('key-architecture-facts')
    end

    it 'skips empty sections' do
      content = "## Empty\n\n## HasContent\nreal stuff\n"
      sections = described_class.split_sections(content)
      expect(sections.size).to eq(1)
      expect(sections[0][:heading]).to eq('HasContent')
    end
  end

  describe '.extract_items' do
    it 'extracts bullet points as individual items' do
      body = "- first item\n- second item\n- third item\n"
      items = described_class.extract_items(body)
      expect(items).to eq(['first item', 'second item', 'third item'])
    end

    it 'merges continuation lines into bullets' do
      body = "- first item\n  continued here\n- second item\n"
      items = described_class.extract_items(body)
      expect(items.size).to eq(2)
      expect(items[0]).to include('continued here')
    end

    it 'keeps code blocks as single items' do
      body = "- before\n```ruby\ncode here\nmore code\n```\n- after\n"
      items = described_class.extract_items(body)
      expect(items.any? { |i| i.include?('code here') }).to be true
    end

    it 'handles paragraphs' do
      body = "This is a paragraph\nwith continuation.\n\nAnother paragraph.\n"
      items = described_class.extract_items(body)
      expect(items.size).to eq(2)
    end
  end

  describe '.extract_inline_tags' do
    it 'extracts backtick terms' do
      tags = described_class.extract_inline_tags('Uses `legion-transport` for messaging')
      expect(tags).to include('legion-transport')
    end

    it 'extracts bold terms' do
      tags = described_class.extract_inline_tags('The **Runner** processes tasks')
      expect(tags).to include('runner')
    end

    it 'rejects very short or very long tags' do
      tags = described_class.extract_inline_tags('`x` and `a_very_long_tag_' + 'x' * 60 + '`')
      expect(tags).to be_empty
    end
  end

  describe '.parse_file' do
    it 'parses a MEMORY.md file into traces' do
      traces = described_class.parse_file(memory_path)
      expect(traces).to be_an(Array)
      expect(traces).not_to be_empty
    end

    it 'assigns firmware type to Hard Rules' do
      traces = described_class.parse_file(memory_path)
      firmware = traces.select { |t| t[:trace_type] == :firmware }
      expect(firmware).not_to be_empty
      expect(firmware.first[:content_payload]).to include('production data')
    end

    it 'assigns procedural type to gotchas' do
      traces = described_class.parse_file(memory_path)
      procedural = traces.select { |t| t[:trace_type] == :procedural }
      expect(procedural).not_to be_empty
      expect(procedural.any? { |t| t[:content_payload].include?('Thor') }).to be true
    end

    it 'assigns identity type to identity sections' do
      traces = described_class.parse_file(memory_path)
      identity = traces.select { |t| t[:trace_type] == :identity }
      expect(identity).not_to be_empty
    end

    it 'sets origin to :firmware for MEMORY.md files' do
      traces = described_class.parse_file(memory_path)
      # All traces from MEMORY.md get :firmware origin (imprint source)
      expect(traces.all? { |t| t[:origin] == :firmware }).to be true
    end

    it 'sets origin to :direct_experience for CLAUDE.md files' do
      traces = described_class.parse_file(claude_path)
      expect(traces.all? { |t| t[:origin] == :direct_experience }).to be true
    end

    it 'sets confidence 1.0 for firmware traces' do
      traces = described_class.parse_file(memory_path)
      firmware = traces.select { |t| t[:trace_type] == :firmware }
      expect(firmware.all? { |t| t[:confidence] == 1.0 }).to be true
    end

    it 'includes source_file in each trace' do
      traces = described_class.parse_file(memory_path)
      expect(traces.all? { |t| t[:source_file] == memory_path }).to be true
    end

    it 'includes domain tags' do
      traces = described_class.parse_file(memory_path)
      expect(traces.all? { |t| t[:domain_tags].is_a?(Array) && !t[:domain_tags].empty? }).to be true
    end

    it 'parses a CLAUDE.md file into traces' do
      traces = described_class.parse_file(claude_path)
      expect(traces).not_to be_empty
      semantic = traces.select { |t| t[:trace_type] == :semantic }
      expect(semantic).not_to be_empty
    end
  end

  describe '.parse_directory' do
    it 'finds and parses all matching files' do
      traces = described_class.parse_directory(fixture_dir, pattern: '*.md')
      expect(traces).not_to be_empty
      source_files = traces.map { |t| t[:source_file] }.uniq
      expect(source_files.size).to be >= 2
    end
  end

  describe '.skip_path?' do
    it 'skips _deprecated paths' do
      expect(described_class.skip_path?('/foo/_deprecated/CLAUDE.md')).to be true
    end

    it 'skips references paths' do
      expect(described_class.skip_path?('/foo/references/CLAUDE.md')).to be true
    end

    it 'allows normal paths' do
      expect(described_class.skip_path?('/foo/lex-memory/CLAUDE.md')).to be false
    end
  end
end
