# frozen_string_literal: true

module Legion
  module Extensions
    module Coldstart
      module Runners
        module Ingest
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          # Ingest a single Claude memory or CLAUDE.md file into agentic memory traces.
          # If lex-agentic-memory is not loaded, returns the parsed traces without storing.
          #
          # @param file_path [String] absolute path to the markdown file
          # @param store_traces [Boolean] whether to store into agentic memory (default: true)
          # @return [Hash] { file:, file_type:, traces_parsed:, traces_stored:, traces: }
          def ingest_file(file_path:, store_traces: true, **)
            unless File.exist?(file_path)
              log.warn "[coldstart:ingest] file not found: #{file_path}"
              return { file: file_path, error: 'file not found' }
            end

            candidates = Helpers::ClaudeParser.parse_file(file_path)
            file_type = Helpers::ClaudeParser.detect_file_type(file_path)
            log.info "[coldstart:ingest] parsed #{candidates.size} traces from #{file_path} (#{file_type})"

            stored = store_traces ? store_candidates(candidates) : []

            {
              file:          file_path,
              file_type:     file_type,
              traces_parsed: candidates.size,
              traces_stored: stored.size,
              traces:        stored.empty? ? candidates : stored
            }
          end

          # Ingest all CLAUDE.md and MEMORY.md files under a directory.
          #
          # @param dir_path [String] absolute path to the directory
          # @param pattern [String] glob pattern (default: '**/{CLAUDE,MEMORY}.md')
          # @param store_traces [Boolean] whether to store into agentic memory (default: true)
          # @return [Hash] { directory:, files_found:, total_parsed:, total_stored:, files: }
          def ingest_directory(dir_path:, pattern: '**/{CLAUDE,MEMORY}.md', store_traces: true, **)
            unless Dir.exist?(dir_path)
              log.warn "[coldstart:ingest] directory not found: #{dir_path}"
              return { directory: dir_path, error: 'directory not found' }
            end

            candidates = Helpers::ClaudeParser.parse_directory(dir_path, pattern: pattern)
            files = candidates.map { |c| c[:source_file] }.uniq
            log.info "[coldstart:ingest] parsed #{candidates.size} traces from #{files.size} files in #{dir_path}"

            stored = store_traces ? store_candidates(candidates) : []

            {
              directory:    dir_path,
              files_found:  files.size,
              total_parsed: candidates.size,
              total_stored: stored.size,
              files:        files
            }
          end

          # Preview what traces would be created from a file without storing them.
          #
          # @param file_path [String] absolute path to the markdown file
          # @return [Hash] { file:, file_type:, traces: }
          def preview_ingest(file_path:, **)
            return { file: file_path, error: 'file not found' } unless File.exist?(file_path)

            candidates = Helpers::ClaudeParser.parse_file(file_path)
            file_type = Helpers::ClaudeParser.detect_file_type(file_path)

            {
              file:      file_path,
              file_type: file_type,
              traces:    candidates
            }
          end

          private

          def store_candidates(candidates)
            return [] unless memory_available?

            imprint = imprint_active_now?
            runner  = memory_runner
            stored  = []

            candidates.each do |candidate|
              result = runner.store_trace(
                type:                candidate[:trace_type],
                content_payload:     candidate[:content_payload],
                domain_tags:         candidate[:domain_tags],
                origin:              candidate[:origin],
                confidence:          candidate[:confidence],
                imprint_active:      imprint,
                emotional_valence:   candidate[:emotional_valence] || 0.0,
                emotional_intensity: candidate[:emotional_intensity] || (candidate[:trace_type] == :firmware ? 0.8 : 0.3)
              )
              stored << result if result
            rescue StandardError => e
              log.warn "[coldstart:ingest] failed to store trace: #{e.message}"
            end

            # Flush the cache-backed store if it supports it
            store = runner.send(:default_store)
            store.flush if store.respond_to?(:flush)

            log.info "[coldstart:ingest] stored #{stored.size} traces (imprint_active=#{imprint})"

            # Co-activate traces from the same section to form Hebbian links
            coactivate_section_traces(stored, candidates, runner)

            stored
          end

          def memory_available?
            Legion::Extensions.const_defined?(:Agentic) &&
              Legion::Extensions::Agentic.const_defined?(:Memory) &&
              Legion::Extensions::Agentic::Memory.const_defined?(:Trace) &&
              Legion::Extensions::Agentic::Memory::Trace.const_defined?(:Runners) &&
              Legion::Extensions::Agentic::Memory::Trace::Runners.const_defined?(:Traces)
          end

          def memory_runner
            @memory_runner ||= Object.new.extend(Legion::Extensions::Agentic::Memory::Trace::Runners::Traces)
          end

          def imprint_active_now?
            bootstrap.imprint_active?
          rescue StandardError
            false
          end

          def bootstrap
            @bootstrap ||= Helpers::Bootstrap.new
          end

          def coactivate_section_traces(stored, candidates, runner)
            return if stored.size < 2

            store = runner.send(:default_store)

            # Group stored trace IDs by their heading_slug domain tag
            groups = {}
            stored.each_with_index do |result, idx|
              candidate = candidates[idx]
              next unless candidate && result

              slug = candidate[:domain_tags]&.find { |t| t.is_a?(String) && !%w[memory claude_md markdown].include?(t) && !t.include?('/') }
              next unless slug

              groups[slug] ||= []
              groups[slug] << result[:trace_id]
            end

            coactivations = 0
            groups.each_value do |trace_ids|
              # Limit to first 10 traces per section to avoid O(n^2) explosion
              trace_ids.first(10).combination(2).each do |id_a, id_b|
                store.record_coactivation(id_a, id_b)
                coactivations += 1
              end
            end

            log.debug "[coldstart:ingest] co-activated #{coactivations} trace pairs across #{groups.size} sections"
          rescue StandardError => e
            log.warn "[coldstart:ingest] co-activation failed: #{e.message}"
          end
        end
      end
    end
  end
end
