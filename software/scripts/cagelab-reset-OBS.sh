#!/usr/bin/env zsh
# a script to restart obs and mediamtx to fix streaming issues

systemctl --user stop mediamtx && systemctl --user stop obs
sleep 1
systemctl --user start mediamtx && systemctl --user start obs
