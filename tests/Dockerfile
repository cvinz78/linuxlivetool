FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash \
        busybox \
        coreutils \
        diffutils \
        findutils \
        gawk \
        grep \
        sed \
        util-linux \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
