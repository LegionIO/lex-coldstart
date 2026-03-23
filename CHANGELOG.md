# Changelog

## [Unreleased]

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
