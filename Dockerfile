FROM debian:bullseye-slim as build_stage

# Define Arguments and Environment variables
ARG PUID=1000
ENV USER steam
ENV HOMEDIR "/home/${USER}"
ENV STEAMCMDDIR "${HOMEDIR}/steamcmd"

# Install steam, set up user, and perform other operations
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		lib32stdc++6=10.2.1-6 \
		lib32gcc-s1=10.2.1-6 \
		ca-certificates=20210119 \
		nano=5.4-2+deb11u2 \
		curl=7.74.0-1.3+deb11u7 \
		locales=2.31-13+deb11u5 \
		wine gettext-base xvfb x11-utils procps tini \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& useradd -u "${PUID}" -m "${USER}" \
	&& su "${USER}" -c \
		"mkdir -p \"${STEAMCMDDIR}\" \
		&& curl -fsSL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C \"${STEAMCMDDIR}\" \
		&& \"./${STEAMCMDDIR}/steamcmd.sh\" +quit \
		&& mkdir -p \"${HOMEDIR}/.steam/sdk32\" \
		&& ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${HOMEDIR}/.steam/sdk32/steamclient.so\" \
		&& ln -s \"${STEAMCMDDIR}/linux32/steamcmd\" \"${STEAMCMDDIR}/linux32/steam\" \
		&& ln -s \"${STEAMCMDDIR}/steamcmd.sh\" \"${STEAMCMDDIR}/steam.sh\"" \
	&& ln -s "${STEAMCMDDIR}/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so" \
	&& apt-get remove --purge --auto-remove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install wine32 -y \
	&& mkdir /saves && chown steam /saves \
	&& echo 'DISPLAY=:99' >> /etc/environment \
	&& winecfg

# Set the work directory
WORKDIR ${STEAMCMDDIR}

# Switch to steam user
USER ${USER}
RUN ./steamcmd.sh +@sSteamCmdForcePlatformType windows +login anonymous +app_update 1829350 validate +quit

# Define Environment variables
ENV DISPLAY=:99
ENV V_RISING_MAX_HEALTH_MOD=1.0
ENV V_RISING_MAX_HEALTH_GLOBAL_MOD=1.0
ENV V_RISING_RESOURCE_YIELD_MOD=1.0
ENV V_RISING_DAY_DURATION_SECONDS=1080.0
ENV V_RISING_DAY_START_HOUR=9
ENV V_RISING_DAY_END_HOUR=17
ENV V_RISING_TOMB_LIMIT=12
ENV V_RISING_NEST_LIMIT=4
ENV V_RISING_MAX_USER=40
ENV V_RISING_MAX_ADMIN=4
ENV V_RISING_DESC="Undertow"
ENV V_RISING_PASSW="stinkfist"
ENV V_RISING_CLAN_SIZE=4
ENV V_RISING_PORT=9876
ENV V_RISING_QUERY_PORT=9877
ENV V_RISING_SETTING_PRESET=""
ENV V_RISING_DEATH_CONTAINER_PERMISSIONS="Anyone"
ENV V_RISING_GAME_MODE="PvE"

# Copy required files and adjust permissions
COPY ./includes/*.json /templates
COPY ./includes/entrypoint.sh /
COPY ./includes/launch_server.sh /

USER root
RUN chown -R steam /saves \
	&& chmod +x /launch_server.sh \
	&& chmod +x /entrypoint.sh

# Set the entrypoint
USER steam
ENTRYPOINT [ "/entrypoint.sh" ]
