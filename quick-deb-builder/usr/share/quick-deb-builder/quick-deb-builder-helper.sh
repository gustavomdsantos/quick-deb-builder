#! /bin/bash

# Author: Gustavo Moraes <gustavosotnas@gmail.com>
#
# This file is subject to the terms and conditions of the GNU General Public
# License. See the file COPYING in the main directory of this archive
# for more details.

# RETURN CODES personalizados do Quick DEB Builder:
# 	50 = "Yes" para fechar
#	100 = "No" para fechar

APP_NAME="Quick DEB Builder"
CMD_NAME="quick-deb-builder"
VERSION="1.1.1"
APP_AUTHOR="Copyright (C) 2015 Gustavo Moraes"
CONTACT_AUTHOR="http://about.me/gustavosotnas"
APP_HOMEPAGE="https://github.com/gustavosotnas/quick-deb-builder"
HELP_DESCRIPTION_TEXT_LINE1="$APP_NAME is a simple tool that quickly creates .deb packages"
HELP_DESCRIPTION_TEXT_LINE2="from an existing build tree. It automatically solves most common"
HELP_DESCRIPTION_TEXT_LINE3="permission problems for files and directories in creating .deb packages."

displayAboutDialog_GUI()
{
	yad --title "About $APP_NAME" --info --center --width=480 --image="package" --window-icon="package" --icon-name="package" --text "<b>$APP_NAME</b>\n\n$VERSION\n\n`echo $HELP_DESCRIPTION_TEXT_LINE1 $HELP_DESCRIPTION_TEXT_LINE2 $HELP_DESCRIPTION_TEXT_LINE3`<b>$ADVICE_DESCRIPTION_TEXT</b>\n\n\n$APP_AUTHOR <b>$CONTACT_AUTHOR</b>" --text-align=center --borders=5 --button=Close:0;
}

displayHelp_CLI()
{
	echo; # Imprime apenas um '\n'
	echo -n "Usage"; echo -n ":"; echo " $CMD_NAME";
	echo -n "   or"; echo -n ":"; echo -n " $CMD_NAME ["; echo -n "OPTION"; echo "]";
	echo;
	echo "$HELP_DESCRIPTION_TEXT_LINE1";
	echo "$HELP_DESCRIPTION_TEXT_LINE2";
	echo "$HELP_DESCRIPTION_TEXT_LINE3";
	echo;
	echo -n "Options"; echo ":";
	echo -n "  -h, --help			"; echo "Display this help and exit";
	echo -n "      --version			"; echo "Shows version information and exit";
	echo;
	echo "Report $CMD_NAME bugs to <$APP_HOMEPAGE>";
	echo "Released under the GNU General Public License."
	echo "$APP_AUTHOR <$CONTACT_AUTHOR>";
}

displayVersion_CLI()
{
	echo "$VERSION";
}

displayCancelDialog()
{
	yad --title "$APP_NAME" --info --center --width=400 --image="help" --window-icon="package" --icon-name="package" --text "<big>Are you sure you want to exit from $APP_NAME?</big>" --text-align=center --button=No:1 --button=Yes:0;
}

verify_term_all()
{
	if [ "$?" == "0" ] # Se o usuário quer terminar tudo (apertou o botão "Yes")
	then
		killall yad; # Mata o yad para o processo pai continuar executando (gera o RETURN CODE 143)
		exit 50; #killall yad avd-launcher.sh; exit; # Mata os pais e sai
	else
		exit 100; #exit; # Apenas sai do helper
	fi
}

verify_safe_exit()
{
	if [ "$?" == "0" ] # Se o usuário quer terminar tudo (apertou o botão "Yes")
	then
		exit 50; #killall yad avd-launcher.sh; exit; # Mata os pais e sai
	else
		exit 100; #exit; # Apenas sai do helper
	fi
}

case $1 in
	"about") displayAboutDialog_GUI;; # Abre uma janela de diálogo "sobre" com uma pequena ajuda de utilização do programa em GUI ("help")
	"--help") displayHelp_CLI;; # Escreve na saída padrão (Terminal) uma ajuda de utilização do programa para CLI
	"--version") displayVersion_CLI;; # Escreve na saída padrão (Terminal) a versão do aplicativo para informação
	"cancel") displayCancelDialog; verify_term_all;; # Interrompe todos os processos relacionados ao programa
	"safe-exit") displayCancelDialog; verify_safe_exit;;
esac;
