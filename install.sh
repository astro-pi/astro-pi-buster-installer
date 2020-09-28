#!/bin/bash

source /home/pi/$REPO/defs.sh

update
apt_install
pip_install
enable_camera
lite_vs_desktop

export -f wrap
