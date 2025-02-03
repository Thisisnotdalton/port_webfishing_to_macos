#!/usr/bin/env bash


# Reference: https://developer.valvesoftware.com/wiki/SteamCMD#macOS

FILE=~/Steam/steamcmd.sh

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
    echo "File $FILE does not exist."
    mkdir ~/Steam
    cd ~/Steam
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
fi


if [[ -z $GAME_ID ]]; then
  echo "Game id was not set. Checking game name."
  GAME_NAME="${GAME_NAME:-WEBFISHING}"
  if [[ $GAME_NAME = WEBFISHING ]]; then
    GAME_ID=3146520
  else
    GAME_ID="UNKNOWN GAME ID"
  fi
  echo "Selecting game id for $GAME_NAME: $GAME_ID"
fi

INSTALL_DIR=~/Steam/godot_games/$GAME_ID
if [[ "$(ls -A $INSTALL_DIR/steamapps)" ]]; then
  echo "Game already downloaded to $INSTALL_DIR."
else
  cd ~/Steam
  if [[ -z $STEAM_USERNAME ]]; then
    echo -n "Please enter your Steam username:"
    read STEAM_USERNAME
  fi
  if [[ -z $STEAM_PASSWORD ]]; then
    echo -n "Please enter your Steam password:"
    read -s STEAM_PASSWORD
    echo
  fi
  if [[ -z $STEAM_GUARD ]]; then
    echo -n "Please enter your Steam Guard code if necessary:"
    read STEAM_GUARD
  fi
  ./steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir $INSTALL_DIR +login $STEAM_USERNAME $STEAM_PASSWORD $STEAM_GUARD +app_update $GAME_ID validate +quit
fi