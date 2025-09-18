#!/usr/bin/env zsh
# a script to launch the cage lab monitor tmuxp session

[[ ! -f $HOME/.config/tmuxp/cagelab-monitor.yaml ]] && \
	ln -sfv $HOME/Code/Setup/config/cagelab-monitor.yaml $HOME/.config/tmuxp/cagelab-monitor.yaml
tmuxp load $HOME/.config/tmuxp/cagelab-monitor.yaml