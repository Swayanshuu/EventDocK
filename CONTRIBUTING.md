# Contributing to EventDock

Thank you for your interest in contributing to EventDock!

## Code of Conduct

Please maintain a welcoming, respectful, and constructive environment.

## Development Workflow

1. Fork and clone the repository.
2. Ensure you have **Java 21 LTS**, **Maven 3.9+**, and **Flutter 3.24+** installed.
3. Build the monorepo:
   ```bash
   mvn clean install -DskipTests
   ```
4. Run automated tests:
   ```bash
   mvn clean test
   cd eventdock-dashboard && flutter test
   ```
5. Follow code style conventions specified in `.editorconfig`.

## Pull Request Guidelines

- Verify that all unit and integration tests pass before submitting.
- Avoid introducing unnecessary dependencies.
- Update documentation in `ABOUT.md` and `docs/` when introducing new features or altering configuration.
- Preserve sensitive data redaction policies and SSRF defenses.
