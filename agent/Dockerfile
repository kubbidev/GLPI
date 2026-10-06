# GLPI Agent - inventories the Docker host and reports to GLPI's native inventory
FROM debian:trixie-slim

ARG GLPI_AGENT_VERSION=1.20

# Official package + the system tools the agent relies on for hardware inventory
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
      dmidecode pciutils usbutils usb.ids hdparm lshw iproute2 net-tools procps \
 && curl -fsSL -o /tmp/glpi-agent.deb \
      "https://github.com/glpi-project/glpi-agent/releases/download/${GLPI_AGENT_VERSION}/glpi-agent_${GLPI_AGENT_VERSION}-1_all.deb" \
 && apt-get install -y --no-install-recommends /tmp/glpi-agent.deb \
 && ln -sf /usr/share/misc/usb.ids /usr/share/glpi-agent/usb.ids \
 && rm -rf /tmp/glpi-agent.deb /var/lib/apt/lists/*

COPY glpi-agent.cfg /etc/glpi-agent/conf.d/00-docker.cfg

ENV GLPI_AGENT_VERSION=${GLPI_AGENT_VERSION}
VOLUME ["/var/lib/glpi-agent"]
EXPOSE 62354

# Foreground daemon: inventories at startup, then on the server-defined schedule
ENTRYPOINT ["sh", "-c", "exec glpi-agent --daemon --no-fork --server=\"$GLPI_SERVER\" ${GLPI_TAG:+--tag=\"$GLPI_TAG\"} \"$@\"", "--"]
