# frozen_string_literal: true

require 'bundler/setup'
require 'legion/extensions/coldstart'

# Stub Legion::Logging if not already defined (standalone test context)
unless defined?(Legion::Logging)
  module Legion
    module Logging
      module_function

      def info(*); end

      def debug(*); end

      def warn(*); end

      def error(*); end
    end
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
