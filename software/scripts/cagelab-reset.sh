#!/usr/bin/env zsh
# a script to restart theConductor and cogmoteGO

systemctl --user stop cogmoteGO.service && systemctl --user stop theConductor.service
systemctl --user daemon-reload
sleep 0.5s
systemctl --user start cogmoteGO.service && systemctl --user start theConductor.service
toggleInput disable # disable touch screen in case it was enabled
