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
          end

          def begin_imprint
            @started_at = Time.now.utc
            @calibration_state = :imprinting
          end

          def load_firmware
            @firmware_loaded = true
          end

          def record_observation
            @observation_count += 1
            check_calibration_progress
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
              firmware_loaded:    @firmware_loaded,
              imprint_active:     imprint_active?,
              imprint_progress:   Imprint.imprint_progress(@started_at),
              observation_count:  @observation_count,
              calibration_state:  @calibration_state,
              current_layer:      current_layer
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
        end
      end
    end
  end
end
