#! /bin/bash

# Author: Gustavo Moraes <gustavomdsantos@pm.me>
#
# This file is subject to the terms and conditions of the GNU General Public
# License. See the file COPYING in the main directory of this archive
# for more details.

#set -u; # Bash will exit the script if you try to use an uninitialised variable

APP_NAME="Quick DEB Builder"
VERSION="$(./quick-deb-builder-get-version.sh)"
APP_AUTHOR="Copyright (C) 2015-2025 Gustavo Moraes https://github.com/gustavomdsantos"
HELP_DESCRIPTION_TEXT="Select a folder path with a \"debian-like\" directory structure and an output folder path and press OK below:"
CURRENT_USER="$2" # $2 - Parâmetro que o "../bin/quick-deb-builder" sempre passa para este (executado como root a variável "$USER" == "root")
true=1; false=0; # boolean

# Função que começa a execução do programa.
# Parâmetros (que o '/usr/bin/quick-deb-builder' passa):
# 	$1=$HOME - Caminho da pasta inicial do usuário comum (não root - $HOME)
#	$2=$USER - Nome do usuário comum
#	$3=$OPTION - Opções informativas do programa (--version, --help, -h)
# OU
#	$3=$INPUT_PATH - Pasta de origem (source do software) a ser criado o pacote deb
#	$4=$OUTPUT_PATH - Pasta de destino do pacote deb
init()
{
	if [ -d "$3" ] && [ -d "$4" ] # Se os dois parâmetros existem e são caminhos de arquivo válidos
	then # O usuário quer usar o 'quick-deb-builder' em linha de comando (CLI)
		USER_INTERFACE="CLI"; # define "linha de comando" como forma de interface com o usuário no programa
		main_CLI "$3" "$4";
	else
		case "$3" in
			"-h"|"--help" )
				./quick-deb-builder-helper.sh --help;; # Esse "--help" é DIFERENTE de "about", este último abre uma janela em GUI!
			"--version" )
				./quick-deb-builder-helper.sh --version;; # Exibe a versão do programa
			*)
				USER_INTERFACE="GUI"; # define "interface gráfica" como forma de interface com o usuário no programa
				main_GUI "$1";; # Executa as funcionalidades principais do programa em GUI
		esac
	fi
}

# Função principal do programa, em interface gráfica (GUI).
# Parâmetros:
# 	$1 - Caminho da pasta inicial do usuário comum (não root - $HOME)
main_GUI()
{
	verify_GUI;

	false; # Para entrar no while
	while [ $? -ne 0 ] # Enquanto a saída do último comando não for igual a ZERO (return =! 0)
	do
		define_deb_IO_folder_paths_GUI "$1";
		(create_deb_package_GUI); # Existe um "exit" que pode ser executado dentro da função; para não finalizar o script inteiro, a função é executada em subshell: "(" + código + ")"
	done
	dialog_deb_building_sucess;
}

# Função principal do programa, em interface de linha de comando (CLI).
# Parâmetros:
#	$1=$INPUT_PATH - Pasta de origem (source do software) a ser criado o pacote deb
#	$2=$OUTPUT_PATH - Pasta de destino do pacote deb
main_CLI()
{
	local INPUT_PATH="$1";
	local OUTPUT_PATH="$2";
	local CHOSEN_OPTION;
	echo -e "\n$APP_NAME $VERSION - ${APP_AUTHOR:0:33}\n";

	echo "The following folder paths will be used for building a new DEB PACKAGE:"
	echo -e "\nInput (source files): \n  $INPUT_PATH";
	echo -e "Output (deb file destination): \n  $OUTPUT_PATH\n";

	echo -n "Do you want to continue? [Y/n] "
	read CHOSEN_OPTION;
	shopt -s nocasematch; # Para o case aceitar tanto maiúsculas como minúsculas (NO Case Sensitive)
	case "$CHOSEN_OPTION" in
		"Y" )
			define_deb_IO_folder_paths_CLI "$INPUT_PATH|$OUTPUT_PATH";
			create_deb_package_CLI;; # Existe um "exit" ("exception") que pode ser executado nessa função; ele PODE finalizar o script inteiro (NÃO está em subshell)!
		"N" )
			echo "Abort.";
			exit 1;; # Fecha o programa
		*) # default
			>&2 echo "Invalid option.";;
	esac
	dialog_deb_building_sucess;
	shopt -u nocasematch; # "Desliga" a função No Case Sensitive
}

