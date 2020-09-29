# Astro Pi Buster Installer

Installer for Astro Pi Buster SD card images used in the 2020-2021 competition.

## About

The scripts will install the same software that is available on the AstroPi units 
on the ISS. 

You can run this on Raspbian Desktop or Raspbian Lite images available from
[raspberrypi.org/downloads](https://www.raspberrypi.org/downloads/). 
If you want to develop in a Python IDE and have access to the web browser and other
graphical tools, you can use Raspbian Desktop. If you want to test your code
as close as possible to the environment on the ISS, start with Raspbian Lite.

Please note that the installer only supports **Raspbian Buster**. You can
download this from the [downloads page](https://www.raspberrypi.org/downloads/raspbian/)
on the Raspberry Pi website.

See [astro-pi.org](https://astro-pi.org/) and the
[Mission Space Lab guide](http://rpf.io/ap-msl-guide) for more information.

## What does the installer do?

- Installs apt packages
- Installs Python packages
- Sets the desktop background to a Mission Space Lab graphic (desktop only)
- Sets your Chromium homepage and bookmarks (desktop only)
- Sets MOTD (lite only)
- Introduces performance throttling (lite only)

## Retrieve the setup script

Make sure you're connected to the internet, and type this in the terminal:

```bash
export REPO="astro-pi-buster-installer"
export BRANCH="2020"
wget https://raw.githubusercontent.com/astro-pi/$REPO/$BRANCH/setup.sh
source setup.sh
```

This will retrieve the setup script and import the necessary functions.

## Clone the repository

Use the `setup` function to clone the repository. This will give you access to the 
rest of the scripts and files that are necessary.

```bash
setup
```

If you'd like to monitor the process more closely and have more fine-grained control over it, 
you can _instead_ invoke the functions that `setup` calls individually.

```bash
start
clone
```

## Install

Use the `install` function to complete setting up the system.

```bash
install
```

If you'd like to monitor the process more closely and have more fine-grained control over it, 
you can _instead_ invoke the functions that `install` calls individually.

```bash
update
apt_install
pip_install
enable_camera
lite_vs_desktop
```

The output of `install` contains a very brief summary of each step 
but the complete output generated is logged to the `/home/pi/setup.log` file. 
You can even monitor the log file "live", as it is generated, using
`tail -f setup.log` in a separate terminal.

### Testing the Python environment

The `tests` folder contains Python programs that import a range of installed modules
and test their functionality. You can run each of them individually or type `test` to 
run them all:

Also in the `tests` folder, you can find and test `astro-example.py`, which contains the code for 
the ["Worked example" presented in the Mission Space Lab Phase 2 guide](https://projects.raspberrypi.org/en/projects/code-for-your-astro-pi-mission-space-lab-experiment/10).

Make sure you have rebooted your system before you perform any of the tests.

### Creating images

If you are using the installer to generate OS images, run the `wrap` function 
as a last step before cloning/shrinking the image:

```bash
wrap
```

## Options

We have included a selection of desktop backgrounds including Astro Pi,
Raspberry Pi and ESA branding, as well as some photos of the Astro Pi in space
and even some of our favourite photos taken by Astro Pi 2018 competition
winners!

To choose a background, right click on the desktop and choose **Desktop
Preferences**. Under **Picture** click the selected file and try changing it
to one of the other options.

## Pi 1 / Pi 3 or 4

Note that you can transfer your SD card between Pi 1 and Pi 3/4 and it will
still work. Python libraries opencv and Tensorflow usually have optimisations
for the Pi 3/4 but this installer will install the Pi 1 version which works on
both models.

## Testing & feedback

Please test this installer and provide feedback. If you have any issues using
the installer, it doesn't work for you, something goes wrong or you have any
other issues, please let us know by [creating a GitHub
issue](https://github.com/astro-pi/astro-pi-buster-installer/issues).
