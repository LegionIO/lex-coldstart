# frozen_string_literal: true

require 'legion/extensions/coldstart/version'
require 'legion/extensions/coldstart/helpers/imprint'
require 'legion/extensions/coldstart/helpers/bootstrap'
require 'legion/extensions/coldstart/helpers/claude_parser'
require 'legion/extensions/coldstart/runners/coldstart'
require 'legion/extensions/coldstart/runners/ingest'

module Legion
  module Extensions
    module Coldstart
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
