#!/usr/bin/env zsh
# a script to reset all cage lab services to their default states
# should be run after any changes to the services or their configurations

cd "$HOME/.config/systemd/user" || return
systemctl --user disable cogmoteGO.service
rm -f cogmoteGO.service
cogmoteGO service -u
sl=(theConductor.service mediamtx.service obs.service obs-fix.service toggleInput.service)
for s in $sl; do
	systemctl --user stop $s
	systemctl --user disable $s
	rm -f $s
	ln -sfv $HOME/Code/CageLab/software/services/$s $HOME/.config/systemd/user
	if [[ $s == "theConductor.service" ]]; then
		[[ -d "/usr/local/MATLAB/R2025a" ]] && ln -sfv "$HOME/Code/CageLab/software/services/theConductor2025a.dservice" "$HOME/.config/systemd/user/theConductor.service"
		[[ -d "/usr/local/MATLAB/R2025b" ]] && ln -sfv "$HOME/Code/CageLab/software/services/theConductor2025b.dservice" "$HOME/.config/systemd/user/theConductor.service"
	fi
	systemctl --user daemon-reload
	systemctl --user enable $s
done
sleep 1
systemctl --user daemon-reload
systemctl --user restart mediamtx cogmoteGO theConductor obs obs-fix
