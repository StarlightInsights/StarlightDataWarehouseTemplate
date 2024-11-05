#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

# Setup Ubuntu
echo "${blue}${bold}Setup Ubuntu${reset}"
echo ""
zsh .devcontainer/01_setupUbuntu.zsh

# Install Python
echo "${blue}${bold}Install Python${reset}"
echo ""
zsh .devcontainer/02_installPython.zsh

# Install requirements
echo "${blue}${bold}Install requirements.txt${reset}"
echo ""
zsh .devcontainer/03_installPipRequirements.zsh

# Copy dbt profiles to home
echo "${blue}${bold}Copy dbt profiles to home${reset}"
echo ""
zsh .devcontainer/04_copyDbtProfiles.zsh