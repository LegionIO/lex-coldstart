# frozen_string_literal: true

module Legion
  module Extensions
    module Coldstart
      module Helpers
        class Bootstrap
          attr_reader :started_at, :observation_count, :firmware_loaded, :calibration_state

          def initialize
            @started_at = nil
            @observation_count = 0
            @firmware_loaded = false
            @calibration_state = :not_started
            load_from_local
          end

          def begin_imprint
            @started_at = Time.now.utc
            @calibration_state = :imprinting
            save_to_local
          end

          def load_firmware
            @firmware_loaded = true
            save_to_local
          end

          def record_observation
            @observation_count += 1
            check_calibration_progress
            save_to_local
          end

          def imprint_active?
            Imprint.imprint_active?(@started_at)
          end

          def current_layer
            return :firmware unless @firmware_loaded

            Imprint.current_layer(@started_at, observations: @observation_count)
          end

          def progress
            {
              firmware_loaded:   @firmware_loaded,
              imprint_active:    imprint_active?,
              imprint_progress:  Imprint.imprint_progress(@started_at),
              observation_count: @observation_count,
              calibration_state: @calibration_state,
              current_layer:     current_layer
            }
          end

          private

          def check_calibration_progress
            if @observation_count >= Imprint::IMPRINT_ENTROPY_BASELINE && !imprint_active?
              @calibration_state = :calibrated
            elsif @observation_count >= Imprint::IMPRINT_ENTROPY_BASELINE
              @calibration_state = :baseline_established
            end
          end

          def save_to_local
            return unless defined?(Legion::Data::Local) && Legion::Data::Local.connected?

            ds = Legion::Data::Local.connection[:bootstrap_state]
            row = {
              started_at_i:      @started_at&.to_i,
              observation_count: @observation_count,
              firmware_loaded:   @firmware_loaded,
              calibration_state: @calibration_state.to_s
            }
            if ds.where(id: 1).any?
              ds.where(id: 1).update(row)
            else
              ds.insert(row.merge(id: 1))
            end
          rescue StandardError => e
            Legion::Logging.warn "lex-coldstart: save_to_local failed: #{e.message}"
          end

          def load_from_local
            return unless defined?(Legion::Data::Local) && Legion::Data::Local.connected?

            row = Legion::Data::Local.connection[:bootstrap_state].where(id: 1).first
            return unless row

            @started_at        = row[:started_at_i] ? Time.at(row[:started_at_i]).utc : nil
            @observation_count = row[:observation_count].to_i
            @firmware_loaded   = [true, 1].include?(row[:firmware_loaded])
            @calibration_state = row[:calibration_state].to_sym
          rescue StandardError => e
            Legion::Logging.warn "lex-coldstart: load_from_local failed: #{e.message}"
          end
        end
      end
    end
  end
end
