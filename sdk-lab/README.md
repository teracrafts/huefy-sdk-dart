# Huefy Dart SDK Lab

Verifies the core email contract through the real Dart email client against a local stub server.

## Run

```bash
dart sdk-lab/run.dart
```

from `sdks/dart/`.

## Scenarios

1. Initialization
2. Single-send contract shaping
3. Bulk-send contract shaping
4. Invalid single rejection
5. Invalid bulk rejection
6. Health request path behavior
7. Cleanup

## Notes

- The lab uses a loopback stub server instead of the live API.
- It checks serialized request bodies, parsed responses, and validation-before-transport behavior.
