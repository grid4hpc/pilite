pilite
======
Installation and configuration

Status: PRELIMINARY (work in progress)

piLite project consists of two parts:
- server-side tools
- client tools

Basically a user needs to install only client tools and configure piLite to access server-side tools.

1. Dependencies (for both server-side and client tools)
- perl 5.0 or higher
- JSON perl module
- ssh
- scp

2. Base configuration (install paths for both server-side and client tools)

To configure the target installation directory edit the Makefile and define the INSTALLDIR variable.
Also define the HOMEDIR - the HOME direcrory for the user who will run piLite. 

3. piLite client
3.1. piLite client installation
The following command should get you a running piLite client:

> make install-client

This installs the required perl scripts and the configuration file example to the 
configured directories.

3.2. To uninstall piLite client but leave the configuration and working directories run:

> make clean-client

3.3. To uninstall piLite client and remove also the configuration and working directories run:

> make clean-client-all

3.4. piLite client configuration
The configuration file for the piLite client (pilite.conf) will be placed into $HOMEDIR/.pilite/conf 
directory during installation process. Edit the file and set the following variables:

LOCAL_HOME_DIR - the same as HOMEDIR
LOCAL_KEY_FILE - user private key file to access the server
REMOTE_HOST_NAME - server host name
REMOTE_USER_NAME - the name of the remote user at the server 
REMOTE_SCRIPT_DIR - the directory at the server host where the piLite server-side tools are installed to

All the REMOTE_<...> parameters should be provided by the server administrator.

4. piLite server
4.1. piLite server installation

> make install-server

This installs the required perl scripts to the configured directory.

4.2. To uninstall piLite server but leave working directories run:
> make clean-server

4.3. To uninstall piLite server and remove also the working directories run:
> make clean-server-all

