#!/usr/bin/env zsh
# a script to try to update all CageLab software

# lets make sure our symlinks are up-to-date
git -C ~/Code/Setup reset --hard
git -C ~/Code/Setup pull
~/Code/Setup/makelinks.sh

# stop all CageLab services
~/bin/cagelab-stop.sh

# ensure the main repos are reset to the latest commit
~/bin/cagelab-reset-code.sh

# update cogmoteGO
curl -sS https://raw.githubusercontent.com/cagelab/cogmoteGO/main/install.sh | sh

# update pixi which manages our command dependencies
pixi self-update; pixi global sync; pixi global -v update

# update flatpak that installs OBS
flatpak update -y 

# restart all CageLab services
~/bin/cagelab-start.sh