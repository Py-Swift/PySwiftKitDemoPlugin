#!/bin/bash
# Helper script to run apps on different displays

DISPLAY_NUM=${1:-99}
PYTHON_SCRIPT=${2:-test-kivy-app.py}

export DISPLAY=:$DISPLAY_NUM
export SDL_VIDEODRIVER=x11

echo "Running $PYTHON_SCRIPT on display :$DISPLAY_NUM"
python3 /work/$PYTHON_SCRIPT
