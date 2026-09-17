# Stand-in for the real pathfinder image: builds in seconds, still produces a
# genuine multi-arch manifest list, which is what the mirroring step operates on.
FROM alpine:3.20

ARG FAKE_VERSION=dev
ENV FAKE_VERSION=${FAKE_VERSION}

RUN echo "$FAKE_VERSION" > /version.txt

ENTRYPOINT ["/bin/sh", "-c", "echo \"mirror-test $(cat /version.txt) on $(uname -m)\""]
