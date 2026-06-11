#!/bin/zsh

# Give networking a moment to reconnect after wake
sleep 30

# Send a trivial Claude Code request
/Users/brian/.local/bin/claude -p "Good morning"

# sleep again immediately
pmset sleepnow


