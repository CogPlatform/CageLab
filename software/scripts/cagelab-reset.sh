#!/usr/bin/env zsh
# a script to restart theConductor and cogmoteGO

systemctl --user stop cogmoteGO.service
systemctl --user stop theConductor.service
sleep 1s
systemctl --user start cogmoteGO.service
systemctl --user start theConductor.service