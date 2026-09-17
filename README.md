# dockerhub-mirror-test

Dry run for software-mansion/pathfinder#3555 — migrating the Pathfinder Docker
images from `eqlabs/pathfinder` to `swmansion/pathfinder` with a transitional
mirror, so releases keep landing in both namespaces during the migration window.

`.github/workflows/docker.yml` here is a structural copy of the real workflow,
against a throwaway alpine image, so the mechanics can be verified without
touching a real release.

## Setup

Two Docker Hub accounts are needed, since the real case involves two separate
accounts (`swmansion` and `eqlabs`). Personal accounts are free; organizations
are not, and are not needed here.

Namespace A is `franciszekjob`, namespace B is `fjobswm`; both push to a
`mirror-test` repo, created automatically on first push (public by default for
personal accounts).

Add four repository secrets:

| Secret | Value |
| --- | --- |
| `DOCKER_HUB_USERNAME` | `franciszekjob` |
| `DOCKER_HUB_ACCESS_TOKEN` | token for `franciszekjob`, write scope |
| `LEGACY_DOCKER_HUB_USERNAME` | `fjobswm` |
| `LEGACY_DOCKER_HUB_ACCESS_TOKEN` | token for `fjobswm`, write scope |

## Running

- **Snapshot only:** run the workflow with `fake_release_tag` empty. Expect
  `snapshot-<sha>` in both namespaces.
- **Simulated release:** run it with `fake_release_tag` set to e.g. `v1.2.3`.
  Expect `snapshot-<sha>`, `v1.2.3` and `latest` in both namespaces.

The final step fails the run if the digests in A and B differ.

## What it proves

- Two logins to `docker.io` in one job do not collide, as long as the copy
  happens after the push (only one account can be logged in at a time).
- `imagetools create` preserves the multi-arch manifest list and the digest.
- Reading from the public A repo works while authenticated as B.
