# frozen_string_literal: true

require 'spec_helper'
require 'sequel'
require 'sequel/extensions/migration'

RSpec.describe 'lex-coldstart local persistence' do
  let(:db) { Sequel.sqlite }
  let(:migration_path) do
    File.join(__dir__, '..', 'lib', 'legion', 'extensions', 'coldstart', 'local_migrations')
  end

  before do
    Sequel::TimestampMigrator.new(db, migration_path).run
    stub_const('Legion::Data::Local', local_mod)
  end

  let(:local_mod) do
    db_ref = db
    Module.new do
      define_singleton_method(:connected?) { true }
      define_singleton_method(:connection) { db_ref }
    end
  end

  def fresh_bootstrap
    Legion::Extensions::Coldstart::Helpers::Bootstrap.new
  end

  describe 'save and load round-trip' do
    it 'persists firmware_loaded after load_firmware' do
      b = fresh_bootstrap
      b.load_firmware
      b2 = fresh_bootstrap
      expect(b2.firmware_loaded).to be true
    end

    it 'persists observation_count after record_observation calls' do
      b = fresh_bootstrap
      b.begin_imprint
      3.times { b.record_observation }
      b2 = fresh_bootstrap
      expect(b2.observation_count).to eq(3)
    end

    it 'persists calibration_state as a symbol' do
      b = fresh_bootstrap
      b.begin_imprint
      b2 = fresh_bootstrap
      expect(b2.calibration_state).to eq(:imprinting)
    end
  end

  describe 'started_at preservation (imprint window survives restarts)' do
    it 'restores started_at so the 7-day window continues from the original time' do
      b = fresh_bootstrap
      b.begin_imprint
      original_started_at = b.started_at

      b2 = fresh_bootstrap
      expect(b2.started_at).not_to be_nil
      expect(b2.started_at.to_i).to be_within(1).of(original_started_at.to_i)
    end

    it 'reports imprint still active after reload within the 7-day window' do
      b = fresh_bootstrap
      b.begin_imprint
      b2 = fresh_bootstrap
      expect(b2.imprint_active?).to be true
    end

    it 'does not reset started_at to nil on second boot' do
      b = fresh_bootstrap
      b.begin_imprint
      b2 = fresh_bootstrap
      expect(b2.started_at).not_to be_nil
    end

    it 'does not reset started_at when begin_imprint is called again without force' do
      first_time = Time.utc(2026, 4, 2, 12, 0, 0)
      second_time = first_time + 60
      allow(Time).to receive(:now).and_return(first_time, second_time)

      b = fresh_bootstrap
      b.begin_imprint
      original_started_at = b.started_at

      b.begin_imprint

      expect(b.started_at.to_i).to eq(original_started_at.to_i)
    end

    it 'resets started_at when begin_imprint is called with force: true' do
      first_time = Time.utc(2026, 4, 2, 12, 0, 0)
      second_time = first_time + 60
      allow(Time).to receive(:now).and_return(first_time, second_time)

      b = fresh_bootstrap
      b.begin_imprint
      original_started_at = b.started_at

      b.begin_imprint(force: true)

      expect(b.started_at.to_i).to be > original_started_at.to_i
    end
  end

  describe 'calibration_state symbol round-trip' do
    %i[not_started imprinting baseline_established calibrated].each do |state|
      it "persists and restores :#{state}" do
        fresh_bootstrap
        # Force the state directly through the DB to test all symbol variants
        db[:bootstrap_state].where(id: 1).delete
        db[:bootstrap_state].insert(
          id:                1,
          started_at_i:      nil,
          observation_count: 0,
          firmware_loaded:   false,
          calibration_state: state.to_s
        )
        b2 = fresh_bootstrap
        expect(b2.calibration_state).to eq(state)
      end
    end
  end

  describe 'graceful no-op when Local is not connected' do
    before do
      stub_const('Legion::Data::Local', disconnected_mod)
    end

    let(:disconnected_mod) do
      Module.new do
        define_singleton_method(:connected?) { false }
      end
    end

    it 'does not raise on begin_imprint' do
      expect { fresh_bootstrap.begin_imprint }.not_to raise_error
    end

    it 'does not raise on load_firmware' do
      expect { fresh_bootstrap.load_firmware }.not_to raise_error
    end

    it 'does not raise on record_observation' do
      b = fresh_bootstrap
      b.begin_imprint
      expect { b.record_observation }.not_to raise_error
    end

    it 'leaves state at defaults when nothing is persisted' do
      b = fresh_bootstrap
      expect(b.started_at).to be_nil
      expect(b.observation_count).to eq(0)
      expect(b.firmware_loaded).to be false
      expect(b.calibration_state).to eq(:not_started)
    end
  end

  describe 'graceful no-op when Legion::Data::Local is not defined' do
    it 'does not raise on initialize when constant is absent' do
      hide_const('Legion::Data::Local')
      expect { fresh_bootstrap }.not_to raise_error
    end
  end
end
