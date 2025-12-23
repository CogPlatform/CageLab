#!/usr/bin/env zsh
# a script to stop all cage lab services gracefully

sl=(theConductor.service cogmoteGO.service obs.service mediamtx.service)
for s in $sl; do
	echo "Stopping $s"
	systemctl --user stop $s
done

echo "All cage lab services stopped."
