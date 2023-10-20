FROM rust:1.73.0 as builder
WORKDIR /root
RUN git clone https://github.com/Wollwolke/dst-ping.git && \
    cargo install --locked --path dst-ping


FROM debian:latest

# Create DST user
RUN useradd -ms /bin/bash dst
WORKDIR /home/dst
COPY data/ /home/dst/data/

# Install dependencies
COPY --from=builder /usr/local/cargo/bin/dst-ping /usr/local/bin/
RUN set -x && \
    dpkg --add-architecture i386 && \
    apt-get update && apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y wget ca-certificates lib32gcc-s1 lib32stdc++6 libcurl4-gnutls-dev:i386 && \
    # Download Steam CMD (https://developer.valvesoftware.com/wiki/SteamCMD#Downloading_SteamCMD)
    wget -q -O - "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    chown -R dst:dst ./ && \
    # Cleanup
    apt-get autoremove --purge -y wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


RUN mkdir /data && \
    chown dst:dst /data
USER dst
RUN mkdir -p .klei/DoNotStarveTogether dst_server

# volume for DST server binary
VOLUME ["/home/dst/dst_server"]

# volume for config / saves
VOLUME ["/data"]

HEALTHCHECK \
    --timeout=10s \
    --start-period=5m \
    CMD /home/dst/data/healthcheck.sh

ENTRYPOINT ["/home/dst/data/entrypoint.sh"]
