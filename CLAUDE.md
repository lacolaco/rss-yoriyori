# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

rss_yoriyori is a Gleam library/application. Gleam is a type-safe functional programming language that compiles to Erlang and JavaScript.

## Build Commands

```sh
gleam build      # Compile the project
gleam run        # Run the project
gleam test       # Run all tests
gleam docs build # Generate documentation
```

## Testing

Tests are located in `test/` and use the gleeunit testing framework. Test functions must end with `_test` suffix to be discovered and run.

## Project Structure

- `src/` - Source files (`.gleam`)
- `test/` - Test files (`.gleam`)
- `gleam.toml` - Project configuration and dependencies
- `manifest.toml` - Locked dependency versions (auto-generated)

## Gleam Language Notes

- Gleam uses `assert` for assertions in tests
- String concatenation uses `<>`
- All functions must have explicit return types
- Pattern matching is the primary control flow mechanism
