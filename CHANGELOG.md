# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.1

### Fixed
- Handle race condition where the process exits between checking for and reading its smaps_rollup file; memory stats are now returned as zeroes instead of raising `Errno::ENOENT`.
- Return zeroes instead of raising `Errno::EACCES` when the process is not readable by the current user.
- Ignore blank lines when parsing smaps data.
- Raise `ArgumentError` for unknown units even on non-Linux platforms instead of silently returning -1.

## 1.0.0

### Added
- Initial release.
