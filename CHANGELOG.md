# Changelog

[![SemVer 2.0.0][📌semver-img]][📌semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][📗keep-changelog],
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
and [yes][📌major-versions-not-sacred], platform and engine support are part of the [public API][📌semver-breaking].
Please file a bug if you notice a violation of semantic versioning.

[📌semver]: https://semver.org/spec/v2.0.0.html
[📌semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

## [Unreleased]

### Added

### Changed

- Replaced scaffold gemspec summary and description placeholders with
  kettle-rb-specific package metadata.

### Deprecated

### Removed

### Fixed

- Package the named `MIT.md` license file in the generated gemspec file list.
- Removed the scaffolded root RBS `VERSION` declaration so the style workflow's
  RBS environment load no longer sees a duplicate `Kettle::Rb::VERSION`.

### Security

## [0.1.1] - 2026-06-29

- TAG: [v0.1.1][0.1.1t]
- COVERAGE: 89.47% -- 68/76 lines in 3 files
- BRANCH COVERAGE: 75.00% -- 12/16 branches in 3 files
- 43.90% documented

### Changed

- Updated RuboCop-LTS compatibility matrix floors to the latest released
  repaired `rubocop-lts` branch stack and wrapper gem versions.
- Removed the default `RUBOCOP_LTS_LOCAL=false` development environment export
  so released RuboCop-LTS gems are selected by absence of local-mode override.

## [0.1.0] - 2026-06-27

- TAG: [v0.1.0][0.1.0t]
- COVERAGE: 89.47% -- 68/76 lines in 3 files
- BRANCH COVERAGE: 75.00% -- 12/16 branches in 3 files
- 43.90% documented
- Initial release

### Added

- Add `Kettle::Rb::CompatMatrix` as the shared Ruby, engine, Rails, RuboCop,
  and RuboCop LTS compatibility source of truth for kettle-rb tooling.

[Unreleased]: https://github.com/kettle-dev/kettle-rb/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/kettle-dev/kettle-rb/compare/v0.1.0...v0.1.1
[0.1.1t]: https://github.com/kettle-dev/kettle-rb/releases/tag/v0.1.1
[0.1.0]: https://github.com/kettle-dev/kettle-rb/compare/7d715a6109f43ab78253e31ea49b280b659a060d...v0.1.0
[0.1.0t]: https://github.com/kettle-dev/kettle-rb/releases/tag/v0.1.0
