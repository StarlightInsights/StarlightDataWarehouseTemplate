#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"


# check .dbt/profiles.yml file exists
if [ -f .dbt/profiles.yml ]; then
    echo "${bold}Copying dbt profiles into home...${reset}"
    sudo cp -r .dbt/ /home/"$USERNAME"/
else
    echo "${red}${bold}Error: File .dbt/profiles.yml does not exist.${reset}"
    echo "Please create .dbt/profiles.yml"
fi

echo ""
echo ""