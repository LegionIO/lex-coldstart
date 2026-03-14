# frozen_string_literal: true

module Legion
  module Extensions
    module Coldstart
      module Helpers
        module ClaudeParser
          module_function

          SECTION_TYPE_MAP = {
            /\bhard rules\b/i                        => :firmware,
            /\bidentity auth\b/i                     => :identity,
            /\barchitecture\b/i                      => :semantic,
            /\bkey concepts?\b|terminology/i         => :semantic,
            /\bproject structure\b/i                 => :semantic,
            /\bdigital worker\b/i                    => :semantic,
            /\bgotcha|caveat|pitfall|known issue/i   => :procedural,
            /\bcli\b|command|usage/i                 => :procedural,
            /\bapi\b|routes?\b|endpoint/i            => :procedural,
            /\bmcp\b/i                               => :procedural,
            /\bconfig|settings?\b|scaffold/i         => :procedural,
            /\bskills?\b/i                           => :procedural,
            /\bdevelopment|conventions?\b|workflow/i => :procedural,
            /\brubocop|lint/i                        => :procedural,
            /\bdependenc/i                           => :semantic,
            /\bfile (map|structure)\b/i              => :semantic,
            /\bwhat is\b/i                           => :semantic,
            /\bpurpose\b/i                           => :semantic,
            /\bstatus|stub|todo\b/i                  => :semantic,
            /\bagentic\b/i                           => :semantic,
            /\bjwt\b|auth|crypt|secur/i              => :procedural,
            /\bsinatra\b|rest\b/i                    => :procedural,
            /\btransport|rabbitmq|amqp/i             => :semantic
          }.freeze

          DEFAULT_TRACE_TYPE = :semantic

          SECTION_VALENCE_MAP = {
            /\bgotcha|caveat|pitfall|known issue|error|stub|todo\b/i => { valence: -0.4, intensity: 0.5 },
            /\bhard rules?\b/i                                       => { valence: 0.0,  intensity: 0.8 },
            /\barchitecture\b|design|key concepts?\b/i               => { valence: 0.3,  intensity: 0.4 },
            /\bdependenc|integration|requirements?\b/i               => { valence: 0.1, intensity: 0.3 }
          }.freeze

          DEFAULT_VALENCE = { valence: 0.1, intensity: 0.3 }.freeze

          # Parse a markdown file into an array of trace candidates.
          # Each candidate is a Hash ready for lex-memory's store_trace.
          #
          # Returns Array<Hash> with keys:
          #   :trace_type, :content_payload, :domain_tags, :origin, :confidence, :source_file
          def parse_file(file_path)
            content = File.read(file_path)
            file_type = detect_file_type(file_path)
            sections = split_sections(content)
            source_name = File.basename(file_path)
            dir_context = extract_dir_context(file_path)

            traces = []
            sections.each do |section|
              trace_type = classify_section(section[:heading])
              base_tags = [file_type.to_s, source_name, dir_context].compact
              base_tags << section[:heading_slug] if section[:heading_slug]

              items = extract_items(section[:body])
              items.each do |item|
                inline_tags = extract_inline_tags(item)
                section_valence = classify_valence(section[:heading])
                traces << {
                  trace_type:          trace_type,
                  content_payload:     item.strip,
                  domain_tags:         (base_tags + inline_tags).uniq,
                  origin:              file_type == :memory ? :firmware : :direct_experience,
                  confidence:          trace_type == :firmware ? 1.0 : 0.7,
                  emotional_valence:   trace_type == :firmware ? 0.0 : section_valence[:valence],
                  emotional_intensity: section_valence[:intensity],
                  source_file:         file_path
                }
              end
            end

            traces.reject { |t| t[:content_payload].empty? }
          end

          # Parse all matching markdown files under a directory.
          # Returns Array<Hash> of trace candidates.
          def parse_directory(dir_path, pattern: '**/{CLAUDE,MEMORY}.md')
            Dir.glob(File.join(dir_path, pattern)).flat_map do |path|
              next [] if skip_path?(path)

              parse_file(path)
            end
          end

          # Detect whether a file is a MEMORY.md or CLAUDE.md
          def detect_file_type(file_path)
            basename = File.basename(file_path).downcase
            if basename.include?('memory') && basename.end_with?('.md')
              :memory
            elsif basename.include?('claude') && basename.end_with?('.md')
              :claude_md
            else
              :markdown
            end
          end

          # Split markdown content into sections by ## headers.
          # Returns Array<Hash{ heading:, heading_slug:, body: }>
          def split_sections(content)
            sections = []
            current = { heading: 'preamble', heading_slug: 'preamble', body: String.new }

            content.each_line do |line|
              if line.match?(/\A##\s+/)
                sections << current unless current[:body].strip.empty?
                heading = line.sub(/\A##\s+/, '').strip
                current = {
                  heading:      heading,
                  heading_slug: slugify(heading),
                  body:         String.new
                }
              else
                current[:body] << line
              end
            end
            sections << current unless current[:body].strip.empty?
            sections
          end

          # Extract individual items from a section body.
          # Bullets become individual items; paragraphs become single items;
          # code blocks are kept as single items.
          def extract_items(body) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            items = []
            current_item = nil
            in_code_block = false

            body.each_line do |line|
              if line.match?(/\A```/)
                if in_code_block
                  current_item << line
                  items << current_item
                  current_item = nil
                  in_code_block = false
                else
                  items << current_item if current_item && !current_item.strip.empty?
                  current_item = line
                  in_code_block = true
                end
                next
              end

              if in_code_block
                current_item << line
                next
              end

              if line.match?(/\A\s*[-*]\s+/)
                items << current_item if current_item && !current_item.strip.empty?
                current_item = line.sub(/\A\s*[-*]\s+/, '').strip
              elsif line.match?(/\A\s{2,}[-*]\s+/) || (current_item && line.match?(/\A\s{2,}\S/))
                # Sub-bullet or continuation of current bullet
                current_item = "#{current_item || ''} #{line.strip}"
              elsif line.strip.empty?
                items << current_item if current_item && !current_item.strip.empty?
                current_item = nil
              elsif current_item
                current_item += " #{line.strip}"
              else
                current_item = line.strip
              end
            end
            items << current_item if current_item && !current_item.strip.empty?

            items.compact.map(&:strip).reject(&:empty?)
          end

          # Extract backtick-quoted terms and bold terms as domain tags.
          def extract_inline_tags(text)
            tags = []
            text.scan(/`([^`]+)`/) { |m| tags << m[0] }
            text.scan(/\*\*([^*]+)\*\*/) { |m| tags << m[0] }
            tags.map { |t| t.gsub(/[^a-zA-Z0-9_\-.]/, '_').downcase }
                .reject { |t| t.length > 60 || t.length < 2 }
                .uniq
          end

          # Classify a section heading into a trace type.
          def classify_section(heading)
            SECTION_TYPE_MAP.each do |pattern, type|
              return type if heading.match?(pattern)
            end
            DEFAULT_TRACE_TYPE
          end

          # Classify a section heading into an emotional valence hash.
          def classify_valence(heading)
            SECTION_VALENCE_MAP.each do |pattern, vals|
              return vals if heading.match?(pattern)
            end
            DEFAULT_VALENCE
          end

          # Extract directory context for domain tagging (e.g., "lex-coldstart", "LegionIO").
          def extract_dir_context(file_path)
            parts = file_path.split('/')
            # Find the most meaningful directory name
            meaningful = parts.reverse.find do |p|
              p.match?(/\A(lex-|legion-|Legion|extensions)/) && p != File.basename(file_path)
            end
            meaningful || parts[-2]
          end

          def slugify(text)
            text.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
          end

          def skip_path?(path)
            path.include?('/_deprecated/') ||
              path.include?('/_ignored/') ||
              path.include?('/z_other/') ||
              path.include?('_working/') ||
              path.include?('/test/') ||
              path.include?('/.terraform/') ||
              path.include?('/references/')
          end
        end
      end
    end
  end
end