# Função que verifica a execução do aplicativo em interface gráfica.
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

# Função que define a pasta de origem e destino para a criação do pacote deb.
# Parâmetros:
# 	$1 - Caminho da pasta inicial do usuário comum (não root - $HOME)
define_deb_IO_folder_paths_GUI()
{
	false; # Para entrar no while
	while [ $? -ne 0 ] # Enquanto a saída do último comando não for igual a ZERO (return =! 0)
	do
		package_path_tmp2=$(get_folder_paths "$1"); # Cria uma string no formato "/pasta/entrada|/pasta/saida|"
			verifyReturnCode;
		if [ "$?" != "1" ] # Se o usuário não quer sair do programa
		then
			validate_deb_package "$package_path_tmp2"; # Se os arquivos estão prontos para serem empacotados (arquivos corretos)
			local returnCode=$?;
			package_path_tmp2=""; # "Desaloca" variável bash
			generateReturnCode $returnCode; ### Aqui não pode ser usado o "return" diretamente porque iria finalizar o loop "while"
		else # $? == 1
			false; # Faz o "while" ter mais 1 iteração
		fi
	done
}

# Função que define a pasta de origem e destino para a criação do pacote deb.
# Parâmetros:
# 	$1 - Caminho da pasta de origem e destino do pacote deb (no formato /pasta/entrada|/pasta/saida|")
define_deb_IO_folder_paths_CLI()
{
	if validate_deb_package "$1" # Se os arquivos estão prontos para serem empacotados (arquivos corretos)
	then
		return 0; # passa para a próxima função no "main_CLI"
	else
		exit 1; # return que fecha o programa
	fi
}

# Função que abre uma janela na interface gráfica para o usuário selecionar a pasta desejada para criar o pacote deb e a pasta aonde colocar o pacote deb criado.
# Parâmetros:
# 	$* - Caminho da pasta inicial do usuário comum (não root - $HOME)
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

# Função que verifica a validade da pasta escolhida pelo usuário para a criação do pacote deb.
# Parâmetros:
# 	$1 - String de saída do "yad", que contém o caminho da pasta de origem e destino do pacote deb (no formato /pasta/entrada|/pasta/saida|")
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

# Função que processa a string de saída do "yad" (no formato /pasta/entrada|/pasta/saida|") em um array de strings.
# Parâmetros:
# 	$1 - String de saída do "yad", que contém o caminho da pasta de origem e destino do pacote deb (no formato /pasta/entrada|/pasta/saida|")
# Saída:
# 	${PACKAGE_PATHS[*]} - Array de strings com o caminho da pasta de origem e destino do pacote deb
format_folder_paths()
{
	old_IFS=$IFS;
	IFS=$'|'; # define separador (barra vertical) para array
	PACKAGE_PATHS=($(echo "$1")); # array / variável GLOBAL
	IFS=$old_IFS;
	#echo "Depois: ${PACKAGE_PATHS[0]} ${PACKAGE_PATHS[1]}";
}

# Função que inicia o procedimento de criação do pacote deb com resolução de problemas de permissão de arquivos e pastas. 
# O progresso é mostrado em um janela gráfica com barra de progresso.
create_deb_package_GUI()
{
	dcreate | 
	yad --progress \
	--center --auto-close --no-buttons --on-top \
	--title="$APP_NAME" \
	--text="Building deb package..." \
	--width=420 --borders=5; #--percentage=0
	return $PIPESTATUS; # retorna o EXIT CODE do dcreate
}

# Função que inicia o procedimento de criação do pacote deb com resolução de problemas de permissão de arquivos e pastas. 
# O progresso é mostrado em interface de texto com indicador de porcentagem de progresso.
create_deb_package_CLI()
{
	dcreate;
}

