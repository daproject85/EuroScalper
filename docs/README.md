# Shared Logging (for both EAs)

- Intent: one logging module both EAs can call into.
- Levels: `none`, `basic`, `debug`, `trace`.
- Output: CSV lines matching `tests/parity/LOG_SCHEMA.md`.
- Add lightweight timestamping and symbol/magic fields; avoid sleeps or heavy IO.
