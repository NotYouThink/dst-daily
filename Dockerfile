FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Steam needs 32-bit libs, plus a virtual display and software OpenGL
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common ca-certificates \
 && add-apt-repository -y multiverse \
 && apt-get update \
 && echo steam steam/question select "I AGREE" | debconf-set-selections \
 && echo steam steam/license note '' | debconf-set-selections \
 && apt-get install -y --no-install-recommends \
      steam-installer \
      xvfb x11vnc openbox scrot procps tzdata tini \
      python3 curl locales zenity \
      libgl1-mesa-dri libgl1-mesa-dri:i386 libgl1:i386 libglx-mesa0 libglx-mesa0:i386 \
      libnss3 libc6:i386 \
 && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/games:${PATH}" \
    LIBGL_ALWAYS_SOFTWARE=1 \
    SDL_AUDIODRIVER=dummy \
    STEAM_EXTRA_ARGS="-no-cef-sandbox" \
    POPUP_WAIT=60 \
    RUN_AT=09:00 \
    RUN_ON_START=false

RUN useradd -m -u 1001 -s /bin/bash steam
WORKDIR /app
COPY dontstarve_daily.py entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

USER steam
ENV HOME=/home/steam
VOLUME /home/steam

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
CMD ["cron"]
