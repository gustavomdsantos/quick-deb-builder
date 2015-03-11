#! /bin/bash

# Author: Gustavo Moraes <gustavosotnas@gmail.com>
#
# This file is subject to the terms and conditions of the GNU General Public
# License. See the file COPYING in the main directory of this archive
# for more details.

# Parâmetros obrigatórios que o "/usr/bin/quick-deb-builder" passa:
# 	$1=$HOME - Caminho da pasta inicial do usuário comum
#	$2=$USER - Nome do usuário comum

#set -u; # Bash will exit the script if you try to use an uninitialised variable

APP_NAME="Quick DEB Builder"
VERSION="0.3.0"
APP_AUTHOR="Copyright (C) 2015 Gustavo Moraes http://about.me/gustavosotnas"
HELP_DESCRIPTION_TEXT="Select a folder path with a \"debian-like\" directory structure and an output folder path and press OK below:"
CURRENT_USER="$2"
true=1; false=0; # boolean

main()
{
	verify_GUI;

	false; # Para entrar no while
	while [ $? -ne 0 ] # Enquanto a saída do último comando não for igual a ZERO (return =! 0)
	do
		define_deb_IO_folder_paths "$1";
		(create_deb_package); # Existe um "exit" que pode ser executado dentro da função; para não finalizar o script inteiro, a função é executada em subshell: "(" + código + ")"
	done
	dialog_deb_creation_sucess;
}

verify_GUI()
{
	if [ -n "$DISPLAY" ] # O script está sendo executado em interface gráfica
	then
		return 0;
	else # O script está sendo executado em interface de texto
		>&2 echo "This program needs to be run in GUI mode.";
		exit 1;
	fi
}

define_deb_IO_folder_paths()
{
	false; # Para entrar no while
	while [ $? -ne 0 ] # Enquanto a saída do último comando não for igual a ZERO (return =! 0)
	do
		package_path_tmp2=$(get_folder_paths "$1");
			verifyReturnCode;
		if [ "$?" != "1" ] # Se o usuário não quer sair do programa
		then
			validate_deb_package "$package_path_tmp2";
			local returnCode=$?;
			package_path_tmp2=""; # "Desaloca" variável bash
			generateReturnCode $returnCode; ### Aqui não pode ser usado o "return" diretamente porque iria finalizar o loop "while"
		else # $? == 1
			false;
		fi
	done
}

get_folder_paths()
{
	if [ -z $* ] # se nenhum parâmetro foi passado para o programa, no caso, "$HOME" do /usr/bin/quick-deb-builder
	then
		package_path_tmp=$(yad --title "$APP_NAME" --form --center --width=500 --image="package" --window-icon="package" --icon-name="package" --text "<b>Folder selection for DEB creating</b>\n\n$HELP_DESCRIPTION_TEXT\n\n" --field 'Folder path to build tree\:':DIR $HOME --field 'Folder path to output .deb package\:':DIR $HOME --borders=5 --button=About:"./quick-deb-builder-helper.sh about" --button=Cancel:"./quick-deb-builder-helper.sh cancel" --button=OK:0)
	else
		package_path_tmp=$(yad --title "$APP_NAME" --form --center --width=500 --image="package" --window-icon="package" --icon-name="package" --text "<b>Folder selection for DEB creating</b>\n\n$HELP_DESCRIPTION_TEXT\n\n" --field 'Folder path to build tree\:':DIR $1 --field 'Folder path to output .deb package\:':DIR $1 --borders=5 --button=About:"./quick-deb-builder-helper.sh about" --button=Cancel:"./quick-deb-builder-helper.sh cancel" --button=OK:0)
	fi
		process_return_cancel_button;
	local returnCode=$?; # Armazena o return (variável "?") para retornar depois (variável local)
	echo "$package_path_tmp"; # "return"
	package_path_tmp=""; # "Desaloca" variável bash
	return $returnCode;
}

validate_deb_package()
{
	format_folder_paths "$1";
	if verify_deb_structure # Se o caminho passado é válido
	then
		return 0;
	else
		dialog_invalid_folder;
		return 1; # Faz o while ter +1 iteração
	fi
}

format_folder_paths()
{
	old_IFS=$IFS;
	IFS=$'|'; # define separador (barra vertical) para array
	PACKAGE_PATHS=($(echo "$1")); # array / variável GLOBAL
	IFS=$old_IFS;
	#echo "Depois: ${PACKAGE_PATHS[0]} ${PACKAGE_PATHS[1]}";
}

