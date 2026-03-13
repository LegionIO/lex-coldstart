# lex-coldstart

**Level 3 Documentation**
- **Parent**: `extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Imprint window and bootstrap calibration for the LegionIO cognitive architecture. Controls the agent's three-phase learning lifecycle (firmware -> imprint_window -> continuous_learning) and provides the multiplier used by `lex-memory` for accelerated consolidation during the imprint window.

## Gem Info

- **Gem name**: `lex-coldstart`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Coldstart`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/coldstart/
  version.rb
  helpers/
    imprint.rb    # LAYERS, IMPRINT_DURATION, IMPRINT_MULTIPLIER, IMPRINT_CONSENT_TIER,
                  # IMPRINT_ENTROPY_BASELINE, SELF_PLAY_ITERATIONS, BOOTSTRAP_TRACE_TYPES
                  # module_function: imprint_active?, imprint_progress, current_layer
    bootstrap.rb  # Bootstrap class - firmware_loaded, started_at, observation tracking
  runners/
    coldstart.rb  # begin_imprint, record_observation, coldstart_progress, imprint_active?, current_multiplier
spec/
  legion/extensions/coldstart/
    runners/
      coldstart_spec.rb
    client_spec.rb
```

## Key Constants (Helpers::Imprint)

```ruby
LAYERS = %i[firmware imprint_window continuous_learning]
IMPRINT_DURATION         = 7 * 86_400  # 7 days in seconds
IMPRINT_MULTIPLIER       = 3.0
IMPRINT_CONSENT_TIER     = :consult
IMPRINT_ENTROPY_BASELINE = 50           # minimum observations for meaningful entropy
SELF_PLAY_ITERATIONS     = 100
BOOTSTRAP_TRACE_TYPES    = %i[identity semantic procedural]
```

## Bootstrap Class

`Helpers::Bootstrap` instance state:
- `@started_at` - nil until `begin_imprint` called
- `@observation_count` - incremented by `record_observation`
- `@firmware_loaded` - set to true by `load_firmware`
- `@calibration_state` - `:not_started` | `:imprinting` | `:baseline_established` | `:calibrated`

`check_calibration_progress` (private) transitions state:
- observations >= 50 and imprint active -> `:baseline_established`
- observations >= 50 and imprint expired -> `:calibrated`

`current_layer` returns `:firmware` until firmware loaded, then delegates to `Imprint.current_layer`.

## Imprint Progress

`Imprint.imprint_progress(started_at)` returns a `[0.0, 1.0]` fraction of elapsed/total duration. Returns 1.0 if `started_at` is nil (imprint considered complete/never started).

## Integration Points

- **lex-memory**: `Consolidation#reinforce` accepts `imprint_active:` flag; when true, applies `IMPRINT_MULTIPLIER = 3.0`
- **lex-consent**: default tier during imprint is `:consult` (from `IMPRINT_CONSENT_TIER`)
- **lex-tick**: coldstart status may be checked in the `procedural_check` phase to gate certain actions

## Development Notes

- `begin_imprint` calls both `load_firmware` and then `begin_imprint` on the Bootstrap instance — order matters; firmware must be loaded first
- `SELF_PLAY_ITERATIONS` and `BOOTSTRAP_TRACE_TYPES` are defined as constants but no self-play runner is implemented yet — reserved for future bootstrap automation
- `imprint_active?` is a predicate method; rubocop's `Naming/PredicateMethod` cop is disabled globally for the project
