#!/usr/bin/env bash


#	MIT License
#
#	Copyright (c) 2024 Pukiru
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.

# References:
# SteamCMD documentation: https://developer.valvesoftware.com/wiki/SteamCMD#macOS
# Mae's guide to repackaging WEBFISHING on MacOS: https://mae.wtf/blog/28102024-webfishing-mac

FILE=~/Steam/steamcmd.sh

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
    echo "File $FILE does not exist."
    mkdir ~/Steam
    cd ~/Steam
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
fi

WEBFISHING_STEAM_APP_ID=3146520


if [[ -z $GAME_ID ]]; then
  echo "Game id was not set. Checking game name."
  GAME_NAME="${GAME_NAME:-WEBFISHING}"
  if [[ $GAME_NAME = WEBFISHING ]]; then
    GAME_ID=$WEBFISHING_STEAM_APP_ID
  else
    GAME_ID="UNKNOWN GAME ID"
  fi
  echo "Selecting game id for $GAME_NAME: $GAME_ID"
fi

INSTALL_DIR=~/Steam/godot_games/
GAME_DIR=${INSTALL_DIR}${GAME_ID}
if [[ "$(ls -A $GAME_DIR/steamapps)" ]]; then
  echo "Game already downloaded to $GAME_DIR."
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
  ./steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir $GAME_DIR +login $STEAM_USERNAME $STEAM_PASSWORD $STEAM_GUARD +app_update $GAME_ID validate +quit
fi


if [[ "$OSTYPE" == "linux-gnu" ]]; then
  PLATFORM="linux64"
else
  PLATFORM="macos"
fi
GODOT_3_STEAM_ARCHIVE="${PLATFORM}-g352-s158-gs321.zip"
GODOT_3_STEAM_URL="https://github.com/GodotSteam/GodotSteam/releases/download/v3.21/${GODOT_3_STEAM_ARCHIVE}"
GODOT_4_STEAM_ARCHIVE="${PLATFORM}-g43-s161-gs412.zip"
GODOT_4_STEAM_URL="https://github.com/GodotSteam/GodotSteam/releases/download/v4.12/${GODOT_4_STEAM_ARCHIVE}"


if [[ $GAME_ID = $WEBFISHING_STEAM_APP_ID ]]; then
  PACK_FILE_PATH="$GAME_DIR/webfishing.exe"
  GODOT_STEAM_URL="$GODOT_3_STEAM_URL"
  echo "Attempting to import WEBFISHING executable as Godot pack: $PACK_FILE_PATH"
fi

if [[ $GODOT_STEAM_URL = $GODOT_3_STEAM_URL ]]; then
  GODOT_STEAM_ARCHIVE=$GODOT_3_STEAM_ARCHIVE
else
  GODOT_STEAM_ARCHIVE=$GODOT_4_STEAM_ARCHIVE
fi


ARCHIVE_PATH="${INSTALL_DIR}${GODOT_STEAM_ARCHIVE}"
if [[ -f $ARCHIVE_PATH ]]; then
  echo "Godot steam archive ${GODOT_STEAM_ARCHIVE} already downloaded to ${ARCHIVE_PATH}."
else
  curl -L -o $ARCHIVE_PATH $GODOT_STEAM_URL
fi



if [[ "$PLATFORM" == "linux64" ]]; then
  echo "To do..."
else
  TMP="./tmp"
  mkdir $TMP
  ARCHIVE_TEMP_PATH="$TMP/template_archive"
  unzip -o -d $ARCHIVE_TEMP_PATH $ARCHIVE_PATH
  TEMPLATE_DIR="${TMP}/template_${GAME_ID}"
  unzip -o -d "$TEMPLATE_DIR" "${ARCHIVE_TEMP_PATH}/macos.zip"
  echo $GAME_ID > "${TEMPLATE_DIR}/osx_template.app/Contents/MacOS/steam_appid.txt"
  export GAME_NAME=$GAME_NAME
  cat "templates/${GAME_NAME}/${PLATFORM}/Info.plist.template" | envsubst '$GAME_NAME' > "${TEMPLATE_DIR}/osx_template.app/Contents/Info.plist"
  CONTENTS_DIR="${TEMPLATE_DIR}/osx_template.app/Contents/"
  cp "${PACK_FILE_PATH}" "${CONTENTS_DIR}Resources/${GAME_NAME}.pck"
  EXECUTABLE_PREFIX="${CONTENTS_DIR}MacOS/"
  rm "${EXECUTABLE_PREFIX}godot_osx_debug.64"
  mv "${EXECUTABLE_PREFIX}godot_osx_release.64" "${EXECUTABLE_PREFIX}${GAME_NAME}"
  OUTPUT_APP_PATH="${GAME_NAME}.app"
  rm -rf "$OUTPUT_APP_PATH"
  mv "${TEMPLATE_DIR}/osx_template.app/" "${OUTPUT_APP_PATH}"
  echo "Saved packaged MacOS app to ${OUTPUT_APP_PATH}"
  sudo xattr -cr "${OUTPUT_APP_PATH}"
  rm -rf $TMP
fi


