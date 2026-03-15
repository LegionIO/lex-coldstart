# frozen_string_literal: true

# Stub the framework actor base class since legionio gem is not available in test
module Legion
  module Extensions
    module Actors
      class Once # rubocop:disable Lint/EmptyClass
      end
    end
  end
end

# Intercept the require in the actor file so it doesn't fail
$LOADED_FEATURES << 'legion/extensions/actors/once'

require 'legion/extensions/coldstart/actors/imprint'

RSpec.describe Legion::Extensions::Coldstart::Actor::Imprint do
  subject(:actor) { described_class.new }

  describe '#runner_class' do
    it 'returns the Coldstart runner module' do
      expect(actor.runner_class).to eq(Legion::Extensions::Coldstart::Runners::Coldstart)
    end
  end

  describe '#runner_function' do
    it 'returns begin_imprint' do
      expect(actor.runner_function).to eq('begin_imprint')
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(actor.check_subtask?).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(actor.generate_task?).to be false
    end
  end
end
