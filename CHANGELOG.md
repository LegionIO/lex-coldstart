# Changelog

## [0.1.4] - 2026-04-03

### Changed
- add idempotency guard to `begin_imprint` (no-op if already started, unless `force: true`)
- add specs for `begin_imprint` idempotency and force-reset behavior

## [0.1.3] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

## [0.1.2] - 2026-03-26

### Changed
- Migrate from lex-memory to lex-agentic-memory for trace storage
- `memory_available?` and `memory_runner` now reference `Legion::Extensions::Agentic::Memory::Trace::Runners::Traces`

## [0.1.1] - 2026-03-22

### Added
- `spec/legion/extensions/coldstart/actors/imprint_spec.rb` (5 examples) — tests for the Imprint actor (Once)

### Changed
- Add legion-* sub-gems as runtime dependencies (legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport)
- Replace direct `Legion::Logging.info/debug/warn` calls with injected `log` helper in runners/coldstart.rb and runners/ingest.rb
- Update spec_helper with real sub-gem helper stubs (removes Legion::Logging stub, adds Helpers::Lex with all 7 helper modules)

## [0.1.0] - 2026-03-13

### Added
- Initial release
