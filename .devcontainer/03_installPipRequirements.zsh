#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"


echo "${blue}Installing requirements.txt....${reset}"
pip install -r requirements.txt --no-warn-script-location
echo ""
echo ""