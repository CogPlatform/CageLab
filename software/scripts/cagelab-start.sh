#!/usr/bin/env zsh
# a script to start all cage lab services gracefully

systemctl --user daemon-reload
sl=(toggleInput.service cogmoteGO.service theConductor.service mediamtx.service obs.service)
for s in $sl; do
	echo "Restarting $s"
	systemctl --user restart $s &
	sleep 0.1s
done

echo "All cage lab services restarting..."