# Procedimento que cria pacotes deb. Função mais importante de todo o aplicativo.
# Arquivos criados:
# 	'/tmp/quick-deb-builder.log' - Arquivo temporário de log do programa. Todo erro durante o procedimento tem sua mensagem (stderr) redirecionada para esse arquivo;
# 	Um arquivo '*.deb', na pasta informada pelo usuário anteriormente;
# 	'/tmp/quick-deb-builder.file' - Arquivo temporário que armazena o caminho do pacote deb criado pelo "dpkg-deb" (por causa que esta função sempre é executada em "subshell", as variáveis globais criadas nela não são acessíveis para o seu "supershell").
dcreate()
{
	NUM_STEPS=20; # INFORME o NÚMERO de passos que o script executará para o indicador da barra de progresso
	# * "2>>/tmp/quick-deb-builder.log": Escreve a saída de erro (stderr) do comando para um arquivo de log

	# Passo 1: Copiando pasta para empacotamento para a pasta temporária (/tmp/)

	generateProgressNum; # Porcentagem de progresso na janela e um "# ", caso seja uma GUI esteja sendo usada
	echo "Copying files to the temporary folder"; # Texto da janela (começa com '# ')
	2>>/tmp/quick-deb-builder.log cp -R "${PACKAGE_PATHS[0]}" /tmp/deb_packaging; # Copia a pasta do pacote para a pasta temporária
		verify_deb_creating_process_sucess;

	# Passo 2: Listando todos os arquivos na pasta
	generateProgressNum; # Porcentagem de progresso na janela e um "#", caso seja uma GUI esteja sendo usada
	echo "Listing all files"; # Texto da janela (começa com '# ')
	list_all_files; # cria a variável do tipo "array": "${ALL_FILES[*]}"
		verify_deb_creating_process_sucess;

	# Passo 3: Verificando existência de arquivos executáveis (mimetype "aplication/...") na pasta

	generateProgressNum;
	echo "Checking existence of executable files in the folder";
	list_executable_files; # cria a variável do tipo "array": "${EXECUTABLE_FILES[*]}"
		verify_deb_creating_process_sucess;

	# Passo 4: Verificando existência de arquivos não-executáveis (mimetype != "aplication/...") na pasta

	generateProgressNum;
	echo "Checking existence of non-executable files in the folder";
	list_non_executable_files; # cria a variável do tipo "array": "${NON_EXECUTABLE_FILES[*]}"
		verify_deb_creating_process_sucess;

	# Passo 5: Modificando as permissões de arquivos executáveis

	generateProgressNum;
	echo "Modifying permissions of executable files";
	if [ -n "$EXECUTABLE_FILES" ] # Se a variável "EXECUTABLE_FILES" NÃO é nula
	then
		echo "${EXECUTABLE_FILES[*]}" | xargs chmod 0755 2>>/tmp/quick-deb-builder.log; # Dá permissões rwxr-xr-x para todos os arquivos executáveis
			verify_deb_creating_process_sucess;
	fi

	# Passo 6: Modificando as permissões de arquivos não executáveis

	generateProgressNum;
	echo "Modifying permissions of non-executable files";
	if [ -n "$NON_EXECUTABLE_FILES" ] # Se a variável "NON_EXECUTABLE_FILES" NÃO é nula
	then
		echo "${NON_EXECUTABLE_FILES[*]}" | xargs chmod 0644 2>>/tmp/quick-deb-builder.log; # Dá permissões rw-r--r-- para todos os arquivos não-executáveis # xargs: "saída padrão" de um comando são os "argumentos" do outro comando
			verify_deb_creating_process_sucess;
	fi

	#### Os 6 próximos passos não precisam de gerar log, são comandos de busca por arquivos não obrigatórios no pacote:

	# Passo 7: Verificando e modificando as permissões do diretório de temas do "BURG bootloader"
	generateProgressNum;
	echo "Verifying and modifying permissions of the BURG bootloader themes directory";
	2>/dev/null find /tmp/deb_packaging/boot/burg/themes/ -type d | xargs chmod 755 2>/dev/null; # Dá permissões rwxr-xr-x para a pasta themes e seus subdiretórios

	# Passo 8: Verificando e modificando as permissões dos arquivos de sudoers na pasta

	generateProgressNum;
	echo "Verifying and modifying permissions of files in the sudoers folder";
	2>/dev/null find /tmp/deb_packaging/etc/sudoers.d/ -type f -exec chmod 0440 {} \; # Dá permissões r--r----- para todos os arquivos que estiverem na pasta /etc/sudoers.d, caso existam

	# Passo 9: Verificando e modificando as permissões dos arquivos de documentação na pasta

	generateProgressNum;
	echo "Verifying and modifying permissions of documentation files in the folder";
	2>/dev/null find /tmp/deb_packaging/usr/share/doc/ -type f | xargs chmod 644 2>/dev/null; # Retira permissões de execução (x) para todos os arquivos relacionados à documentação do software /tmp/deb_packaging/usr/share/man/ 

	# Passo 10: Verificando e modificando as permissões dos arquivos de manual na pasta

	generateProgressNum;
	echo "Verifying and modifying permissions of man files in the folder";
	2>/dev/null find /tmp/deb_packaging/usr/share/man/ -type f | xargs chmod 644 2>/dev/null; # Retira permissões de execução (x) para todos os arquivos relacionados à manuais de usuário (man files)

	# Passo 11: Verificando e modificando as permissões de arquivos com mimetype "text/x-python" (arquivo executável Python sem permissão de execução)

	generateProgressNum;
	echo "Verifying and modifying permissions of Python files";
	2>/dev/null echo "`find /tmp/deb_packaging -type f -exec mimetype {} + | awk -F': +' '{ if ($2 ~ /^text\/x-python/) print $1 }'`" | xargs chmod 755 2>/dev/null; # Lista todos os arquivos não-executáveis (mimetype != "aplication/...") da pasta pra variável local

	# Passo 11: Verificando e modificando as permissões dos arquivos .xml

	generateProgressNum;
	echo "Verifying and modifying permissions of .xml files";
	chmod_all_by_extension xml -x; # Retira permissões de execução (x) para todos os arquivos ".xml"

	# Passo 13: Verificando e modificando as permissões dos arquivos .html

	generateProgressNum;
	echo "Verifying and modifying permissions of .html files";
	chmod_all_by_extension html -x; # Retira permissões de execução (x) para todos os arquivos ".html"

	# Passo 14: Verificando e modificando as permissões dos arquivos .desktop

	generateProgressNum;
	echo "Verifying and modifying permissions of .desktop files";
	chmod_all_by_extension desktop -x; # Retira permissões de execução (x) para todos os arquivos ".desktop" (lançadores de aplicativos)

	# Passo 15: Colocando permissões de executável (+x) para arquivos executáveis nas pastas "(...)/bin"

	generateProgressNum;
	echo "Modifying permissions of files in 'bin' folders";
	2>/dev/null chmod -R 0755 /tmp/deb_packaging/usr/bin /tmp/deb_packaging/usr/local/bin /tmp/deb_packaging/usr/local/sbin /tmp/deb_packaging/usr/sbin /tmp/deb_packaging/sbin /tmp/deb_packaging/bin /tmp/deb_packaging/usr/games /tmp/deb_packaging/usr/local/games; # Dá permissões rwxr-xr-x para todos os arquivos que estiverem em pastas de executáveis (caso existam)

	#### FIM DA BUSCA ####

	# Passo 16: Modificando as permissões do diretório de controle do pacote deb

	generateProgressNum;
	echo "Modifying permissions of the files in DEBIAN directory";
	2>>/tmp/quick-deb-builder.log chmod -R 0755 /tmp/deb_packaging/"$DEBIAN_FOLDER_ALIAS"; # Dá permissões rwxr-xr-x para pasta debian # xargs: "saída padrão" de um comando são os "argumentos" do outro comando
		verify_deb_creating_process_sucess;

	# Passo 17: Criar arquivo md5sums
	generateProgressNum;
	echo "Creating md5sums file";
	2>>/tmp/quick-deb-builder.log find /tmp/deb_packaging -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -print0 | 2>>/tmp/quick-deb-builder.log xargs -0 md5sum > /tmp/deb_packaging/"$DEBIAN_FOLDER_ALIAS"/md5sums; # Cria o arquivo md5sums
		verify_deb_creating_process_sucess;
	local md5sums_file=$(cat /tmp/deb_packaging/"$DEBIAN_FOLDER_ALIAS"/md5sums); # Abre o arquivo "md5sums" para uma variável local
	echo "${md5sums_file//\/tmp\/deb_packaging\//}" > /tmp/deb_packaging/"$DEBIAN_FOLDER_ALIAS"/md5sums; # Retira os "/tmp/deb_packaging" do "md5sums"
	2>/dev/null chmod 0644 /tmp/deb_packaging/"$DEBIAN_FOLDER_ALIAS"/md5sums; # Dá permissões rw-r--r-- para o arquivo "md5sums" na pasta "DEBIAN"

	# Passo 18: Empacotando arquivos

	generateProgressNum;
	echo "Packaging files";
	DPKG_DEB_OUTPUT=$(2>>/tmp/quick-deb-builder.log dpkg-deb -b /tmp/deb_packaging "${PACKAGE_PATHS[1]}"); # sudo / o arquivo .deb vai estar com o "root" como proprietário do arquivo
		verify_deb_creating_process_sucess;

	# Passo 19: Mudando proprietário do arquivo .deb de "root" para usuário atual

	generateProgressNum;
	echo "Changing owner of the .deb file";
	DEB_PACKAGE_CREATED_FILENAME=$(echo ${DPKG_DEB_OUTPUT//\'/\"} | cut -d'"' -f4);
	1>/tmp/quick-deb-builder.file echo "$DEB_PACKAGE_CREATED_FILENAME"; # quick-deb-builder.file armazena o caminho do arquivo .deb criado (para uso na função "dialog_deb_building_sucess") # Isso foi necessário porque esta função é executada em subshell - as variáveis criadas aqui não são visíveis para seu "supershell"
	2>>/tmp/quick-deb-builder.log chown "$CURRENT_USER": "$DEB_PACKAGE_CREATED_FILENAME"; # Imprime a saída do dpkg-deb trocando aspas simples ('') por aspas duplas ("") | Corta o texto para pegar apenas o caminho do .deb | Adiciona barra invertida (\) onde tiver espaço ( ) | muda o proprietário do arquivo
		verify_deb_creating_process_sucess;

	# Passo 20: Removendo arquivos temporários

	generateProgressNum;
	echo "Removing temporary files";
	2>>/tmp/quick-deb-builder.log rm -R /tmp/deb_packaging; # exclui pasta temporária
		verify_deb_creating_process_sucess;
}

# Função que informa ao usuário o sucesso do procedimento de criação do pacote deb.
dialog_deb_building_sucess()
{
	local DEB_PACKAGE_CREATED_FILENAME=$(cat /tmp/quick-deb-builder.file); # Lê o nome do arquivo .deb criado (armazenado em arquivo)
	if [ "$USER_INTERFACE" == "GUI" ]
	then
		show_deb_building_sucess_GUI "$DEB_PACKAGE_CREATED_FILENAME";
	elif [ "$USER_INTERFACE" == "CLI" ]
	then
		show_deb_building_sucess_CLI "$DEB_PACKAGE_CREATED_FILENAME";
	fi
	remove_temp_files;
}

# Função que exibe uma janela em interface gráfica informando o sucesso do procedimento de criação do pacote deb.
# Parâmetros:
#	$1 - o nome do arquivo .deb criado pelo Quick DEB Builder.
show_deb_building_sucess_GUI()
{
	yad --title "$APP_NAME" --info --center --width=350 --image="package" --window-icon="package" --icon-name="package" --text "<b>DEB package created sucessfully.</b>\n\nName of the created package:\n<tt>$1</tt>\n\n Do you want to open the package?" --text-align=center --button="No:1" --button="Yes:0";
	if [ "$?" == "0" ]
	then
		xdg-open "$DEB_PACKAGE_CREATED_FILENAME";
	fi
}

# Função que exibe uma janela em interface de texto informando o sucesso do procedimento de criação do pacote deb.
# Parâmetros:
#	$1 - o nome do arquivo .deb criado pelo Quick DEB Builder.
show_deb_building_sucess_CLI()
{
	local CHOSEN_OPTION;
	echo -n -e "\nDEB package created sucessfully.\n\nName of the created package:\n $1 \nDo you want to open the package? [Y/n] ";
	read CHOSEN_OPTION;
	case "$CHOSEN_OPTION" in
	"Y" )
		gdebi "$DEB_PACKAGE_CREATED_FILENAME" || dpkg -i "$DEB_PACKAGE_CREATED_FILENAME";; # Executa o "gdebi" ou o "dpkg" para instalar o pacote deb.
	"N" )
		echo "Exiting.";;
	*) # default
		>&2 echo "Invalid option.";;
	esac
}

