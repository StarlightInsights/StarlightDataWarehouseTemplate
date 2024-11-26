#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"


echo "${blue}Run dbt deps....${reset}"
cd starlight
dbt deps
echo ""
echo ""
