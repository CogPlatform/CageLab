#!/usr/bin/env zsh
# a script to restart theConductor and cogmoteGO

systemctl --user stop cogmoteGO.service && systemctl --user stop theConductor.service
systemctl --user daemon-reload
sleep 0.5s
systemctl --user start cogmoteGO.service && systemctl --user start theConductor.service
echo "theConductor and cogmoteGO restarted."
echo "If you have a touch screen, we will try to disable it..."
DISPLAY=:0 toggleInput disable # disable touch screen in case it was enabled
