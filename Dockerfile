FROM ubuntu:22.04

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>"

ENV VNC_SCREEN_SIZE=1024x768
ENV CHROME_OPTS_OVERRIDE="https://www.bbc.co.uk --user-data-dir=/config --no-sandbox --disable-features=InfiniteSessionRestore --no-default-browser-check --disable-fre --no-first-run --window-position=0,0 --force-device-scale-factor=1 --disable-dev-shm-usage"
ENV X11VNC_OPTS_OVERRIDE="-nopw -wait 0 -forever -xrandr -repeat"
ENV PWSH_SCRIPT="/scripts/test-file.ps1"

COPY copyables /

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
	&& DEBIAN_FRONTEND=noninteractive \
	apt-get install -y --no-install-recommends \
	gnupg2 \
	fonts-noto-cjk \
	pulseaudio \
	supervisor \
	x11vnc \
	fluxbox \
	eterm

ADD https://dl.google.com/linux/linux_signing_key.pub \
	https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
	https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb \
	/tmp/

RUN apt-key add /tmp/linux_signing_key.pub \
	&& dpkg -i /tmp/google-chrome-stable_current_amd64.deb \
	|| dpkg -i /tmp/chrome-remote-desktop_current_amd64.deb \
	|| DEBIAN_FRONTEND=noninteractive apt-get -f --yes install

RUN apt-get clean \
	&& rm -rf /var/cache/* /var/log/apt/* /var/lib/apt/lists/* /tmp/* \
	&& useradd -m -G chrome-remote-desktop,pulse-access chrome \
	&& usermod -s /bin/bash chrome \
	&& ln -s /crdonly /usr/local/sbin/crdonly \
	&& ln -s /update /usr/local/sbin/update \
	&& mkdir -p /home/chrome/.config/chrome-remote-desktop \
	&& mkdir -p /home/chrome/.fluxbox \
	&& mkdir -p /config \
	&& mkdir -p /config/Default \
	&& mkdir -p /home/chrome/Downloads \	
	&& echo ' \n\
		session.screen0.toolbar.visible:        false\n\
		session.screen0.fullMaximization:       true\n\
		session.screen0.maxDisableResize:       true\n\
		session.screen0.maxDisableMove: true\n\
		session.screen0.defaultDeco:    NONE\n\
	' >> /home/chrome/.fluxbox/init \
	&& chown -R chrome:chrome /home/chrome/.config /home/chrome/.fluxbox /config /config/Default /home/chrome/Downloads

RUN apt-get update \
	&& apt-get install -y wget apt-transport-https software-properties-common \
	&& wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb \
	&& dpkg -i packages-microsoft-prod.deb \
	&& add-apt-repository universe \
	&& apt-get install -y powershell

VOLUME /config/Default
VOLUME /home/chrome/Downloads
VOLUME /scripts

USER chrome

WORKDIR /tmp

EXPOSE 5900

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
