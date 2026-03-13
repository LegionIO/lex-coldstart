# frozen_string_literal: true

require 'legion/extensions/coldstart/version'
require 'legion/extensions/coldstart/helpers/imprint'
require 'legion/extensions/coldstart/helpers/bootstrap'
require 'legion/extensions/coldstart/runners/coldstart'

module Legion
  module Extensions
    module Coldstart
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
