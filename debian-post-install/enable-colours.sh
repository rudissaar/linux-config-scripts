#!/usr/bin/env bash

# Check if dircolors is installed.
which dircolors 1>/dev/null 2>&1

# Install package that contains dircolors.
if [[ "${?}" != '0' ]]; then
    apt-get update -y
    apt-get install -y coreutils
fi

grep -Fq "LS_OPTIONS='--color=auto'" /etc/bash.bashrc

if [[ "${?}" != '0' ]]; then
    echo "LS_OPTIONS='--color=auto'" >> /etc/bash.bashrc
fi

grep -Fq "eval \$(dircolors)" /etc/bash.bashrc

if [[ "${?}" != '0' ]]; then
    echo "eval \$(dircolors)" >> /etc/bash.bashrc
fi

grep -Fq "alias ls='ls \${LS_OPTIONS}'" /etc/bash.bashrc

if [[ "${?}" != '0' ]]; then
    echo "alias ls='ls \${LS_OPTIONS}'" >> /etc/bash.bashrc
fi

# Source global bashrc file that we just changed.
. /etc/bash.bashrc

echo '> Finished.'

