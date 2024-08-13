#!/bin/bash
set -e

apt-get install -y git vim
echo "source /usr/share/bash-completion/completions/git" >> ~/.bashrc
git config --local core.editor vim
terraform -install-autocomplete
