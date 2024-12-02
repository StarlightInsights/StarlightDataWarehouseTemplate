#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

if [ -f .devcontainer/.env ]; then
    echo "${bold}Loading environment variables...${reset}"
    set -a
    source .devcontainer/.env
    set +a
else
    echo "${blue}No .env file found in .devcontainer folder${reset}"
    echo "If you are using local devcontainer, copy .env.example to .devcontainer/.env and update the values"
fi

echo ""
echo ""
