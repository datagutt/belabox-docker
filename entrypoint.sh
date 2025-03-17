#!/bin/sh
HW=$1
xhost +
cd /opt/belaUI
sed -i "s/hw\": \"n100\"/hw\": \"$HW\"/g" /opt/bela/belaconfig.json
nodejs ./belaUI.js