dcreate() # Procedimento de criação do pacote deb com resolução de problemas de permissão de arquivos e pastas
{
	NUM_STEPS=17; # INFORME o NÚMERO de passos que o script executará para o indicador da barra de progresso
	# * "2>/tmp/quick-deb-builder.log": Escreve a saída de erro (stderr) do comando para um arquivo de log

	# Passo 1: Copiando pasta para empacotamento para a pasta temporária (/tmp/)

	generateProgressNum; # Porcentagem de progresso na janela
	echo "# Copying files to the temporary folder"; # Texto da janela (começa com '# ')
	2>/tmp/quick-deb-builder.log cp -R "${PACKAGE_PATHS[0]}" /tmp/deb_packing; # Copia a pasta do pacote para a pasta temporária
		verify_installation_process_sucess;

	# Passo 2: Verificando existência de arquivos executáveis (mimetype "aplication/...") na pasta

	generateProgressNum;
	echo "# Checking existence of executable files in the folder";
	local executable_files_tmp=$(2>/tmp/quick-deb-builder.log find /tmp/deb_packing -type f -exec mimetype {} + | awk -F': +' '{ if ($2 ~ /^application\//) print $1 }') # Lista todos os arquivos executáveis (mimetype "aplication/...") da pasta pra variável local
		verify_installation_process_sucess;

	# Passo 3: Verificando existência de arquivos não-executáveis (mimetype != "aplication/...") na pasta

	generateProgressNum;
	echo "# Checking existence of non-executable files in the folder";
	local non_executable_files_tmp=$(2>/tmp/quick-deb-builder.log find /tmp/deb_packing -type f -exec mimetype {} + | awk -F': +' '{ if ($2 !~ /^application\//) print $1 }') # Lista todos os arquivos não-executáveis (mimetype != "aplication/...") da pasta pra variável local
		verify_installation_process_sucess;

	# Passo 4: Listando todos os arquivos executáveis para "array"

	generateProgressNum;
	echo "# Listing all files in the folder";

	old_IFS=$IFS; # IFS: Processa string de variáveis com separador definido para variável "array"
	IFS=$'\n'; # define separador (quebra de linha) para array
	executable_files=($(echo "$executable_files_tmp")); # array / variável GLOBAL
	non_executable_files=($(echo "$non_executable_files_tmp"));
	IFS=$old_IFS;

	# Passo 5: Modificando as permissões de arquivos executáveis

	generateProgressNum;
	echo "# Modifying permissions of executable files";
	2>/tmp/quick-deb-builder.log echo "${executable_files[*]}" | xargs chmod 0755; # Dá permissões rwxr-xr-x para todos os arquivos executáveis
		verify_installation_process_sucess;

	# Passo 6: Modificando as permissões de arquivos não executáveis

	generateProgressNum;
	echo "# Modifying permissions of non-executable files";
	2>/tmp/quick-deb-builder.log echo "${non_executable_files[*]}" | xargs chmod 0644; # Dá permissões rw-r--r-- para todos os arquivos não-executáveis # xargs: "saída padrão" de um comando são os "argumentos" do outro comando
		verify_installation_process_sucess;

	# Passo 7: Modificando as permissões do diretório de controle do pacote deb

	generateProgressNum;
	echo "# Modifying permissions of the files in DEBIAN directory";
	2>/tmp/quick-deb-builder.log chmod -R 0755 /tmp/deb_packing/DEBIAN/ || 2>/tmp/quick-deb-builder.log chmod -R 0755 /tmp/deb_packing/debian/; # Dá permissões rwxr-xr-x para pasta debian # xargs: "saída padrão" de um comando são os "argumentos" do outro comando
		verify_installation_process_sucess;

	#### Os 6 próximos passos não precisam de gerar log, são comandos de busca por arquivos não obrigatórios no pacote:
	# Passo 8: Verificando e modificando as permissões do arquivo md5sums na pasta de controle do pacote deb

	generateProgressNum;
	echo "# Verifying and modifying permissions of the md5sums file";
	2>/dev/null chmod 0644 /tmp/deb_packing/DEBIAN/md5sums || 2>/dev/null chmod 0644 /tmp/deb_packing/debian/md5sums; # Dá permissões rw-r--r-- para o arquivo "md5sums" na pasta "DEBIAN"

	# Passo 9: Verificando e modificando as permissões dos arquivos de sudoers na pasta

	generateProgressNum;
	echo "# Verifying and modifying permissions of files in the sudoers folder";
	2>/dev/null find /tmp/deb_packing/etc/sudoers.d/ -type f -exec chmod 0440 {} \; # Dá permissões r--r----- para todos os arquivos que estiverem na pasta /etc/sudoers.d, caso existam

	# Passo 10: Verificando e modificando as permissões dos arquivos de documentação na pasta

	generateProgressNum;
	echo "# Verifying and modifying permissions of documentation files in the folder";
	2>/dev/null find /tmp/deb_packing/usr/share/doc/ -type f | xargs chmod 644; # Retira permissões de execução (x) para todos os arquivos relacionados à documentação do software /tmp/deb_packing/usr/share/man/ 

	# Passo 11: Verificando e modificando as permissões dos arquivos de manual na pasta

	generateProgressNum;
	echo "# Verifying and modifying permissions of man files in the folder";
	2>/dev/null find /tmp/deb_packing/usr/share/man/ -type f | xargs chmod 644; # Retira permissões de execução (x) para todos os arquivos relacionados à manuais de usuário (man files)

	# Passo 12: Verificando e modificando as permissões dos arquivos .xml

	generateProgressNum;
	echo "# Verifying and modifying permissions of .xml files";
	2>/dev/null find /tmp/deb_packing -type f -name "*.xml" | xargs chmod -x; # Retira permissões de execução (x) para todos os arquivos ".xml"

	# Passo 13: Verificando e modificando as permissões dos arquivos .desktop

	generateProgressNum;
	echo "# Verifying and modifying permissions of .desktop files";
	2>/dev/null find /tmp/deb_packing -type f -name "*.desktop" | xargs chmod -x; # Retira permissões de execução (x) para todos os arquivos ".desktop" (lançadores de aplicativos)

	# Passo 14: Colocando permissões de executável (+x) para arquivos executáveis nas pastas "(...)/bin"

	generateProgressNum;
	echo "# Modifying permissions of files in 'bin' folders";
	2>/dev/null chmod -R 0755 /tmp/deb_packing/usr/bin /tmp/deb_packing/usr/local/bin /tmp/deb_packing/usr/local/sbin /tmp/deb_packing/usr/sbin /tmp/deb_packing/sbin /tmp/deb_packing/bin /tmp/deb_packing/usr/games /tmp/deb_packing/usr/local/games; # Dá permissões rwxr-xr-x para todos os arquivos que estiverem em pastas de executáveis (caso existam)

	####

	# Passo 15: Empacotando arquivos

	generateProgressNum;
	echo "# Packaging files";
	DPKG_DEB_OUTPUT=$(2>/tmp/quick-deb-builder.log dpkg-deb -b /tmp/deb_packing "${PACKAGE_PATHS[1]}"); # sudo / o arquivo .deb vai estar com o "root" como proprietário do arquivo
		verify_installation_process_sucess;

	# Passo 16: Mudando proprietário do arquivo .deb de "root" para usuário atual

	generateProgressNum;
	echo "# Changing owner of the .deb file";
	2>/tmp/quick-deb-builder.log echo ${DPKG_DEB_OUTPUT//\'/\"} | cut -d'"' -f4 | sed 's/ \+/\\ /g' | xargs chown "$CURRENT_USER":; # Imprime a saída do dpkg-deb trocando aspas simples ('') por aspas duplas ("") | Corta o texto para pegar apenas o caminho do .deb | Adiciona barra invertida (\) onde tiver espaço ( ) | muda o proprietário do arquivo
		verify_installation_process_sucess;

	# Passo 17: Removendo arquivos temporários

	generateProgressNum;
	echo "# Removing temporary files";
	2>/tmp/quick-deb-builder.log rm -R /tmp/deb_packing; # exclui pasta temporária
		verify_installation_process_sucess;
}

create_deb_package()
{
	dcreate | 
	yad --progress \
	--center --auto-close --no-buttons --on-top \
	--title="$APP_NAME" \
	--text="Building deb package..." \
	--width=420 --borders=5; #--percentage=0
}

#### FUNÇÕES AUXILIARES DO QUICK-DEB-BUILDER ####

function generateProgressNum() # Função para gerar o número do progresso da instalação (de acordo com o número de passos informado)
{
	if [ -z "$CURRENT_STEP" ]
	then
		CURRENT_STEP=0; # Apenas inicialização
	fi
	if [ -z "$1" ] # Nenhum parâmetro foi passado
	then
		CURRENT_STEP=$((CURRENT_STEP+1)); # Incrementa passo atual antes do cálculo

		# Fórmula geral para calcular o percentual da barra de progresso:
		STEP=$(((CURRENT_STEP*100)/NUM_STEPS));
		if [ "$STEP" == "100" ] # Porque o zenity se fecha automaticamente quando a barra de progresso atinge 100%
		then
			STEP=99;
		fi
		echo $STEP; # return STEP;
	else # Precisa passar 2 parâmetros: 
		N=$1; # Sub-passo atual
		T=$2; # Total de sub-passos

		# Fórmula específica para calcular o percentual da barra de progresso em sub-passos (usado em estruturas de repetição):
		STEP=$((((CURRENT_STEP*100)/NUM_STEPS)+(N*10/T+1)));
		if [ "$STEP" == "100" ] # Porque o zenity se fecha automaticamente quando a barra de progresso atinge 100%
		then
			STEP=99;
		fi
		echo $STEP; # return STEP;
	fi
}

process_return_cancel_button()
{
	local returnCode=$?;
	if [ "$returnCode" == "143" ] # O "yad" foi morto pelo helper ("killall")
	then
		return 50; # vai para o "verifyReturnCode" e este finaliza o programa
	elif [ "$returnCode" == "252" ] # O "yad" foi fechado usando as funções da janela para fechar o diálogo (padrão do "yad")
	then
		return 1; # Para entrar na função "verifyReturnCode" e abrir a janela de confirmação de fechamento do "helper"
	else #elif[ "$returnCode" == "0" ] # O "yad" saiu normalmente
		return 0;
	fi 

}

verifyReturnCode()
{
	local returnCode=$?;
	if [ "$returnCode" == "50" ] # Se o RETURN CODE já é 50
	then # Significa que o usuário está querendo sair do programa apertando o botão Cancel, o "yad" abriu o helper e o usuário apertou "Yes" para fechar
		exit;
	elif [ "$returnCode" == "0" ] # o usuário não quer sair (apertou o botão OK da janela principal)
	then # o programa continua
		return 0;
	else
		./quick-deb-builder-helper.sh safe-exit # Abre janela de confirmação se quer mesmo fechar o programa
		if [ "$?" == "50" ] # Usuário apertou o botão de confirmação "Yes" para fechar
		then # o usuário quer sair
			exit;
		else # o usuário não quer sair (retornou "100")
			return 1; # return 1
		fi
	fi
}

verify_installation_process_sucess()
{
	if [ "$?" != "0" ]
	then
		dialog_deb_creation_error;
		rm -f /tmp/quick-deb-builder.log; # Exclui o arquivo de log
		rm -R -f /tmp/deb_packing; # Exclui a pasta temporária 
		exit 1; # Este "exit" NÃO vai finalizar o script inteiro pois ele vai ser chamado em subshell
	fi
}

verify_deb_structure()
{
	if find "${PACKAGE_PATHS[0]}/DEBIAN" > /dev/null || find "${PACKAGE_PATHS[0]}/debian" > /dev/null
	then
		ISTHERE_DEBIAN_FOLDER=$true; # echo "A pasta DEBIAN existe!";
	else
		ISTHERE_DEBIAN_FOLDER=$false; # echo "A pasta DEBIAN NÃO existe!";
	fi

	if find "${PACKAGE_PATHS[0]}/DEBIAN/control" > /dev/null || find "${PACKAGE_PATHS[0]}/debian/control" > /dev/null
	then
		ISTHERE_CONTROL_FILE=$true; # echo "O arquivo de controle existe!";
	else
		ISTHERE_CONTROL_FILE=$false; # echo "O arquivo de controle NÃO existe."
	fi

	if [ $ISTHERE_DEBIAN_FOLDER -eq $true ]	&& [ $ISTHERE_CONTROL_FILE -eq $true ]
	then
		return 0; # É um pacote deb válido
	else
		return 1; # Não é um pacote deb válido
	fi
}

dialog_invalid_folder()
{
	yad --title "$APP_NAME" --error --center --width=350 --image="error" --window-icon="package" --icon-name="package" --text "<big><b>Invalid folder, try again.</b></big>" --text-align=center --button="OK:0";
}

dialog_deb_creation_error()
{
	cat /tmp/quick-deb-builder.log | yad --title "$APP_NAME" --text-info --center --width=500 --image="error" --window-icon="package" --icon-name="package" --text "<big><b>An unexpected error occured in creating .deb package.</b></big>\n\nLog of the error:" --button="OK:0";
}

dialog_deb_creation_sucess()
{
	yad --title "$APP_NAME" --info --center --width=350 --image="package" --window-icon="package" --icon-name="package" --text "<b>DEB package created sucessfully.</b>" --text-align=center --button="OK:0";
}

generateReturnCode()
{
	return $1;
}

main $@; # Repassa os parâmetros de linha de comando para a função
