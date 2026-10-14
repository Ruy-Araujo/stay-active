# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Linux X11 support using xdotool

### Changed
- Documented X11 requirements and the Wayland limitation

## [1.0.0] - 2025-12-09

### Added
- Initial release
- Mouse movement simulation (1-5 pixels, random direction)
- Keyboard activity simulation (Shift key press)
- Random intervals (30-60 seconds) with 15% shorter bursts
- Human-like behavior (60% chance to return to original position)
- Commands: start, stop, toggle, status, log
- Colored terminal output
- Activity logging
- Help and version flags
- One-command installer script
- Uninstaller script

### Technical Details
- Pure Bash implementation
- Uses cliclick on macOS and xdotool on Linux X11 for mouse/keyboard automation
- Runs as background daemon
- Control via file-based flags
