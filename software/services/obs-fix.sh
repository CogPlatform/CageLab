#!/usr/bin/env bash
# a script to restart obs and mediamtx to fix streaming issues
# should be run as a systemd user service every hour or so
# e.g. in ~/.config/systemd/user/obs-fix.service

systemctl --user stop mediamtx && systemctl --user stop obs
sleep 1
systemctl --user start mediamtx && systemctl --user start obs