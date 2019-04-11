#!/usr/bin/env bash

# Getting the OS the script is running on
os_name="$(uname -s)"
case "${os_name}" in
	Linux*)		machine=Linux;;
	Darwin*)	machine=Mac;;
	# CYGWIN*)	machine=Cygwin;;
	# MINGW32*)	machine=Win32;;
	# MINGW64*)	machine=Win64;;
	*)			machine="UNKNOWN:${os_name}"
esac

if [[ ${machine} == UNKNOWN* ]]; then echo "Unsupported OS ${machine}. Exiting..."; return; fi

# Setup
setup() {
    [[ ${machine} == "Mac" ]] && echo "macOS setup scripts coming soon..."
	[[ ${machine} == "Linux" ]] && echo "Linux setup scripts coming soon..."
}

# Self Update
self_update() {
    UPDATE_URL="https://raw.githubusercontent.com/93v/devenv/master/script.sh"
    curl -sL $UPDATE_URL > $HOME/.bash_profile
    source $HOME/.bash_profile
    echo "DevEnv Updated!"
}

mac_cleanup() {
    # Empty Trash
	sudo rm -rfv /Volumes/*/.Trashes &>/dev/null
	sudo rm -rfv ~/.Trash &>/dev/null
	# User Caches and Logs
	rm -rfv ~/Library/Caches/*
	rm -rfv ~/Library/logs/*
	# System Caches and Logs
	sudo rm -rfv /Library/Caches/*
	sudo rm -rfv /Library/logs/*
	sudo rm -rfv /var/log/*
	sudo rm -rfv /private/var/log/asl/*.asl &>/dev/null
	sudo rm -rfv /Library/Logs/DiagnosticReports/* &>/dev/null
	sudo rm -rfv /Library/Logs/Adobe/* &>/dev/null
	rm -rfv ~/Library/Containers/com.apple.mail/Data/Library/Logs/Mail/* &>/dev/null
	rm -rfv ~/Library/Logs/CoreSimulator/* &>/dev/null
	# Adobe Caches
	sudo rm -rfv ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files/* &>/dev/null
	# Private Folders
	sudo rm -rfv /private/var/folders/*
	# iOS Apps, Backups and Photos Cache
	rm -rfv ~/Music/iTunes/iTunes\ Media/Mobile\ Applications/* &>/dev/null
	rm -rfv ~/Library/Application\ Support/MobileSync/Backup/* &>/dev/null
	rm -rfv ~/Pictures/iPhoto\ Library/iPod\ Photo\ Cache/*
	# XCode Derived Data and Archives
	rm -rfv ~/Library/Developer/Xcode/DerivedData/* &>/dev/null
	rm -rfv ~/Library/Developer/Xcode/Archives/* &>/dev/null
	# Homebrew Cache
	brew cleanup --force -s &>/dev/null
	rm -rfv /Library/Caches/Homebrew/* &>/dev/null
	brew tap --repair &>/dev/null
	# Old gems
	gem cleanup &>/dev/null
	# Old Dockers
	if type "docker" > /dev/null; then
		echo 'Cleanup Docker'
		docker container prune -f
		docker image prune -f
		docker volume prune -f
		docker network prune -f
	fi
	# Memory
	sudo purge

	# Applications Caches
	for x in $(ls ~/Library/Containers/)
	do
		rm -rfv ~/Library/Containers/$x/Data/Library/Caches/*
	done
}

# Aliases

alias r="source $HOME/.bash_profile"
alias c="mac_cleanup"
alias selfu="self_update"
alias slefu="self_update"

# ------------------------------------------------------------------------------
# Launching a function from this file directly
# ------------------------------------------------------------------------------

# You can launch any function from this file by simply calling
# bash script.sh function_name
# bash script.sh function_name arg1 arg2

# Check if the function exists (bash specific)
if [ -n "$1" ]; then
    if declare -f "$1" > /dev/null;
    then
    	# call arguments verbatim
    	"$@"
    else
    	# Show a helpful error
    	echo "'$1' is not a known function name" >&2
    	exit 1
    fi
fi
