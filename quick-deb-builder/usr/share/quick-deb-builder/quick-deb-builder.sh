#! /bin/bash

APP_NAME="Quick DEB Builder"
VERSION="0.1.0"
HELP_DESCRIPTION_TEXT="$APP_NAME is a simple tool that quickly create .deb packages from an existing build tree."
APP_AUTHOR="Copyright (C) 2015 Gustavo Moraes http://about.me/gustavosotnas"

main()
{
	package_path_tmp=$(yad --title "$APP_NAME" --form --center --width=500 --image="package" --window-icon="package" --icon-name="package" --text "$HELP_DESCRIPTION_TEXT\n\n" --field 'Folder path to build tree\:':DIR $HOME --separator="" --borders=5 --button=Cancel:"./quick-deb-builder-helper.sh cancel" --button=OK:0)
}

main;