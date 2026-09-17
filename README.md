# dockerhub-mirror-test

Dry run for software-mansion/pathfinder#3555 — migrating the Pathfinder Docker
images from `eqlabs/pathfinder` to `swmansion/pathfinder` with a transitional
mirror, so releases keep landing in both namespaces during the migration window.

`.github/workflows/docker.yml` is a near-verbatim copy of the real workflow: same
triggers, same three jobs, same `if` conditions, same step order and logins. The
header of that file lists every deviation.

| real | here |
| --- | --- |
| `swmansion/pathfinder` (new home) | `franciszekjob/mirror-test` |
| `eqlabs/pathfinder` (legacy) | `fjobswm/mirror-test` |
| `EQLABS_DOCKER_HUB_*` secrets | `LEGACY_DOCKER_HUB_*` |

## Setup

Both repos are created automatically on first push (public by default for
personal accounts). Add four repository secrets:

| Secret | Value |
| --- | --- |
| `DOCKER_HUB_USERNAME` | `franciszekjob` |
| `DOCKER_HUB_ACCESS_TOKEN` | token for `franciszekjob`, write scope |
| `LEGACY_DOCKER_HUB_USERNAME` | `fjobswm` |
| `LEGACY_DOCKER_HUB_ACCESS_TOKEN` | token for `fjobswm`, write scope |

## Running the full flow

The point is to walk the same two-step path a real release takes:

1. **Push a version tag** — `git tag v0.0.1 && git push origin v0.0.1`.
   `build-image` runs (`github.event_name != 'release'`), pushes
   `snapshot-<sha>` to `franciszekjob/mirror-test` and mirrors it to
   `fjobswm/mirror-test`.
2. **Publish a GitHub release for that tag.** `tag-release` runs on a *fresh*
   runner, so it logs in from scratch: it tags the snapshot as `v0.0.1` and
   `latest` in `franciszekjob/mirror-test`, then re-logs in as `fjobswm` and
   mirrors both tags. `update-infra` runs afterwards as a no-op echo.

Mark the release as a prerelease to check that `latest` is left alone.
`workflow_dispatch` also works for a snapshot-only run.

## Verifying

```bash
crane digest franciszekjob/mirror-test:v0.0.1
crane digest fjobswm/mirror-test:v0.0.1        # must be identical

docker run --rm --platform linux/arm64 fjobswm/mirror-test:v0.0.1
```

## What it proves

- Two logins to `docker.io` in one job do not collide, as long as the copy
  happens after the push — only one account can be logged in at a time, which is
  why the mirror copies an already-pushed image instead of pushing twice.
- `imagetools create` preserves the multi-arch manifest list and the digest.
- Reading from the public namespace A works while authenticated as B.
- The `tag-release` job works on a clean runner, where nothing is logged in yet.
