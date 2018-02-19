FROM centos:7
LABEL maintainer="echizenryoma.zhang@gmail.com"

# Runtime settings
ENV PORT=27015
ENV MAX_PLAYERS=32
ENV MAP=fy_iceworld

# Install steamcmd
RUN yum makecache \
  && yum install -y glibc.i686 libstdc++.i686 unzip
RUN mkdir -p /opt/steam/ \
    && curl -SL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xzC /opt/steam/
RUN /opt/steam/steamcmd.sh +login anonymous +quit

# Install hlds cstrike
RUN /opt/steam/steamcmd.sh +login anonymous +force_install_dir /opt/hlds +app_update 90 validate +quit \
  && /opt/steam/steamcmd.sh +login anonymous +force_install_dir /opt/hlds +app_update 70 validate +quit || : \
  && /opt/steam/steamcmd.sh +login anonymous +force_install_dir /opt/hlds +app_update 10 validate +quit || : \
  && /opt/steam/steamcmd.sh +login anonymous +force_install_dir /opt/hlds +app_update 90 validate +quit

# Install cstrike server patch
# metamod-p
RUN mkdir -p /opt/hlds/cstrike/addons/metamod/dlls \
    && curl -SL https://sourceforge.net/projects/metamod-p/files/Metamod-P%20Binaries/1.21p37/metamod-p-1.21p37-linux_i686.tar.gz | tar -xzC /opt/hlds/cstrike/addons/metamod/dlls
RUN sed -i 's/^gamedll_linux\s\+.*$/gamedll_linux \"addons\/metamod\/dlls\/metamod.so\"/' /opt/hlds/cstrike/liblist.gam
# amxmodx
RUN mkdir -p /opt/hlds/cstrike/ \
    && curl -SL https://www.amxmodx.org/release/amxmodx-1.8.2-base-linux.tar.gz | tar -xzC /opt/hlds/cstrike/
RUN mkdir -p /opt/hlds/cstrike/ \
    && curl -SL https://www.amxmodx.org/release/amxmodx-1.8.2-cstrike-linux.tar.gz | tar -xzC /opt/hlds/cstrike/
# dproto
RUN curl -L http://non-steam.ru/wp-content/files/dproto_0_9_548.zip -o dproto.zip \
    && unzip dproto.zip -d dproto/ \
    && rm dproto.zip \
    && mkdir -p /opt/hlds/cstrike/addons/dproto/ \
    && cp -f dproto/bin/Linux/dproto_i386.so /opt/hlds/cstrike/addons/dproto/ \
    && cp -f dproto/dproto.cfg /opt/hlds/cstrike/ \
    && rm -rf dproto
RUN chmod -R +x /opt/hlds/cstrike/addons/

COPY files/cstrike/custom.hpk /opt/hlds/cstrike/
COPY files/cstrike/maps/* /opt/hlds/cstrike/maps/
RUN echo "fy_iceworld" > /opt/hlds/cstrike/mapcycle.txt \
  && touch /opt/hlds/cstrike/listip.cfg \
  && touch /opt/hlds/cstrike/banned.cfg \
  && echo -e "linux addons/amxmodx/dlls/amxmodx_mm_i386.so\nlinux addons/dproto/dproto_i386.so\n" > /opt/hlds/cstrike/addons/metamod/plugins.ini

ENV HOME /root

RUN mkdir -p ${HOME}/.steam/sdk32/ \
  && ln -s /opt/hlds/steamclient.so ${HOME}/.steam/sdk32/steamclient.so

# Set our workdir
WORKDIR /opt/hlds/

# Expose port
EXPOSE ${PORT}/udp

# Default run command
CMD ./hlds_run -insecure -console -game cstrike -port ${PORT} +maxplayers ${MAX_PLAYERS} +map ${MAP} +mp_logecho 1
