#!/bin/bash

bold='\033[1m'
norm='\033[39m\033[0m'
colr='\033[92m'
logfile='/home/pi/setup.log'

export REPO="astro-pi-buster-installer"
export BRANCH="2020"

function log () {
    echo -e "${colr}`date '+%H:%M:%S'` ${bold}$1${norm}" | tee -a $logfile 
}

function is_desktop () {
    if [ `dpkg -l | grep chromium | wc -l` -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

function start () {
    # Check we're on Raspbian Buster (Debian 10)
    source /etc/os-release
    if [ ! $VERSION_ID -eq 10 ]; then
        echo "You seem to be using {$PRETTY_NAME}. This installer is for Raspbian Buster."
        exit 1
    fi

    if is_desktop; then
        log "You are running Raspbian Buster (Desktop version)."
    else
        log "You are running Raspbian Buster (Lite version)."
    fi

    if [ -z $REPO ]; then
        echo "You need to set the REPO environment variable."
        exit 1
    fi

    if [ -z $BRANCH ]; then
        log "You need to set the BRANCH variable."
        exit 1
    fi
    log "Starting Astro Pi setup for $REPO/$BRANCH..."
}

function clone () {
    # Check if git was already installed
    git=`dpkg -l | grep "ii  git " | wc -l`
    if [ $git -eq 0 ]; then
        log "Installing git"
        sudo apt-get update >> $logfile
        sudo apt-get install git -y >> $logfile
        touch /home/pi/.git-installed
    fi

    # Clone the repo
    log "Cloning installation repository"
    rm -rf $REPO || true # delete if it's already there
    git clone --progress --single-branch -b $BRANCH https://github.com/astro-pi/$REPO &>> $logfile
}

function update () {
    log "Updating apt packages"
    sudo apt-get update >> $logfile

    # Install apt packages
    log "Running dist-upgrade"
    sudo apt-get -y dist-upgrade >> $logfile
}

function digikam_fix () {
#    cat >> /home/pi/.bashrc << EOF
#export QT_QPA_PLATFORMTHEME=gtk3
#export QT_STYLE_OVERRIDE=gtk3
#EOF
    sed -i -e 's/^style=.*/style=gtk3/' /home/pi/.config/qt5ct/qt5ct.conf
}

function apt_install () {
    if is_desktop; then
    log "Installing new apt packages for Desktop version..."
        sudo apt-get install `cat $REPO/packages.txt $REPO/packages.desktop.txt` --no-install-recommends -y >> $logfile
        if ! grep -q digikam $REPO/packages.txt; then digikam_fix; fi
    else
        log "Installing new apt packages for Lite version..."
        sudo apt-get install `cat $REPO/packages.txt` --no-install-recommends -y >> $logfile
    fi
}

function pip_install() {
    armv6_packages=(
        opencv-contrib-python-headless
        grpcio
        tensorflow
    )

    # Download Armv6 versions of opencv/tensorflow/grpcio wheel files
    for package in "${armv6_packages[@]}"; do
        if [ `ls $REPO/wheels | grep $package | wc -l` -eq 0 ]; then
          log "Downloading armv6l version of $package..."
          pip3 download `cat $REPO/requirements.txt | grep $package==` --only-binary=:all: --no-deps --dest $REPO/wheels --platform linux_armv6l >> $logfile
        fi
    done

    # duplicate armv6 wheels to pass for armv7
    for file in $REPO/wheels/*armv6l.whl; do cp $file `echo $file | sed 's/armv6l/armv7l/'` ; done

    # Install Python packages from PyPI/piwheels - versions specified in requirements.txt
    log "Installing Python packages..."
    sudo pip3 install --requirement $REPO/requirements.txt --only-binary=:all: --find-links $REPO/wheels >> $logfile
}

function enable_camera () {
    # Enable the camera
    log "Enabling the camera interface"
    sudo raspi-config nonint do_camera 0
}

function lite_vs_desktop () {

    if is_desktop; then
        echo 'XDG_DATA_DIR="$HOME/Data"' >> .config/user-dirs.dirs

        # Set Chromium homepage and bookmarks
        log "Setting your Chromium homepage and bookmarks..."
        sudo python3 $REPO/chromium.py

        log "Installing desktop backgrounds"
        sudo cp $REPO/desktop-backgrounds/* /usr/share/rpd-wallpaper/
        # Set the desktop background to MSL
        global_config_dir="/etc/xdg/pcmanfm/LXDE-pi"
        local_config_dir="/home/pi/.config/pcmanfm"
        local_config="/home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf"
        if [ ! -e $local_config ]; then
            mkdir -p $local_config_dir
            cp -r $global_config_dir $local_config_dir
        fi
        sed -i -e 's|wallpaper=.*|wallpaper=/usr/share/rpd-wallpaper/mission_space_lab.sunglint.png|g' $local_config

        log "Installing Mu editor..."
        sudo apt-get install mu-editor -y >> $logfile
    else
        log "Setting MOTD"
        sudo cp $REPO/files/motd /etc/motd
        log "Implementing performance throttling"
        sudo cp $REPO/files/astropiconfig.txt /boot/
        echo "include astropiconfig.txt" | sudo tee --append /boot/config.txt > /dev/null
        if ! grep -q 'maxcpus=1' /boot/cmdline.txt; then
            sudo sed -i -e 's/$/ maxcpus=1/g' /boot/cmdline.txt
        fi
    fi
}

function set_resize () {
    if is_desktop; then
        log "Reinstating the piwiz for next boot"
        sudo mv /home/pi/piwiz.desktop /etc/xdg/autostart/
    fi
    if ! grep -q 'init_resize.sh' /boot/cmdline.txt; then
        log "Preparing to resize filesystem on next boot"
        sudo sed -i 's|$| init=/usr/lib/raspi-config/init_resize.sh|' /boot/cmdline.txt
        sudo mv /home/pi/resize2fs_once /etc/init.d/
        sudo chmod +x /etc/init.d/resize2fs_once
        sudo systemctl enable resize2fs_once
    fi
    sudo rm -f /home/pi/.bash_history /home/pi/.python_history /home/pi/.wget-hsts /home/pi/setup.log /home/pi/setup.sh
}

function wrap () {
    log "Removing WiFi configuration"
    head -2 /etc/wpa_supplicant/wpa_supplicant.conf | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
    log "Disabling ssh"
    sudo systemctl disable ssh &>> $logfile
    log "Deleting repository contents"
    cp $REPO/files/resize2fs_once /home/pi/
    if is_desktop; then
        cp $REPO/files/piwiz.desktop /home/pi/
    fi
    rm -rf $REPO
    # Remove git if it wasn't installed before
    if [ -f /home/pi/.git-installed ]; then
        log "Removing git"
        sudo apt-get -y purge git >> $logfile
        rm /home/pi/.git-installed
    fi
    log "Autoremoving packages"
    sudo apt-get -y autoremove >> $logfile
    log "Deleting .deb cache"
    sudo rm -rf /var/cache/apt/archives/
    log "Deleting pip cache"
    sudo rm -rf .cache
    log "Deleting history and other misc items"
    sudo rm -f /home/pi/.bash_history /home/pi/.python_history /home/pi/.wget-hsts /home/pi/setup.log
}

function setup () {
    start
    clone
}

function install () {
    update
    apt_install
    pip_install
    enable_camera
    lite_vs_desktop
}

function test() {
    for test in $REPO/tests/test-*.py; do python3 $test; done
}
