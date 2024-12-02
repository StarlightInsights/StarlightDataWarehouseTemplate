#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
yellow="\033[0;33m"
reset="\033[0m"

# Check if running in a GitHub Codespace
if [[ -n "$CODESPACES" ]]; then
    echo "${yellow}${bold}Running in a GitHub Codespace. Skipping .env loading.${reset}"
    echo "Environment variables should be set via GitHub Secrets or Repository Variables."
else
    # Check if .env file exists
    if [ -f .env ]; then
        echo "${bold}Loading .env variables locally...${reset}"

        # Export variables for the current shell without printing their values
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ ! -z "$line" && "$line" != \#* ]]; then
                var=$(echo $line | cut -d '=' -f 1)
                export $line
                echo "${blue}Loaded $var into the environment (value hidden for security)${reset}"
            fi
        done < .env

        # Persist variables into ~/.zshrc without exposing their values
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ ! -z "$line" && "$line" != \#* ]]; then
                var=$(echo $line | cut -d '=' -f 1)
                if ! grep -q "export $var=" ~/.zshrc; then
                    echo "export $line" >> ~/.zshrc
                fi
            fi
        done < .env

        echo "${green}All .env variables have been securely loaded and persisted to ~/.zshrc.${reset}"
    else
        echo "${yellow}${bold}No .env file found.${reset}"
        echo "Skipping local .env loading."
    fi
fi

echo ""
echo ""
