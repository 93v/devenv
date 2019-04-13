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

spinner() {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

clear_line() {
    printf "\033[2K\r"
}

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
    p_info "Configuring macOS..."
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
	defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
	defaults write com.apple.finder QLEnableTextSelection -bool true
	defaults write com.apple.finder ShowStatusBar -bool true
	defaults write com.apple.finder ShowPathbar -bool true
	defaults write com.apple.finder DisableAllAnimations -bool true
    clear_line
    p_successln "macOS Configured!"
}

mac_install_command_line_tools() {
    p_info "Installing Command Line Tools..."
    clt_tmp="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
	touch "$clt_tmp"
	clt=$(softwareupdate -l | awk '/\*\ Command Line Tools/ { $1=$1;print }' | tail -1 | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)
	( softwareupdate -i "$clt" &>/dev/null & spinner $! )
	[[ -f "$clt_tmp" ]] && rm "$clt_tmp"
    clear_line
    p_successln "Command Line Tools Installed!"
}

mac_smart_install_command_line_tools() {
    if pkgutil --pkg-info com.apple.pkg.CLTools_Executables &>/dev/null; then
		count=0
		for file in $(pkgutil --files com.apple.pkg.CLTools_Executables); do
			if [ ! -e "/$file" ]; then ((count++)); break; fi
		done
		if (( count > 0 )); then
			( sudo rm -rf /Library/Developer/CommandLineTools & spinner $! )
			mac_install_command_line_tools
		fi
	else
		mac_install_command_line_tools
	fi
}

