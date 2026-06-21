FROM rust:1 AS build

WORKDIR /app

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get -y install --no-install-recommends ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/*

COPY . .

RUN CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build --release && \
    mkdir -p /app/microbin_data

# Use debian-slim as the base image for runtime to include standard libraries (libbz2, liblzma, etc.)
FROM debian:bookworm-slim

WORKDIR /app

# copy time zone info from build stage
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

# copy CA certificates from build stage
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# copy built executable
COPY --from=build /app/target/release/microbin /usr/bin/microbin

# copy data directory skeleton with nonroot ownership
COPY --from=build --chown=65532:65532 /app/microbin_data /app/microbin_data

USER 65532:65532

VOLUME ["/app/microbin_data"]

# Expose webport used for the webserver to the docker runtime
EXPOSE 8080

ENTRYPOINT ["/usr/bin/microbin"]
