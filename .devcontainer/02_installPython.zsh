#!/bin/zsh

bold="\033[1m"
blue="\033[0;34m"
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

PYTHON_VERSION=$(cat .python-version)

echo "${blue}Updating package lists...${reset}"
sudo apt-get update

echo "${blue}Installing required tools...${reset}"
sudo apt-get install -y software-properties-common

echo "${blue}Adding deadsnakes PPA for Python $PYTHON_VERSION ...${reset}"
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt-get update

echo "${blue}Installing Python $PYTHON_VERSION and related packages...${reset}"
sudo apt-get install -y python$PYTHON_VERSION python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-distutils

echo "${blue}Installing pip for Python $PYTHON_VERSION ...${reset}"
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python$PYTHON_VERSION get-pip.py
rm get-pip.py

echo "${blue}Setting Python $PYTHON_VERSION as default ...${reset}"
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python$PYTHON_VERSION 1

echo "${blue}Updating pip ...${reset}"
sudo python$PYTHON_VERSION -m pip install --upgrade pip

echo "${blue}Checking versions of python3 and pip ...${reset}"
python3 --version
python$PYTHON_VERSION -m pip --version

echo ""
echo "${green}Python $PYTHON_VERSION installation complete!${reset}"