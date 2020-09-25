#!/bin/bash

bold='\033[1m'
norm='\e[39m\033[0m'
colr='\033[92m'
logfile='/home/pi/setup.log'

function log () {
    echo -e "${colr}`date '+%H:%M:%S'` ${bold}$1${norm}" | tee -a $logfile 
}

function start () {
    # Check we're on Raspbian Buster (Debian 10)
    source /etc/os-release
    if [ $VERSION_ID -eq 10 ]; then
        log "You are running Raspbian Buster. Starting Astro Pi setup..."
    else
        echo "You seem to be using {$PRETTY_NAME}. This installer is for Raspbian Buster. Please download Raspbian Buster from the Raspberry Pi website http://rpf.io/raspbian"
        exit 1
    fi
}

function enable_camera () {
    # Enable the camera
    log "Enabling the camera interface"
    sudo raspi-config nonint do_camera 0
}

function update () {
    log "Updating apt packages"
    sudo apt-get update >> $logfile
  
    # Install apt packages
    log "Running dist-upgrade"
    sudo apt-get -y dist-upgrade >> $logfile
}

function clone_repository () {
    if [ -z $1 ]; then
        log "You need to specify a branch to clone, e.g.: clone_repository 2020"
        exit 1
    fi

    # Check if git was already installed
    git=`dpkg -l | grep "ii  git" | wc -l`
    if [ $git -gt 0 ]; then
        git_installed=true
    else
        git_installed=false
        log "Installing git"
        sudo apt-get install git -y >> $logfile
    fi

    # Clone this repo to have access to test files and desktop backgrounds
    log "Cloning installation repository"
    rm -rf astro-pi-buster-installer || true # delete if it's already there
    git clone --progress --single-branch -b $1 https://github.com/astro-pi/astro-pi-buster-installer &>> $logfile

    # Remove git if it wasn't installed before
    if ! $git_installed; then
        log "Removing git"
        sudo apt-get -y purge git >> $logfile
        sudo apt-get -y autoremove >> $logfile
    fi
}

function apt_install () {
    log "Installing new apt packages..."
    sudo apt-get install `cat astro-pi-buster-installer/packages.txt` -y >> $logfile
}

function pip_install() {
    armv6_packages=(
        opencv-contrib-python-headless
        grpcio
        tensorflow
    )
    
    # Download Armv6 versions of opencv/tensorflow/grpcio wheel files
    for package in "${armv6_packages[@]}"; do
        log "Downloading armv6l version of $package..."
        pip3 download `cat astro-pi-buster-installer/requirements.txt | grep $package==` --only-binary=:all: --no-deps --dest astro-pi-buster-installer/wheels --platform linux_armv6l >> $logfile
    done

    # rename armv6 wheels to pass for armv7
    for file in `ls astro-pi-buster-installer/wheels/*armv6l.whl`; do mv $file `echo $file | sed 's/armv6l/armv7l/'` ; done

    # Install Python packages from PyPI/piwheels - versions specified in requirements.txt
    log "Installing Python packages..."
    sudo pip3 install --requirement astro-pi-buster-installer/requirements.txt --only-binary=:all: --find-links astro-pi-buster-installer/wheels >> $logfile
}

# Test Python imports
#t=`date '+%H:%M:%S'`
#echo "$t Testing importing your Python packages..."
#if python3 -W ignore test.py; then
#    t=`date '+%H:%M:%S'`
#    echo "$t All Python libraries imported ok"
#else
#    t=`date '+%H:%M:%S'`
#    echo "$t There were errors with the Python libraries. See above for more information."
#fi

function lite_vs_desktop () {
    # Check we're on desktop or lite
    chromium=`dpkg -l | grep chromium | wc -l`
    if [ $chromium -gt 0 ]; then
        desktop=true
        log "It looks like you are running Raspbian Desktop"
    else
        desktop=false
        log "It looks like you are running Raspbian Lite"
    fi

    if $desktop; then
        # Set Chromium homepage and bookmarks
        log "Setting your Chromium homepage and bookmarks..."
        sudo python3 astro-pi-buster-installer/chromium.py

        log "Installing desktop backgrounds"
        sudo cp astro-pi-buster-installer/desktop-backgrounds/* /usr/share/rpd-wallpaper/
        # Set the desktop background to MSL
        global_config_dir="/etc/xdg/pcmanfm/LXDE-pi"
        local_config_dir="/home/pi/.config/pcmanfm"
        local_config="/home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf"
        if [ ! -e $local_config ]; then
            mkdir -p $local_config_dir
            cp -r $global_config_dir $local_config_dir
        fi
        sed -i -e 's/temple.jpg/mission-space-lab.earth.jpg/g' $local_config
        
        log "Installing Mu editor..."
        sudo apt-get install mu-editor -y >> $logfile
    else
        log "Setting MOTD"
        sudo /bin/sh motd.sh /etc/motd
        log "Implementing performance throttling"
        sudo cp astro-pi-buster-installer/astropiconfig.txt /boot/
        echo "include astropiconfig.txt" | sudo tee --append /boot/config.txt > /dev/null
        if ! grep -q 'maxcpus=1' /boot/cmdline.txt; then
            sudo sed -i -e 's/rootwait/rootwait maxcpus=1/g' /boot/cmdline.txt
        fi
    fi
}

function wrap () {
  if $desktop; then
      log "Re-instating the piwiz for next boot"
      sudo cp astro-pi-buster-installer/piwiz.desktop /etc/xdg/autostart/
  fi
  log "Re-instating init_resize.sh for next boot"
  sudo sed -i 's|quiet|quiet init=/usr/lib/raspi-config/init_resize.sh|' /boot/cmdline.txt
  log "Removing WiFi configuration"
  head -2 /etc/wpa_supplicant/wpa_supplicant.conf | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
  log "Disabling ssh"
  sudo systemctl disable ssh &>> $logfile
  log "Removing repository"
  rm -rf astro-pi-buster-installer
  log "Deleting .deb cache"
  sudo rm -rf /var/cache/apt/archives/
  log "Deleting pip cache"
  sudo rm -rf .cache
  log "Deleting other misc items"
  sudo rm -f .bash_history .wget_hsts
  log "Astro Pi Installation complete! Run 'sudo reboot' to restart."
}
