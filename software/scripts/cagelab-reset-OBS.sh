#!/usr/bin/env zsh
# a script to restart obs and mediamtx to fix streaming issues

systemctl --user stop obs && systemctl --user stop mediamtx
systemctl --user daemon-reload
sleep 0.25s
systemctl --user start mediamtx && systemctl --user start obs &
