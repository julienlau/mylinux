#!/bin/bash
#
# Switching on or off your headphone speaker and mic jacks
# and at the same time switching off or on your laptop front speakers.
# requires hda-verb-0.3-6-mdv2011.0.x86_64
#
# Before putting it in place make sure to test your PIN_WIDGET_CONTROL's
# with su -c 'python2 hda-analyzer.py' available here :
# http://www.alsa-project.org/hda-analyzer.py
#

if [[ $# -eq 1 ]]; then
    mode=$1
else
    mode=1
fi

PIN_CONFIGS=/sys/class/sound/hwC0D0/init_pin_configs
if [ ! -f $PIN_CONFIGS ]; then
    echo "Your kernel is missing CONFIG_SND_HDA_HWDEP=y"
    exit 0
fi
if [  -z $(which hda-verb 2>/dev/null) ]; then
    echo "This script requires hda-verb-0.3-6-mdv2011.0.x86_64"
    exit 0
fi
PINS_PRESENT=`cat $PIN_CONFIGS | awk '{print $1}'`
if [[ ${mode} -eq 1 ]]; then
# Headset (Mic (Node 0x1b) + Headphone Drive (Node 0x19)) : ON
# Laptop Speaker (Node 0x1f) : OFF
[ `echo "$PINS_PRESENT" | grep 0x19` ] &&
   hda-verb /dev/snd/hwC0D0 0x19 SET_PIN_WIDGET_CONTROL 0x40
[ `echo "$PINS_PRESENT" | grep 0x1f` ] &&
   hda-verb /dev/snd/hwC0D0 0x1f SET_PIN_WIDGET_CONTROL 0
[ `echo "$PINS_PRESENT" | grep 0x1b` ] &&
   hda-verb /dev/snd/hwC0D0 0x1b SET_PIN_WIDGET_CONTROL 0x64
fi

if [[ ${mode} -eq 0 ]]; then
# Headset (Mic (Node 0x1b) + Headphone Drive (Node 0x19)) : OFF
# Laptop Speaker (Node 0x1f) : ON
[ `echo "$PINS_PRESENT" | grep 0x19` ] &&
   hda-verb /dev/snd/hwC0D0 0x19 SET_PIN_WIDGET_CONTROL 0
[ `echo "$PINS_PRESENT" | grep 0x1f` ] &&
   hda-verb /dev/snd/hwC0D0 0x1f SET_PIN_WIDGET_CONTROL 0x40
[ `echo "$PINS_PRESENT" | grep 0x1b` ] &&
   hda-verb /dev/snd/hwC0D0 0x1b SET_PIN_WIDGET_CONTROL 0x24
fi
