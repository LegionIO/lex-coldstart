# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:bootstrap_state) do
      primary_key :id
      Integer :started_at_i
      Integer :observation_count, default: 0
      TrueClass :firmware_loaded, default: false
      String :calibration_state, default: 'not_started'
    end
  end
end
