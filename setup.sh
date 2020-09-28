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

function clone () {

    if [ -z $1 ]; then
        log "You need to specify a branch to clone, e.g.: clone 2020"
        exit 1
    fi

    # Check if git was already installed
    git=`dpkg -l | grep "ii  git" | wc -l`
    if [ $git -gt 0 ]; then
        git_installed=true
    else
        git_installed=false
        log "Installing git"
    	sudo apt-get update >> $logfile
        sudo apt-get install git -y >> $logfile
    fi

    # Clone the repo
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

clone