#### FUNÇÕES AUXILIARES DO QUICK-DEB-BUILDER ####

# Função que gera o número do progresso do procedimento de criação do pacote deb (de acordo com o número de passos informado)
# Parâmetros:
# 	$NUM_STEPS (variável GLOBAL) - o número total de passos do procedimento (100%)
# Saída:
# 	$CURRENT_STEP (variável GLOBAL) - o número do passo atual (em '%' - porcentagem)
generateProgressNum()
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
		printStepNum; # imprime o passo atual
	else # Precisa passar 2 parâmetros: 
		N=$1; # Sub-passo atual
		T=$2; # Total de sub-passos

		# Fórmula específica para calcular o percentual da barra de progresso em sub-passos (usado em estruturas de repetição):
		STEP=$((((CURRENT_STEP*100)/NUM_STEPS)+(N*10/T+1)));
		if [ "$STEP" == "100" ] # Porque o zenity se fecha automaticamente quando a barra de progresso atinge 100%
		then
			STEP=99;
		fi
		printStepNum; # imprime o passo atual
	fi
}

# Imprime o número em porcentagem do passo atual do processo de construção do pacote deb, dependendo da UI usada no momento.
# Parâmetros:
#	$USER_INTERFACE - a interface de usuário usada no sistema ("GUI" ou "CLI").
#	$STEP (variável GLOBAL) - o número do passo atual (em '%' - porcentagem).
printStepNum()
{
	if [ "$USER_INTERFACE" == "GUI" ]
	then
		echo $STEP; # return STEP;
		echo -n "# "; # Indicador do YAD de que é um texto que é para ser exibido na janela de progresso (dentro do "dcreate")
	elif [ "$USER_INTERFACE" == "CLI" ]
	then
		echo -n "[$STEP%] ";
	else
		echo ""
	fi
}

