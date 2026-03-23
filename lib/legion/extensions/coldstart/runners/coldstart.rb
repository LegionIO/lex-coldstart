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
            dur = Helpers::Imprint::IMPRINT_DURATION
            mul = Helpers::Imprint::IMPRINT_MULTIPLIER
            tier = Helpers::Imprint::IMPRINT_CONSENT_TIER
            log.info "[coldstart] imprint begun: duration=#{dur}s multiplier=#{mul}x consent=#{tier}"
            {
              started:          true,
              imprint_duration: Helpers::Imprint::IMPRINT_DURATION,
              multiplier:       Helpers::Imprint::IMPRINT_MULTIPLIER,
              consent_tier:     Helpers::Imprint::IMPRINT_CONSENT_TIER
            }
          end

          def record_observation(**)
            bootstrap.record_observation
            log.debug "[coldstart] observation: count=#{bootstrap.observation_count} " \
                      "calibration=#{bootstrap.calibration_state} layer=#{bootstrap.current_layer}"
            {
              observation_count: bootstrap.observation_count,
              calibration_state: bootstrap.calibration_state,
              current_layer:     bootstrap.current_layer
            }
          end

          def coldstart_progress(**)
            progress = bootstrap.progress
            log.debug "[coldstart] progress: #{progress.inspect}"
            progress
          end

          def imprint_active?(**) # rubocop:disable Naming/PredicateMethod
            active = bootstrap.imprint_active?
            log.debug "[coldstart] imprint_active?=#{active}"
            { active: active }
          end

          def current_multiplier(**)
            active = bootstrap.imprint_active?
            multiplier = active ? Helpers::Imprint::IMPRINT_MULTIPLIER : 1.0
            log.debug "[coldstart] multiplier=#{multiplier} imprint_active=#{active}"
            { multiplier: multiplier, imprint_active: active }
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
