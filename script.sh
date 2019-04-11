#!/usr/bin/env bash

# Better printf function
p_print() {
	string=$1
	params=${@:2}

    # Styles and Colors literals
    STYLE_NONE=00
    STYLE_BOLD=01
    STYLE_UNDERSCORE=04
    STYLE_BLINK=05
    STYLE_REVERSE=07
    STYLE_CONCEALED=08
    COLOR_BLACK=30
    COLOR_RED=31
    COLOR_GREEN=32
    COLOR_YELLOW=33
    COLOR_BLUE=34
    COLOR_MAGENTA=35
    COLOR_CYAN=36
    COLOR_WHITE=37
    BG_BLACK=40
    BG_RED=41
    BG_GREEN=42
    BG_YELLOW=43
    BG_BLUE=44
    BG_MAGENTA=45
    BG_CYAN=46
    BG_WHITE=47
    NO_STYLE='\e[0m'

	style_string='\e['
	for param in ${@:2}; do
		case $param in
			STYLE_NONE*)		style_string+=$STYLE_NONE";";;
			STYLE_BOLD*)		style_string+=$STYLE_BOLD";";;
			STYLE_UNDERSCORE*)	style_string+=$STYLE_UNDERSCORE";";;
			STYLE_BLINK*)		style_string+=$STYLE_BLINK";";;
			STYLE_REVERSE*)		style_string+=$STYLE_REVERSE";";;
			STYLE_CONCEALED*)	style_string+=$STYLE_CONCEALED";";;
			COLOR_BLACK*)		style_string+=$COLOR_BLACK";";;
			COLOR_RED*)			style_string+=$COLOR_RED";";;
			COLOR_GREEN*)		style_string+=$COLOR_GREEN";";;
			COLOR_YELLOW*)		style_string+=$COLOR_YELLOW";";;
			COLOR_BLUE*)		style_string+=$COLOR_BLUE";";;
			COLOR_MAGENTA*)		style_string+=$COLOR_MAGENTA";";;
			COLOR_CYAN*)		style_string+=$COLOR_CYAN";";;
			COLOR_WHITE*)		style_string+=$COLOR_WHITE";";;
			BG_BLACK*)			style_string+=$BG_BLACK";";;
			BG_RED*)			style_string+=$BG_RED";";;
			BG_GREEN*)			style_string+=$BG_GREEN";";;
			BG_YELLOW*)			style_string+=$BG_YELLOW";";;
			BG_BLUE*)			style_string+=$BG_BLUE";";;
			BG_MAGENTA*)		style_string+=$BG_MAGENTA";";;
			BG_CYAN*)			style_string+=$BG_CYAN";";;
			BG_WHITE*)			style_string+=$BG_WHITE";";;
			*)					;;
		esac
	done
	[[ style_string == '\e[' ]] && style_string+='0'
	i=$((${#style_string}-1))
	[[ ${style_string:$i:1} == ';' ]] && style_string=${style_string:0:$i}
	style_string+='m'
	printf "${style_string}${string}${NO_STYLE}"
}

p_println() { 	p_print "${@}"; echo; }
p_log() { 		p_print "$1" COLOR_WHITE; }
p_alert() { 	p_print "$1" COLOR_RED STYLE_BOLD; }
p_success() { 	p_print "$1" COLOR_GREEN STYLE_BOLD; }
p_info() { 		p_print "$1" COLOR_CYAN STYLE_BOLD; }
p_logln() { 	p_log "$1"; echo; }
p_alertln() { 	p_alert "$1"; echo; }
p_successln() { p_success "$1"; echo; }
p_infoln() { 	p_info "$1"; echo; }

prompt() { read -p "$1 " -n 1 -r && echo; [[ $REPLY =~ ^[Yy]$ ]] && true || false; }
# Usage
# if prompt "ok? [y/N]"; then
# 	echo 'OK'
# fi

# Util functions
free-port() { kill "$(lsof -t -i :$1)"; }

kill-port() { kill -kill "$(lsof -t -i :$1)"; }

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

if [[ ${machine} == UNKNOWN* ]]; then
    p_alertln "Unsupported OS ${machine}. Exiting..."
    return
fi

mac_configure() {
    p_info "Configuring macOS... "
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
	defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
	defaults write com.apple.finder QLEnableTextSelection -bool true
	defaults write com.apple.finder ShowStatusBar -bool true
	defaults write com.apple.finder ShowPathbar -bool true
	defaults write com.apple.finder DisableAllAnimations -bool true
    p_successln "macOS Configured!"
}

mac_install_command_line_tools() {
    p_info "Installing Command Line Tools... "
    clt_tmp="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
	touch "$clt_tmp"
	clt=$(softwareupdate -l | awk '/\*\ Command Line Tools/ { $1=$1;print }' | tail -1 | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)
	softwareupdate -i "$clt" >/dev/null 2>&1
	[[ -f "$clt_tmp" ]] && rm "$clt_tmp"
    p_successln "Command Line Tools Installed!"
}

mac_smart_install_command_line_tools() {
    if pkgutil --pkg-info com.apple.pkg.CLTools_Executables >/dev/null 2>&1; then
		count=0
		for file in $(pkgutil --files com.apple.pkg.CLTools_Executables); do
			if [ ! -e "/$file" ]; then ((count++)); break; fi
		done
		if (( count > 0 )); then
			sudo rm -rfv /Library/Developer/CommandLineTools
			mac_install_command_line_tools
		fi
	else
		mac_install_command_line_tools
	fi
}

mac_install_brew() {
    p_info "Installing Homebrew..."
    mac_smart_install_command_line_tools
    echo | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" >/dev/null 2>&1
    p_successln "Homebrew Installed!"
}

mac_setup() {
    install_all=false
    [[ "$1" = "--all" ]] && install_all=true

    configure_mac=false
    install_command_line_tools=false
    install_brew=false

    if [ "$install_all" != true ]; then
        p_info "Do you want to configure macOS? "
        if prompt "[y/N]"; then configure_mac=true; fi

        p_info "Do you want to install Command Line Tools? "
        if prompt "[y/N]"; then install_command_line_tools=true; fi

        p_info "Do you want to install Homebrew? "
        if prompt "[y/N]"; then install_brew=true; fi

        if $install_brew && ! $install_command_line_tools; then
            p_log "Homebrew installation requires Command Line Tools. "
            p_logln "Will install Command Line Tools."
            install_command_line_tools=true
        fi
    fi

    if $install_all || $configure_mac; then mac_configure; fi
    if $install_all || $install_command_line_tools; then mac_smart_install_command_line_tools; fi
    if $install_all || $install_brew; then mac_install_brew; fi
    p_successln "Setup Finished!"
}

linux_setup() {
    p_alertln "Linux setup scripts coming soon..."
}

# Setup
setup() {
    [[ ${machine} == "Mac" ]] && mac_setup "$@"
	[[ ${machine} == "Linux" ]] && linux_setup "$@"
}

# Self Update
self_update() {
    p_info "Updating DevEnv... "
    UPDATE_URL="https://raw.githubusercontent.com/93v/devenv/master/script.sh"
    curl -sL $UPDATE_URL > $HOME/.bash_profile
    source $HOME/.bash_profile
    p_successln "DevEnv Updated!"
}

# macOS Cleanup
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
		p_infoln 'Cleanup Docker...'
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

    p_successln "Cleanup Completed!"
}

# Aliases
alias r="source $HOME/.bash_profile"
alias c="mac_cleanup"
alias selfu="self_update"
# slefu is a usual typo
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
