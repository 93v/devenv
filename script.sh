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

alias r="source $HOME/.bash_profile"
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
