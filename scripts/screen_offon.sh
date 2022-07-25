#!/bin/sh

xset dpms force off
sleep 1
xset dpms force on

# as I'm connected to different displays at work and at home. autorandr allows automatic xrandr configurations for different display setup. To use autorandr,

#     Install with sudo apt install autorandr (tested on Ubuntu 18.04, Lubuntu 20.04)
#     Configure your monitor to your liking with xrandr
#     Store your configuration with autorandr --save work (I'm storing my work config, choose a name that suits you)
#     Resume the config with autorandr --change work to choose config, or just autorandr --change to have it infer your config from your connected monitors.


# run simply xrandr to get a list of all displays currently connected and their respective names (their connection). In possession of that information, you can run a simple command to 'reactivate' the secondary display and place it in the correct location. It would be something like
# internal = eDP-1-1
# DP-0 = Display Port
# HDMI-0 = HDMI
#xrandr --output SECONDARYDISPLAY --auto --right-of PRIMARYDISPLAY

# In your case, since you are using two external displays, you might also want to set the primary display with xrandr, in case running simply the first command doesn't work. You can then combine both with something like
#xrandr --output PRIMARYDISPLAY --auto --primary && xrandr --output SECONDARYDISPLAY
