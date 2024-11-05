#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"


echo "${blue}Setting PATH ...${reset}"
echo 'export PATH="$PATH:/home/'"$USERNAME"'/.local/bin"' >> ~/.zshrc
source ~/.zshrc
echo $PATH
echo ""

echo "${blue}Updaing apt-get ...${reset}"
sudo apt-get update
echo ""

echo "${blue}Upgrading apt-get ...${reset}"
sudo apt-get upgrade -y
echo ""
echo ""