# Função que faz o processamento das interações do usuário em relação ao fechamento do programa (botão "Cancel" ou botão padrão "X" das janelas).
# Parâmetros:
# 	$? - EXIT CODE do último comando executado ("yad")
# Saída:
# 	EXIT CODE apropriado para o momento (função "verifyReturnCode")
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

# Função que faz o processamento de todas as possibilidades para o usuário em relação à botões de confirmação.
# Parâmetros:
# 	$? - EXIT CODE do último comando executado ("yad")
# Saída:
# 	EXIT CODE apropriado para cada caso
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

# Função que lista TODOS os arquivos da pasta '/tmp/deb_packaging'.
# Saída:
# 	${ALL_FILES[*]} (variável GLOBAL) - Array de strings com o caminho de todos os arquivos
list_all_files()
{
	local all_files_tmp=$(2>>/tmp/quick-deb-builder.log find /tmp/deb_packaging -type f) # Lista todos os arquivos da pasta pra variável local
	local old_IFS=$IFS; # IFS: Processa string de variáveis com separador definido para variável "array"
	IFS=$'\n'; # define separador (quebra de linha) para array
	local all_files_list=($(echo "$all_files_tmp")); # array temporária / variável LOCAL
	IFS=$old_IFS;

	local counter=0; # contador adicional para o for
	for current_file in "${all_files_list[@]}"
	do
		ALL_FILES[$counter]=$(echo "$current_file" | sed 's/ \+/\\ /g'); # array / variável GLOBAL (sed coloca "\" aonde estiver espaço no caminho do arquivo, para evitar quebra de nome de arquivo)
		counter=$((counter+1));
	done
}

