# frozen_string_literal: true

require 'legion/extensions/coldstart/client'

RSpec.describe Legion::Extensions::Coldstart::Client do
  it 'responds to coldstart runner methods' do
    client = described_class.new
    expect(client).to respond_to(:begin_imprint)
    expect(client).to respond_to(:record_observation)
    expect(client).to respond_to(:coldstart_progress)
    expect(client).to respond_to(:imprint_active?)
    expect(client).to respond_to(:current_multiplier)
  end
end
