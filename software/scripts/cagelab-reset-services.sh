#!/usr/bin/env zsh
# a script to reset all cage lab services to their default states
# should be run after any changes to the services or their configurations
echo "Resetting Cage Lab services to default states..."

# try to ensure no system services are running that might interfere
sudo systemctl disable --now cogmoteGO@prisys.service > /dev/null 2>&1
sudo systemctl disable --now theConductor.service  > /dev/null 2>&1
sudo systemctl disable --now mediamtx.service  > /dev/null 2>&1
sudo systemctl disable --now obs.service  > /dev/null 2>&1

# user services reset
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
	systemctl --user enable --now $s
	printf "...Reset and enabled %s\n" "$s"
done
echo "All cage lab services have been reset to their default states."