# Função que lista todos os arquivos executáveis (mimetype "aplication/...") da pasta '/tmp/deb_packaging'.
# Saída:
# 	${EXECUTABLE_FILES[*]} (variável GLOBAL) - Array de strings com o caminho de todos os arquivos executáveis
list_executable_files()
{
	local executable_files_tmp=$(2>>/tmp/quick-deb-builder.log find /tmp/deb_packaging -type f -exec mimetype {} + | awk -F': +' '{ if ($2 ~ /^application\//) print $1 }') # Lista todos os arquivos executáveis (mimetype "aplication/...") da pasta pra variável local
	local old_IFS=$IFS; # IFS: Processa string de variáveis com separador definido para variável "array"
	IFS=$'\n'; # define separador (quebra de linha) para array
	local executable_files_list=($(echo "$executable_files_tmp")); # array temporária / variável LOCAL
	IFS=$old_IFS;

	local counter=0; # contador adicional para o for
	for executable_file in "${executable_files_list[@]}"
	do
		EXECUTABLE_FILES[$counter]=$(echo "$executable_file" | sed 's/ \+/\\ /g'); # array / variável GLOBAL (sed coloca "\" aonde estiver espaço no caminho do arquivo, para evitar quebra de nome de arquivo)
		counter=$((counter+1));
	done
}

