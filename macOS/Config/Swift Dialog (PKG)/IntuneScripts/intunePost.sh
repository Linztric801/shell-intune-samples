#!/bin/bash

############################################################################################
##
## Post-install Script for Swift Dialog
## 
## VER 1.0.0
##
############################################################################################

# Define any variables we need here:
logDir="/Library/Application Support/Microsoft/IntuneScripts/Swift Dialog"
DIALOG_BIN="/usr/local/bin/dialog"
PKG_PATH="/var/tmp/dialog-2.5.2-4777.pkg"

# Start Logging
mkdir -p "$logDir"
exec > >(tee -a "$logDir/postinstall.log") 2>&1

# Check if we've run before
#if [[ -f "$logDir/onboardingComplete" ]]; then
#  echo "$(date) | POST | We've already completed onboarding, let's exit quietly"
#  exit 1
#fi

# Check if SwiftDialog is installed
if [[ ! -f "$DIALOG_BIN" ]]; then
  echo "$(date) | POST | Swift Dialog is not installed [$DIALOG_BIN]. Installing now..."

  # Install SwiftDialog from the .pkg file
  if [[ -f "$PKG_PATH" ]]; then
    sudo installer -pkg "$PKG_PATH" -target /
    
    if [[ $? -eq 0 ]]; then
      echo "$(date) | POST | Swift Dialog has been installed successfully."
    else
      echo "$(date) | ERROR | Swift Dialog installation failed."
      exit 1
    fi
  else
    echo "$(date) | ERROR | Package file not found at $PKG_PATH. Exiting."
    exit 1
  fi
else
  echo "$(date) | POST | Swift Dialog is already installed."
fi

# Wait for Desktop
until ps aux | grep /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock | grep -v grep &>/dev/null; do
    echo "$(date) |  + Dock not running, waiting [1] seconds"
    sleep 1
done
echo "$(date) | Dock is here, lets carry on"

# Run Swift Dialog
/usr/local/bin/dialog --jsonfile "/Library/Application Support/SwiftDialogResources/swiftdialog.json" --width 1280 --height 670 --blurscreen --ontop &

# Wait for Swift Dialog to start
START=$(date +%s) # Set the start time so we can calculate how long we've been waiting
echo "$(date) | POST | Waiting for Swift Dialog to Start..."
# Loop for 1 minutes (60 seconds)
until ps aux | grep /usr/local/bin/dialog | grep -v grep &>/dev/null; do
    # Check if the 60 seconds have passed
    if [[ $(($(date +%s) - $START)) -ge 60 ]]; then
        echo "$(date) | POST | Failed: Swift Dialog did not start within 60 seconds"
        exit 1
    fi
    echo -n "."
    sleep 1
done
echo "OK"

echo "$(date) | POST | Processing scripts..."
for script in /Library/Application\ Support/SwiftdialogResources/scripts/*.*; do
  echo "$(date) | POST | Executing [$script]"
  xattr -d com.apple.quarantine "$script" >/dev/null 2>&1
  chmod +x "$script" >/dev/null 2>&1
  nice -n 20 "$script"
done

# Once we're done, we should write a flag file out so that we don't run again
sudo touch "$logDir/onboardingComplete"
exit 0
