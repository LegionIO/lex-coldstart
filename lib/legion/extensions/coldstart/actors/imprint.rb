# frozen_string_literal: true

require 'legion/extensions/actors/once'

module Legion
  module Extensions
    module Coldstart
      module Actor
        class Imprint < Legion::Extensions::Actors::Once
          def runner_class
            Legion::Extensions::Coldstart::Runners::Coldstart
          end

          def runner_function
            'begin_imprint'
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
