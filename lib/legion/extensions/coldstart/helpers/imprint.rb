# frozen_string_literal: true

module Legion
  module Extensions
    module Coldstart
      module Helpers
        module Imprint
          # Three learning layers (spec: cold-start-spec.md)
          LAYERS = %i[firmware imprint_window continuous_learning].freeze

          # Imprint window parameters
          IMPRINT_DURATION        = 7 * 86_400 # 7 days
          IMPRINT_MULTIPLIER      = 3.0        # consolidation rate multiplier during imprint
          IMPRINT_CONSENT_TIER    = :consult    # conservative consent during imprint
          IMPRINT_ENTROPY_BASELINE = 50        # minimum observations before entropy is meaningful

          # Self-play bootstrap parameters
          SELF_PLAY_ITERATIONS    = 100
          BOOTSTRAP_TRACE_TYPES   = %i[identity semantic procedural].freeze

          module_function

          def imprint_active?(started_at)
            return false unless started_at

            (Time.now.utc - started_at) < IMPRINT_DURATION
          end

          def imprint_progress(started_at)
            return 1.0 unless started_at

            elapsed = Time.now.utc - started_at
            [elapsed / IMPRINT_DURATION.to_f, 1.0].min
          end

          def current_layer(started_at, observations:)
            if observations < IMPRINT_ENTROPY_BASELINE && imprint_active?(started_at)
              :imprint_window
            elsif imprint_active?(started_at)
              :imprint_window
            else
              :continuous_learning
            end
          end
        end
      end
    end
  end
end
