#!/usr/bin/env bash
if [ -f /usr/bin/waypaper ]; then
    echo ":: Launching wallpaper selector in /usr/bin"
    waypaper $1 &
elif [ -f $HOME/.local/bin/waypaper ]; then
    echo ":: Launching wallpaper selector in $HOME/.local/bin"
    $HOME/.local/bin/waypaper $1 &
else
    echo ":: waypaper not found"
fi
