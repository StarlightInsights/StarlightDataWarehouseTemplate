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

# Load .env variables into the current shell and persist them in ~/.zshrc
echo "${blue}${bold}Load .env${reset}"
echo ""
if [ -f .env ]; then
  echo "Loading .env variables..."
  # Export variables for the current script
  export $(grep -v '^#' .env | xargs)

  # Persist to ~/.zshrc for future sessions
  grep -v '^#' .env | while IFS= read -r line; do
    if [[ ! -z "$line" ]]; then
      var=$(echo $line | cut -d '=' -f 1)
      if ! grep -q "export $var=" ~/.zshrc; then
        echo "export $line" >> ~/.zshrc
      fi
    fi
  done
else
  echo "${red}No .env file found!${reset}"
fi

# Install dbt deps
echo "${blue}${bold}dbt deps${reset}"
echo ""
zsh .devcontainer/05_dbtDeps.zsh
