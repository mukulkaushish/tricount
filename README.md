# tricount

Flutter application workspace with a target architecture documented in `docs/`.

## Current Status

This repository is currently close to a starter Flutter app:

- `lib/` only contains `main.dart`
- `pubspec.yaml` still uses the default starter dependencies
- the architecture documented under `docs/` is a target state, not the current implementation

Read [docs/00B_PROJECT_STATUS_AND_ADOPTION.md](docs/00B_PROJECT_STATUS_AND_ADOPTION.md) before assuming a documented module or dependency already exists in code.

## Documentation Map

Start here:

1. [docs/00A_CODING_RULES.md](docs/00A_CODING_RULES.md)
2. [docs/00B_PROJECT_STATUS_AND_ADOPTION.md](docs/00B_PROJECT_STATUS_AND_ADOPTION.md)
3. [CLAUDE.md](CLAUDE.md)
4. [AGENTS.md](AGENTS.md)

Then use [docs/00_INDEX.md](docs/00_INDEX.md) as the main guide to the rest of the architecture docs.

## How To Use These Docs

- Treat `docs/01` through `docs/24` as the recommended architecture and delivery blueprint.
- Treat `docs/00B` as the source of truth for what exists today and what should be adopted next.
- When implementing features, prefer incremental adoption over a large one-shot rewrite.

## Local Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

## Next Recommended Steps

1. Align `pubspec.yaml` with the dependency strategy in [docs/03_DEPENDENCY_MANIFEST.md](docs/03_DEPENDENCY_MANIFEST.md).
2. Create the initial feature/core folder structure from [docs/02_PROJECT_STRUCTURE.md](docs/02_PROJECT_STRUCTURE.md).
3. Add CI workflow files in `.github/workflows/` using [docs/18_CI_CD_PIPELINE.md](docs/18_CI_CD_PIPELINE.md).
4. Add the environment/flavor strategy from [docs/23_ENVIRONMENTS_AND_FLAVORS.md](docs/23_ENVIRONMENTS_AND_FLAVORS.md) only as far as the app actually needs it.
5. Add performance and release checks from [docs/24_PERFORMANCE_AND_RELEASE_GATES.md](docs/24_PERFORMANCE_AND_RELEASE_GATES.md).