mac_install_brew() {
    p_info "Installing Homebrew..."
    mac_smart_install_command_line_tools
    ( echo | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" &>/dev/null & spinner $! )
    clear_line
    p_successln "Homebrew Installed!"
}

mac_smart_install_brew() {
    [ ! $(which brew) ] && mac_install_brew
}

mac_install_mas() {
    p_infoln "Installing Mac App Store command line interface..."
    p_logln "The process needs to run sudo commands and might ask for your password."

	sudo -v
	(while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &)

    mac_smart_install_brew
    [ $(which brew) ] && brew install mas >/dev/null 2>&1
    [ $(which xcodebuild) ] && sudo xcodebuild -license accept >/dev/null 2>&1

    clear_line
    p_successln "Mac App Store command line interface Installed!"

    # Deactivating sudo for the session
    sudo -k
}

mac_install_mac_apps() {
    p_infoln "Installing macOS Apps..."
    local APPS=(Numbers Pages Spark Xcode)

    local answers=()

    local install_all=false
    [[ "$1" = "--all" ]] && install_all=true

    if [ "$install_all" != true ]; then
        for index in ${!APPS[*]}; do
            p_info "Do you want to install "
            p_success "${APPS[$index]}"
            p_info " ?"
            if prompt "[y/N]"; then answers[$index]=true; fi
        done
    fi

    for index in ${!APPS[*]}; do
        if [[ ${answers[$index]} = true || $install_all = true ]]; then
            [ ! $(which mas) ] && mac_install_mas
            clear_line
            p_info "Installing "
            p_success "${APPS[$index]}"
            p_info " ..."
            ( mas lucky ${APPS[$index]} &>/dev/null & spinner $! )
        fi
    done

    clear_line
    p_successln "macOS Apps Installed!"
}

mac_install_brew_packages() {
    p_infoln "Installing Homebrew Packages..."
    local PACKAGES=(
        bash
        bash-completion
        brew-cask-completion
        gem-completion
        git
        goenv
        mas
        nodenv
        pip-completion
        pyenv
        rbenv
        ruby-completion
        tmux
        vim
    )

    local answers=()

    local install_all=false
    [[ "$1" = "--all" ]] && install_all=true

    if [ "$install_all" != true ]; then
        for index in ${!PACKAGES[*]}; do
            p_info "Do you want to install "
            p_success "${PACKAGES[$index]}"
            p_info " ?"
            if prompt "[y/N]"; then answers[$index]=true; fi
        done
    fi

    for index in ${!PACKAGES[*]}; do
        if [[ ${answers[$index]} = true || $install_all = true ]]; then
            [ ! $(which brew) ] && mac_install_brew
            clear_line
            p_info "Installing "
            p_success "${PACKAGES[$index]}"
            p_info " from Homebrew..."
            ( brew install ${PACKAGES[$index]} &>/dev/null & spinner $! )
            if [ "${PACKAGES[$index]}" = "nodenv" ]; then
                ( brew unlink node-build &>/dev/null & spinner $! )
                ( brew install --HEAD node-build &>/dev/null & spinner $! )
                ( brew link node-build &>/dev/null & spinner $! )
            fi
        fi
    done

    clear_line
    p_successln "Homebrew Packages Installed!"
}

mac_install_brew_casks() {
    p_infoln "Installing Homebrew Casks..."
    local CASKS=(
        authy
        bitwarden
        caskroom/fonts/font-fira-code
        docker
        iterm2
        java
        slack
        spectacle
        the-unarchiver
        visual-studio-code-insiders
    )

    local answers=()

    local install_all=false
    [[ "$1" = "--all" ]] && install_all=true

    if [ "$install_all" != true ]; then
        for index in ${!CASKS[*]}; do
            p_info "Do you want to install "
            p_success "${CASKS[$index]}"
            p_info " ?"
            if prompt "[y/N]"; then answers[$index]=true; fi
        done
    fi

    for index in ${!CASKS[*]}; do
        if [[ ${answers[$index]} = true || $install_all = true ]]; then
            [ ! $(which brew) ] && mac_install_brew
            clear_line
            p_info "Installing "
            p_success "${CASKS[$index]}"
            p_info " from Homebrew..."
            ( brew cask install ${CASKS[$index]} &>/dev/null & spinner $! )
            if [ "${CASKS[$index]}" = "visual-studio-code-insiders" ]; then
                VSCODE_PLUGINS=( Shan.code-settings-sync )
                for plugin in ${VSCODE_PLUGINS[@]}; do
                    ( code-insiders --install-extension ${plugin} &>/dev/null & spinner $! )
                done
                ( [[ $(pgrep Code) && $(pgrep Electron) ]] && kill -9 $(pgrep Code) && kill -9 $(pgrep Electron) && code-insiders &>/dev/null & spinner $!)
            fi
        fi
    done

    clear_line
    p_successln "Homebrew Packages Installed!"
}

mac_setup() {
    # Keep-alive: update existing `sudo` time stamp until the script has finished.
	clear
    p_infoln "Starting the Setup process..."
    p_logln "The process needs to run sudo commands and might ask for your password."

	sudo -v
	(while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &)
	sudo xcodebuild -license accept

    # The actual working part
    install_all=false
    [[ "$1" = "--all" ]] && install_all=true

    configure_mac=false
    install_command_line_tools=false
    install_brew=false
    install_mas=false
    install_mac_apps=false
    install_brew_packages=false
    install_brew_casks=false

    if [ "$install_all" != true ]; then
        p_info "Do you want to configure macOS? "
        if prompt "[y/N]"; then configure_mac=true; fi

        p_info "Do you want to install Command Line Tools? "
        if prompt "[y/N]"; then install_command_line_tools=true; fi

        if [ ! $(which brew) ]; then
            p_info "Do you want to install Homebrew? "
            if prompt "[y/N]"; then install_brew=true; fi
        fi

        if $install_brew && ! $install_command_line_tools; then
            p_log "Homebrew installation requires Command Line Tools. "
            p_logln "Will automatically install Command Line Tools."
            install_command_line_tools=true
        fi

        if [ ! $(which mas) ]; then
            p_info "Do you want to install Mac App Store command line interface? "
            if prompt "[y/N]"; then install_mas=true; fi
        fi

        if $install_mas && ! $install_brew && [ ! $(which brew) ]; then
            p_log "Mac App Store command line interface installation requires Homebrew. "
            p_logln "Will automatically install Homebrew."
            install_brew=true
        fi

        if $install_brew && ! $install_command_line_tools; then
            p_log "Homebrew installation requires Command Line Tools. "
            p_logln "Will automatically install Command Line Tools."
            install_command_line_tools=true
        fi

        p_info "Do you want to install Homebrew Packages? "
        if prompt "[y/N]"; then install_brew_packages=true; fi

        if $install_brew_packages && ! $install_brew && [ ! $(which brew) ]; then
            p_log "Homebrew Packages installation requires Homebrew. "
            p_logln "Will automatically install Homebrew."
            install_brew=true
        fi

        if $install_brew && ! $install_command_line_tools; then
            p_log "Homebrew installation requires Command Line Tools. "
            p_logln "Will automatically install Command Line Tools."
            install_command_line_tools=true
        fi

        p_info "Do you want to install Homebrew Casks? "
        if prompt "[y/N]"; then install_brew_casks=true; fi

        if $install_brew_casks && ! $install_brew && [ ! $(which brew) ]; then
            p_log "Homebrew Casks installation requires Homebrew. "
            p_logln "Will automatically install Homebrew."
            install_brew=true
        fi

        if $install_brew && ! $install_command_line_tools; then
            p_log "Homebrew installation requires Command Line Tools. "
            p_logln "Will automatically install Command Line Tools."
            install_command_line_tools=true
        fi

        p_info "Do you want to install Mac Apps? "
        if prompt "[y/N]"; then install_mac_apps=true; fi
    fi

    if $install_all || $configure_mac; then
        mac_configure
    fi
    if $install_all || $install_command_line_tools; then
        mac_smart_install_command_line_tools
    fi
    if $install_all || $install_brew; then
        mac_install_brew
    fi
    if $install_all || $install_mas; then
        mac_install_mas
    fi
    if $install_all || $install_mac_apps; then
        mac_install_mac_apps "$@"
    fi
    if $install_all || $install_brew_packages; then
        mac_install_brew_packages "$@"
    fi
    if $install_all || $install_brew_casks; then
        mac_install_brew_casks "$@"
    fi

    # New line
    echo
    p_successln "Setup Finished!"

    # Deactivating sudo for the session
    sudo -k
}

mac_update_brew() {
    [ ! $(which brew) ] && mac_smart_install_brew
	cd "$(brew --repo)" && git fetch origin && git reset --hard origin/master
	cd -
	brew update && brew upgrade
	brew uninstall --force --ignore-dependencies node-build
	brew install --HEAD node-build
}

mac_update_brew_casks() {
    [ ! $(which brew) ] && mac_smart_install_brew
	brew cask upgrade
	for app in $(brew cask list); do
		current_version=$(ls -1 /usr/local/Caskroom/${app}/.metadata/ | head -n 1)
		av=$(brew cask info ${app} | tail -n +1 | head -n 1 | cut -d ' ' -f 2)
		if [[ ${current_version} != ${av} ]] || [[ ${current_version} == "latest" ]]; then
			brew cask uninstall "${app}" --force
			brew cask install "${app}"
		fi
	done
}

mac_update() {
    p_info "Updating macOS..."
    ( softwareupdate -ia &>/dev/null & spinner $! )

    if [ $(which mas) ]; then
        clear_line
        p_info "Updating Mac App Store Apps..."
        ( mas upgrade &>/dev/null & spinner $! )
    fi

    if [ $(which brew) ]; then
        clear_line
        p_info "Updating Homebrew..."
        ( mac_update_brew &>/dev/null & spinner $! )
        clear_line
        p_info "Updating Homebrew Casks..."
        ( mac_update_brew_casks &>/dev/null & spinner $! )
        # Cleanup after updates
        ( brew cleanup &>/dev/null & spinner $! )
    fi

    if [ $(which npm) ]; then
        clear_line
        p_info "Updating npm..."
        ( npm install -g npm &>/dev/null & spinner $! )
        ( npm update -g &>/dev/null & spinner $! )
    fi

    if [ $(which pip) ]; then
        clear_line
        p_info "Updating pip..."
        ( pip list --outdated --format=freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U &>/dev/null & spinner $! )
    fi

    if [ $(which gem) ]; then
        clear_line
        p_info "Updating gem..."
        ( gem update --system &>/dev/null & spinner $! )
        ( gem update &>/dev/null & spinner $! )
    fi

    if [ $(which vagrant) ]; then
        clear_line
        p_info "Updating Vagrant Plugins..."
        ( vagrant plugin update &>/dev/null & spinner $! )
    fi

    clear_line
    p_successln "Updated!"
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
    p_info "Updating DevEnv..."
    UPDATE_URL="https://raw.githubusercontent.com/93v/devenv/master/script.sh"
    ( curl -sL $UPDATE_URL > $HOME/.bash_profile & spinner $! )
    source $HOME/.bash_profile
    clear_line
    p_successln "DevEnv Updated!"
}

# macOS Cleanup
mac_cleanup() {
    # Keep-alive: update existing `sudo` time stamp until the script has finished.
	clear
    p_infoln "Starting the Cleanup process..."
    p_logln "The process needs to run sudo commands and might ask for your password."

	sudo -v
	( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null & )

    # Empty Trash
    clear_line
    p_info "Removing Volumes Trashes..."
	( sudo rm -rf /Volumes/*/.Trashes &>/dev/null & spinner $! )
    clear_line
    p_info "Removing Trash..."
	( sudo rm -rf ~/.Trash &>/dev/null & spinner $! )
	# User Caches and Logs
    clear_line
    p_info "Removing Library Caches..."
	( rm -rf ~/Library/Caches/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing Library Logs..."
	( rm -rf ~/Library/logs/* &>/dev/null & spinner $! )
	# System Caches and Logs
    clear_line
    p_info "Removing System Caches..."
	( sudo rm -rf /Library/Caches/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing System Logs..."
	( sudo rm -rf /Library/logs/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing Logs..."
	( sudo rm -rf /var/log/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing ASL Logs..."
	( sudo rm -rf /private/var/log/asl/*.asl &>/dev/null & spinner $! )
    clear_line
    p_info "Removing Diagnostic Reports..."
	( sudo rm -rf /Library/Logs/DiagnosticReports/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing Adobe Logs..."
	( sudo rm -rf /Library/Logs/Adobe/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing Mail Logs..."
	( rm -rf ~/Library/Containers/com.apple.mail/Data/Library/Logs/Mail/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing Core Simulator Logs..."
	( rm -rf ~/Library/Logs/CoreSimulator/* &>/dev/null & spinner $! )
	# Adobe Caches
    clear_line
    p_info "Removing Adobe Caches..."
	( sudo rm -rf ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files/* &>/dev/null & spinner $! )
	# Private Folders
    clear_line
    p_info "Removing Private Folders..."
	( sudo rm -rf /private/var/folders/* &>/dev/null & spinner $! )
	# iOS Apps, Backups and Photos Cache
    clear_line
    p_info "Removing iOS Apps..."
	( rm -rf ~/Music/iTunes/iTunes\ Media/Mobile\ Applications/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing iOS Backups..."
	( rm -rf ~/Library/Application\ Support/MobileSync/Backup/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing iOS Photo Cache..."
	( rm -rf ~/Pictures/iPhoto\ Library/iPod\ Photo\ Cache/* &>/dev/null & spinner $! )
	# XCode Derived Data and Archives
    clear_line
    p_info "Removing Xcode Derived Data..."
	( rm -rf ~/Library/Developer/Xcode/DerivedData/* &>/dev/null & spinner $! )
    clear_line
    p_info "Removing Xcode Archives..."
	( rm -rf ~/Library/Developer/Xcode/Archives/* &>/dev/null & spinner $! )
	# Homebrew Cache
    if type "brew" > /dev/null; then
        clear_line
        p_info "Cleaning Homebrew..."
        ( brew cleanup --force -s &>/dev/null & spinner $! )
    fi
    clear_line
    p_info "Removing Homebrew Caches..."
	( rm -rf /Library/Caches/Homebrew/* &>/dev/null & spinner $! )
    if type "brew" > /dev/null; then
        clear_line
        p_info "Repairing Homebrew taps..."
        ( brew tap --repair &>/dev/null & spinner $! )
    fi
	# Old gems
    if type "brew" > /dev/null; then
        clear_line
        p_info "Cleaning gems..."
        ( gem cleanup &>/dev/null & spinner $! )
    fi
	# Old Dockers
	if type "docker" > /dev/null; then
        clear_line
        p_info "Pruning Docker Containers..."
		( docker container prune -f &>/dev/null & spinner $! )
        clear_line
        p_info "Pruning Docker Images..."
		( docker image prune -f &>/dev/null & spinner $! )
        clear_line
        p_info "Pruning Docker Volumes..."
		( docker volume prune -f &>/dev/null & spinner $! )
        clear_line
        p_info "Pruning Docker Networks..."
		( docker network prune -f &>/dev/null & spinner $! )
	fi
	# Memory
    clear_line
    p_info "Purging the Memory..."
	( sudo purge & spinner $! )

	# Applications Caches
	for x in $(ls ~/Library/Containers/)
	do
        clear_line
        p_info "Removing Containers Data Caches..."
		( rm -rf ~/Library/Containers/$x/Data/Library/Caches/* &>/dev/null & spinner $! )
	done

    clear_line
    p_successln "Cleanup Completed!"

    # Deactivating sudo for the session
    sudo -k
}

# Aliases
alias r="source $HOME/.bash_profile && p_successln \"Refreshed!\""
alias c="mac_cleanup"
alias u="mac_update"
alias selfu="self_update"
# slefu is a usual typo
alias slefu="self_update"

# Initializer script
if [[ ${machine} == "Mac" ]]; then
	export PATH=$HOME/bin:/opt/local/bin:/opt/local/sbin:/usr/local/opt/ruby/bin:/usr/local/sbin:$PATH
	export JAVA_HOME=$(/usr/libexec/java_home)

	[ $(which nodenv) ] && eval "$(nodenv init -)"
	[ $(which pyenv) ] && eval "$(pyenv init -)"
	[ $(which rbenv) ] && eval "$(rbenv init -)"
	[ $(which goenv) ] && eval "$(goenv init -)"

	# If Visual Studio Code is not installed and VS Code Insiders is installed
	# alias code to code-insiders
	[ ! $(which code) ] && [ $(which code-insiders) ] && alias code="code-insiders"

	[ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion

	###-begin-npm-completion-###
	#
	# npm command completion script
	#
	# Installation: npm completion >> ~/.bashrc  (or ~/.zshrc)
	# Or, maybe: npm completion > /usr/local/etc/bash_completion.d/npm
	#

	if type complete &>/dev/null; then
		_npm_completion () {
			local words cword
			if type _get_comp_words_by_ref &>/dev/null; then
				_get_comp_words_by_ref -n = -n @ -n : -w words -i cword
			else
				cword="$COMP_CWORD"
				words=("${COMP_WORDS[@]}")
			fi
			local si="$IFS"
			IFS=$'\n' COMPREPLY=($(COMP_CWORD="$cword" \
								COMP_LINE="$COMP_LINE" \
								COMP_POINT="$COMP_POINT" \
								npm completion -- "${words[@]}" \
								2>/dev/null)) || return $?
			IFS="$si"
			if type __ltrim_colon_completions &>/dev/null; then
				__ltrim_colon_completions "${words[cword]}"
			fi
		}
		complete -o default -F _npm_completion npm
	elif type compdef &>/dev/null; then
		_npm_completion() {
			local si=$IFS
			compadd -- $(COMP_CWORD=$((CURRENT-1)) \
						COMP_LINE=$BUFFER \
						COMP_POINT=0 \
						npm completion -- "${words[@]}" \
						2>/dev/null)
			IFS=$si
		}
		compdef _npm_completion npm
	elif type compctl &>/dev/null; then
		_npm_completion () {
			local cword line point words si
			read -Ac words
			read -cn cword
			let cword-=1
			read -l line
			read -ln point
			si="$IFS"
			IFS=$'\n' reply=($(COMP_CWORD="$cword" \
							COMP_LINE="$line" \
							COMP_POINT="$point" \
							npm completion -- "${words[@]}" \
							2>/dev/null)) || return $?
			IFS="$si"
		}
		compctl -K _npm_completion npm
	fi
	###-end-npm-completion-###

	vol() {
		while true
		do
			osascript -e "set volume output volume ${1:-50}"
		done
	}
fi

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
