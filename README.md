[**English**](#english) | [**Português**](#português)

![Quick DEB Builder](http://icons.iconarchive.com/icons/alecive/flatwoken/48/Apps-Package-Debian-icon.png) Quick DEB Builder
============================================================================================================================

[![Stories in Backlog](https://img.shields.io/github/issues-raw/gustavosotnas/quick-deb-builder.svg?label=backlog&style=plastic)](https://waffle.io/gustavosotnas/quick-deb-builder)
[![GitHub license](https://img.shields.io/github/license/gustavosotnas/quick-deb-builder.svg?style=plastic)](https://github.com/gustavosotnas/quick-deb-builder/blob/master/COPYING)
[![GitHub release](https://img.shields.io/github/release/gustavosotnas/quick-deb-builder.svg?style=plastic)](https://github.com/gustavosotnas/quick-deb-builder/releases/latest)

English
--------------------------
**Quick DEB Builder** is a simple tool written in Bash that creates [*.deb*](http://en.wikipedia.org/wiki/Deb_%28file_format%29) packages from an [existing build tree](https://www.debian.org/releases/jessie/i386/apcs02.html.en) in a easy and quick way.

Just enter a folder path that contains a valid "debian-like" directory structure and an output folder path that **Quick DEB Builder** creates the *.deb* package in the specified output folder.

It automatically solves most common permission problems for files and directories in creating *.deb* packages.

### License
**Quick DEB Builder** is distributed under the terms of the [GNU General Public License](http://www.gnu.org/licenses/), version 2 or later. See the COPYING file for details.

### Download and installation
**Quick DEB Builder** is available as an installable *.deb* package for Debian-based systems (*Ubuntu, Mint, Elementary OS, Deepin, Kali, Tails,* etc.)

To download the *.deb* package, go to [***releases***](https://github.com/gustavosotnas/quick-deb-builder/releases/latest) section and download the latest version of it. Install with a **package installer** like [GDebi](https://apps.ubuntu.com/cat/applications/gdebi) or enter the following command in a Terminal (in the folder where is the downloaded file):

`sudo dpkg -i quick-deb-builder_ver.si.on_all.deb` <br>
(replace `ver.si.on` with the downloaded application version number)

#### Dependencies
 * [**yad**](http://www.webupd8.org/2010/12/yad-zenity-on-steroids-display.html), which must be installed to the application work correctly.

### Bug tracker
Found a bug? Want to suggest a new feature or improvement? Let us know [here](https://github.com/gustavosotnas/quick-deb-builder/issues) on GitHub!

### Author
 * Gustavo Moraes - <gustavomdsantos@pm.me>

### Pull Request
Contributors are welcome! [Issues - gustavosotnas/quick-deb-builder](https://github.com/gustavosotnas/quick-deb-builder/issues)

Português
--------------------------
**Quick DEB Builder** é uma simples ferramenta feita em Bash que cria pacotes *.deb* de forma fácil e rápida, a partir de uma [árvore de construção existente](https://www.debian.org/releases/jessie/i386/apcs02.html.en).

Basta inserir um caminho de pasta que contenha uma estrutura de diretórios "*debian-like*" válida e um caminho de pasta de saída que o **Quick DEB Builder** cria o pacote *.deb* na pasta de saída especificada.

Ele resolve automaticamente os problemas mais comuns de permissão para arquivos e diretórios na criação de pacotes *.deb*.

### Licença
**Quick DEB Builder** é distribuído sob os termos da [GNU General Public License](http://www.gnu.org/licenses/), versão 2 ou posterior. Consulte o arquivo COPYING para mais detalhes.

### Download e instalação
**Quick DEB Builder** está disponível como um pacote *.deb* instalável para sistemas baseados no ***Debian*** (*Ubuntu, Mint, Elementary OS, Deepin, Kali, Tails,* etc.).

Para baixar o pacote *.deb*, vá para a seção [***releases***](https://github.com/gustavosotnas/quick-deb-builder/releases/latest) e baixe a última versão do mesmo. Instale com um **instalador de pacotes** como [GDebi](https://apps.ubuntu.com/cat/applications/gdebi/) ou digite o seguinte comando em um Terminal (na pasta onde está o arquivo baixado):

`sudo dpkg -i quick-deb-builder_ver.si.on_all.deb` <br>
(substitua `ver.si.on` pelo número da versão do aplicativo baixada)

#### Dependências
 * [**yad**](http://www.webupd8.org/2010/12/yad-zenity-on-steroids-display.html), que deve estar instalado para o aplicativo funcionar corretamente.

### Bug tracker
Encontrou um bug? Quer sugerir uma nova funcionalidade ou melhoria? Informe-nos [aqui](https://github.com/gustavosotnas/quick-deb-builder/issues) no GitHub!

### Autor
 * Gustavo Moraes - <gustavomdsantos@pm.me>

### Pull Request
Contribuidores são bem vindos! [Issues - gustavosotnas/quick-deb-builder](https://github.com/gustavosotnas/quick-deb-builder/issues)
