#!/bin/sh
# Show welcome message only if Desktop Environment is not installed

# Check if DE is already installed
if [ ! -f /etc/de-installed ]; then
    cat << 'EOF'

========================================
  Welcome to Void Linux on Xiaomi Pad 6
========================================

You are currently in console mode (TTY).

To install a Desktop Environment (KDE Plasma or GNOME), run:
    sudo setup-de

After installation, reboot to start the graphical interface.

For more information, visit:
https://t.me/pipa_mainline

========================================

EOF
fi
