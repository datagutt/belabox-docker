# Use Ubuntu 24.04 LTS as the base image
FROM ubuntu:24.04

# Update and install necessary packages
RUN apt-get update && apt-get dist-upgrade -y && \
	apt-get install -y cmake network-manager ifupdown net-tools wget isc-dhcp-client resolvconf nano build-essential git tcl libgl1 libglx-mesa0 nodejs npm usb-modeswitch libgstreamer1.0-dev libgl1-mesa-dri libgstreamer-plugins-base1.0-dev && \
	apt-get install -y libssl-dev libasound2 libgtk-3-0 libxtst6 libpulse0 avahi-utils alsa-base alsa-utils pulseaudio-utils && \
	rm -rf /var/lib/apt/lists/*

# Add Google DNS servers
RUN mkdir -p /etc/resolvconf/resolv.conf.d
RUN printf "\nnameserver 8.8.8.8\nnameserver 8.8.4.4\n" | tee -a /etc/resolvconf/resolv.conf.d/head

# Set up source routing for wired modems
RUN mkdir -p /etc/dhcp/dhclient-exit-hooks.d
RUN wget https://raw.githubusercontent.com/mikeful/belabox-tutorial/master/dhclient-source-routing -O /etc/dhcp/dhclient-exit-hooks.d/dhclient-source-routing && \
	wget https://raw.githubusercontent.com/mikeful/belabox-tutorial/master/interfaces -O /etc/network/interfaces && \
	printf "100 usb0\n101 usb1\n102 usb2\n103 usb3\n104 usb4\n" | tee -a /etc/iproute2/rt_tables && \
	printf "110 eth0\n111 eth1\n112 eth2\n113 eth3\n114 eth4\n" | tee -a /etc/iproute2/rt_tables

# Set up source routing for WiFi with NetworkManager
RUN mkdir -p /etc/NetworkManager/dispatcher.d
RUN wget https://raw.githubusercontent.com/mikeful/belabox-tutorial/master/nm-source-routing -O /etc/NetworkManager/dispatcher.d/nm-source-routing && \
	chmod 755 /etc/NetworkManager/dispatcher.d/nm-source-routing && \
	printf "120 wlan0\n121 wlan1\n122 wlan2\n123 wlan3\n124 wlan4\n" | tee -a /etc/iproute2/rt_tables

# Use old network interface names
# /lib/systemd/network/99-default.link
RUN ln -s /dev/null /etc/systemd/network/99-default.link

WORKDIR /opt
# Clone and install SRT
RUN git clone https://github.com/BELABOX/srt.git && \
	cd srt && \
	./configure --prefix=/usr/local && \
	make -j4 && \
	make install && \
	ldconfig

# Clone and build belacoder
RUN git clone https://github.com/mikeful/belacoder-n100.git belacoder && \
	cd belacoder && \
	mkdir -p pipelines/custom && \
	make

# Clone and build srtla
RUN git clone https://github.com/BELABOX/srtla.git && \
	cd srtla && \
	make

# Clone and set up belaUI
RUN git clone https://github.com/BELABOX/belaUI.git && \
	cd belaUI && \
	git checkout ws_nodejs && \
	# Replace bcrypt ^3.0.8 with ^5.0.1"
	sed -i 's/"bcrypt": "^3.0.8"/"bcrypt": "^5.0.1"/' package.json && \
	npm install && \
	./install_service.sh

# Expose the application port
EXPOSE 80

# Start the belaUI web interface
COPY entrypoint.sh /opt/belaUI/entrypoint.sh
COPY setup.json /opt/belaUI/setup.json
RUN chmod +x /opt/belaUI/entrypoint.sh
ENTRYPOINT ["/opt/belaUI/entrypoint.sh"]