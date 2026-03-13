# frozen_string_literal: true

require 'legion/extensions/coldstart/client'

RSpec.describe Legion::Extensions::Coldstart::Runners::Coldstart do
  let(:client) { Legion::Extensions::Coldstart::Client.new }

  describe '#begin_imprint' do
    it 'starts the imprint window' do
      result = client.begin_imprint
      expect(result[:started]).to be true
      expect(result[:multiplier]).to eq(3.0)
    end
  end

  describe '#record_observation' do
    it 'increments observation count' do
      client.begin_imprint
      result = client.record_observation
      expect(result[:observation_count]).to eq(1)
    end

    it 'transitions calibration state at baseline threshold' do
      client.begin_imprint
      50.times { client.record_observation }
      result = client.record_observation
      expect(result[:calibration_state]).to eq(:baseline_established)
    end
  end

  describe '#coldstart_progress' do
    it 'reports progress' do
      client.begin_imprint
      result = client.coldstart_progress
      expect(result[:firmware_loaded]).to be true
      expect(result[:imprint_active]).to be true
      expect(result[:current_layer]).to eq(:imprint_window)
    end
  end

  describe '#imprint_active?' do
    it 'returns false before begin' do
      result = client.imprint_active?
      expect(result[:active]).to be false
    end

    it 'returns true after begin' do
      client.begin_imprint
      result = client.imprint_active?
      expect(result[:active]).to be true
    end
  end

  describe '#current_multiplier' do
    it 'returns 1.0 when not imprinting' do
      result = client.current_multiplier
      expect(result[:multiplier]).to eq(1.0)
    end

    it 'returns 3.0 during imprint' do
      client.begin_imprint
      result = client.current_multiplier
      expect(result[:multiplier]).to eq(3.0)
    end
  end
end
