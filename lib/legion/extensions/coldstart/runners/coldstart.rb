# frozen_string_literal: true

module Legion
  module Extensions
    module Coldstart
      module Runners
        module Coldstart
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def begin_imprint(**)
            bootstrap.load_firmware
            bootstrap.begin_imprint
            {
              started:          true,
              imprint_duration: Helpers::Imprint::IMPRINT_DURATION,
              multiplier:       Helpers::Imprint::IMPRINT_MULTIPLIER,
              consent_tier:     Helpers::Imprint::IMPRINT_CONSENT_TIER
            }
          end

          def record_observation(**)
            bootstrap.record_observation
            {
              observation_count: bootstrap.observation_count,
              calibration_state: bootstrap.calibration_state,
              current_layer:     bootstrap.current_layer
            }
          end

          def coldstart_progress(**)
            bootstrap.progress
          end

          def imprint_active?(**)
            { active: bootstrap.imprint_active? }
          end

          def current_multiplier(**)
            multiplier = bootstrap.imprint_active? ? Helpers::Imprint::IMPRINT_MULTIPLIER : 1.0
            { multiplier: multiplier, imprint_active: bootstrap.imprint_active? }
          end

          private

          def bootstrap
            @bootstrap ||= Helpers::Bootstrap.new
          end
        end
      end
    end
  end
end
