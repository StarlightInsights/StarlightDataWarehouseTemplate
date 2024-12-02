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

# Install requirements
echo "${blue}${bold}Install requirements.txt${reset}"
echo ""
zsh .devcontainer/02_installPipRequirements.zsh

# Copy DBT profiles to home
echo "${blue}${bold}Copy DBT profiles to home${reset}"
echo ""
zsh .devcontainer/03_copyDbtProfiles.zsh

# Install dbt deps
echo "${blue}${bold}dbt deps{reset}"
echo ""
zsh .devcontainer/04_dbtDeps.zsh

# Install DBT deps
echo "${blue}${bold}Load env{reset}"
echo ""
zsh .devcontainer/05_loadEnv.zsh