# Função que lista todos os arquivos não-executáveis (mimetype != "aplication/...") da pasta "/tmp/deb_packaging".
# Saída:
# 	${NON_EXECUTABLE_FILES[*]} (variável GLOBAL) - Array de strings com o caminho de todos os arquivos não executáveis
list_non_executable_files()
{
	local non_executable_files_tmp=$(2>>/tmp/quick-deb-builder.log find /tmp/deb_packaging -type f -exec mimetype {} + | awk -F': +' '{ if ($2 !~ /^application\//) print $1 }') # Lista todos os arquivos não-executáveis (mimetype != "aplication/...") da pasta pra variável local
	local old_IFS=$IFS; # IFS: Processa string de variáveis com separador definido para variável "array"
	IFS=$'\n'; # define separador (quebra de linha) para array
	local non_executable_files_list=($(echo "$non_executable_files_tmp")); # array temporária / variável LOCAL
	IFS=$old_IFS;

	local counter=0; # contador adicional para o for
	for non_executable_file in "${non_executable_files_list[@]}"
	do
		NON_EXECUTABLE_FILES[$counter]=$(echo "$non_executable_file" | sed 's/ \+/\\ /g'); # array / variável GLOBAL (sed coloca "\" aonde estiver espaço no caminho do arquivo, para evitar quebra de nome de arquivo)
		counter=$((counter+1));
	done
}

# Função que modifica permissões de todos os arquivos de uma determinada extensão.
# Parâmetros:
# 	$1 - Extensão dos arquivos
# 	$2 - Tipo de permissão desejada para os arquivos (modelo "chmod")
# Uso:
# 	chmod_all_by_extension [MODE] [EXTENSION]
# 	chmod_all_by_extension [OCTAL-MODE] [EXTENSION]
chmod_all_by_extension()
{
	local mode="$2";
	local extension="$1";
	2>/dev/null printf '%s\n' "${ALL_FILES[@]}" | grep ".$extension" | xargs chmod "$mode" 2>/dev/null; # (`printf '%s\n' "${ALL_FILES[@]}"` imprime cada um dos elementos do array em uma linha)
}

# Função que verifica o sucesso ou falha do comando executado no procedimento de criação do pacote deb.
# Seria equivalente à uma Exception da linguagem Java. Ele exclui os arquivos temporários caso haja alguma falha.
# Parâmetros:
# 	$? - EXIT CODE do último comando executado
verify_deb_creating_process_sucess()
{
	if [ "$?" != "0" ]
	then
		dialog_deb_creation_error;
		rm -f /tmp/quick-deb-builder.log; # Exclui o arquivo de log
		rm -R -f /tmp/deb_packaging; # Exclui a pasta temporária 
		exit 1; # Este "exit" NÃO vai finalizar o script inteiro pois ele vai ser chamado em subshell
	fi
}

