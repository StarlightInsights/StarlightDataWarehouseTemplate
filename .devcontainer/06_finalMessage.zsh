#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

echo ""
echo "${green}${bold}Setup is complete!${reset}"
echo ""
echo "${blue}Next steps:${reset}"
echo ""

echo "1. ${bold}Reload your environment.${reset}"
echo "   - If you are using VS Code, press ${bold}Cmd+Shift+P${reset} (or ${bold}Ctrl+Shift+P${reset} on Windows/Linux) to open the Command Palette."
echo "     Then type ${bold}Reload Window${reset} and select it."
echo "   - If you are in the browser, refresh the page to reload the Codespace."

echo ""
echo "2. ${bold}Find additional guidance and resources:${reset}"
echo "   - Visit ${blue}https://starlightinsights.com/starlight-data-warehouse-template${reset} for a comprehensive guide on setting up and using your environment, including DBT and Snowflake."
echo "   - Explore ${blue}https://starlightinsights.com/starlight-data-framework${reset} for insights and recommendations on effective data management."

echo ""
echo "${green}Happy coding! ✨${reset}"
