#!/usr/bin/env zsh
# a script to stop all cage lab services gracefully

sl=(cogmoteGO.service theConductor.service mediamtx.service obs.service obs-fix.service toggleInput.service)
for s in $sl; do
	echo "Restarting $s"
	systemctl --user restart $s
done

