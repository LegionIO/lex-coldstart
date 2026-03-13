# frozen_string_literal: true

require 'legion/extensions/coldstart/helpers/imprint'
require 'legion/extensions/coldstart/helpers/bootstrap'
require 'legion/extensions/coldstart/runners/coldstart'

module Legion
  module Extensions
    module Coldstart
      class Client
        include Runners::Coldstart

        def initialize(**)
          @bootstrap = Helpers::Bootstrap.new
        end

        private

        attr_reader :bootstrap
      end
    end
  end
end