# Função que verifica a validade do conteúdo da pasta escolhida pelo usuário à procura dos itens essenciais e obrigatórios 
# para a criação do pacote deb (pasta "DEBIAN" e arquivo "control").
# Parâmetros:
# 	${PACKAGE_PATHS[*]} - Array de strings com o caminho da pasta de origem e destino do pacote deb (será usada apenas o índice 0 na função - origem)
# Retorna:
# 	Um "boolean" - "0" = É um pacote deb válido, "1" = Não é um pacote deb válido
verify_deb_structure()
{
	if find "${PACKAGE_PATHS[0]}/DEBIAN" &> /dev/null # "&>" manda tanto o stdout quanto o stderr para o "Buraco Negro"
	then # O nome da pasta de controle do pacote é "DEBIAN" (maiúsculas)
		DEBIAN_FOLDER_ALIAS="DEBIAN"; # Define variável local com o nome da pasta (será usada nos próximos passos para evitar fazer várias estruturas condicionais)
		local ISTHERE_DEBIAN_FOLDER=$true; # A pasta DEBIAN existe!
	elif find "${PACKAGE_PATHS[0]}/debian" &> /dev/null
	then # O nome da pasta de controle do pacote é "DEBIAN" (minúsculas)
		DEBIAN_FOLDER_ALIAS="debian"; # Define variável local com o nome da pasta (será usada nos próximos passos para evitar fazer várias estruturas condicionais)
		local ISTHERE_DEBIAN_FOLDER=$true; # A pasta DEBIAN existe!
	else
		local ISTHERE_DEBIAN_FOLDER=$false; # A pasta DEBIAN NÃO existe!
	fi

	if find "${PACKAGE_PATHS[0]}/$DEBIAN_FOLDER_ALIAS/control" &> /dev/null
	then
		local ISTHERE_CONTROL_FILE=$true; # O arquivo de controle existe!
	else
		local ISTHERE_CONTROL_FILE=$false; # O arquivo de controle NÃO existe
	fi

	if [ "$ISTHERE_DEBIAN_FOLDER" == "$true" ] && [ "$ISTHERE_CONTROL_FILE" == "$true" ] # Existe a pasta "DEBIAN"? Existe o arquivo de controle?
	then
		return 0; # É um pacote deb válido
	else
		return 1; # Não é um pacote deb válido
	fi
}

# Função que exibe uma janela em interface gráfica informando que a pasta escolhida pelo usuário é inválida.
# Parâmetros:
# 	$APP_NAME (variável GLOBAL) - o nome do aplicativo.
dialog_invalid_folder()
{
	if [ "$USER_INTERFACE" == "GUI" ]
	then
		yad --title "$APP_NAME" --error --center --width=350 --image="error" --window-icon="package" --icon-name="package" --text "<big><b>Invalid folder, try again.</b></big>" --text-align=center --button="OK:0";
	elif [ "$USER_INTERFACE" == "CLI" ]
	then
		echo "Error: Invalid folder, try again."
	fi
}

# Função que exibe uma janela em interface gráfica informando que um erro ocorreu durante o procedimento de criação de pacotes deb.
# Parâmetros:
# 	$APP_NAME (variável GLOBAL) - o nome do aplicativo.
dialog_deb_creation_error()
{
	if [ "$USER_INTERFACE" == "GUI" ]
	then
		cat /tmp/quick-deb-builder.log | yad --title "$APP_NAME" --text-info --center --width=500 --image="error" --window-icon="package" --icon-name="package" --text "<big><b>An unexpected error occured in creating .deb package.</b></big>\n\nLog of the error:" --button="OK:0";
	elif [ "$USER_INTERFACE" == "CLI" ]
	then
		>&2 echo -e "Error: An unexpected error occured in creating .deb package.\nLog of the error:\n";
		>&2 cat /tmp/quick-deb-builder.log;
	fi
	remove_temp_files;
}

# Função que remove os arquivos de log temporários criados durante o procedimento de criação de pacotes deb.
# Ele NÃO remove a pasta temporária "deb_packaging".
remove_temp_files()
{
	rm -f /tmp/quick-deb-builder.log /tmp/quick-deb-builder.file; # remove arquivos temporários
}

# Função que gera um RETURN CODE para a função chamada.
# Parâmetros:
# 	$1 - o número do RETURN CODE desejado para gerar.
generateReturnCode()
{
	return $1;
}

#### MAIN ####

init "$@"; # Repassa os parâmetros de linha de comando para a função
