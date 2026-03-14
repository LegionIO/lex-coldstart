# lex-coldstart

Imprint window and bootstrap calibration for brain-modeled agentic AI. Manages the agent's initial learning period with an accelerated consolidation multiplier and three-phase learning architecture.

## Overview

`lex-coldstart` implements the agent's bootstrap sequence. When an agent is first instantiated, it enters an imprint window (7 days by default) during which memory consolidation is tripled and consent is held at the conservative `:consult` tier. After the imprint window, the agent transitions to continuous learning.

## Learning Phases

| Phase | Description |
|-------|-------------|
| `firmware` | Hardcoded values loaded before any observations |
| `imprint_window` | First 7 days — accelerated learning (3x multiplier) |
| `continuous_learning` | Post-imprint — normal operation |

## Key Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Imprint duration | 7 days | Length of the imprint window |
| Imprint multiplier | 3.0x | Memory consolidation boost during imprint |
| Consent tier during imprint | `:consult` | Conservative — always ask before acting |
| Entropy baseline | 50 observations | Minimum before entropy is meaningful |
| Self-play iterations | 100 | Bootstrap trace generation count |

## Installation

Add to your Gemfile:

```ruby
gem 'lex-coldstart'
```

## Usage

### Starting the Imprint

```ruby
require 'legion/extensions/coldstart'

# Load firmware and begin imprint window
result = Legion::Extensions::Coldstart::Runners::Coldstart.begin_imprint
# => { started: true, imprint_duration: 604800,
#      multiplier: 3.0, consent_tier: :consult }
```

### Recording Observations

```ruby
# Record that an observation occurred (increments counter toward entropy baseline)
Legion::Extensions::Coldstart::Runners::Coldstart.record_observation
# => { observation_count: 1, calibration_state: :imprinting, current_layer: :imprint_window }
```

### Checking Status

```ruby
# Is the imprint window still active?
Legion::Extensions::Coldstart::Runners::Coldstart.imprint_active?
# => { active: true }

# Get the current learning multiplier
Legion::Extensions::Coldstart::Runners::Coldstart.current_multiplier
# => { multiplier: 3.0, imprint_active: true }

# Full progress report
Legion::Extensions::Coldstart::Runners::Coldstart.coldstart_progress
# => { firmware_loaded: true, imprint_active: true,
#      imprint_progress: 0.14, observation_count: 7,
#      calibration_state: :imprinting, current_layer: :imprint_window }
```

## Calibration States

| State | Condition |
|-------|-----------|
| `:not_started` | Before `begin_imprint` |
| `:imprinting` | During imprint window |
| `:baseline_established` | >= 50 observations, imprint still active |
| `:calibrated` | >= 50 observations, imprint window expired |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
