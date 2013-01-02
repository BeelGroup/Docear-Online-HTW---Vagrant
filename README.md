## Installation

* https://www.virtualbox.org/wiki/Downloads
    * tested with VirtualBox 4.2.6 for Windows hosts 
* http://vagrantup.com/
     * click "Download Now"
	 * tested with vagrant_1.0.5.msi on Windows 7 Home Premium 64bit
	 
## Working with the VM

### Setup Docear

* put docear_linux.tar.gz in the folder artifacts/docear
* put in the same folder a file version.txt which contains the docear build number
    * for example docear-1.0.0.7_devel_build139
    * it has to match with the content of the docear_linux.tar.gz
    * beware of whitespace
* don't check the files into version control

### Setup any play app

* put into artifacts/play only one zip file
    * zip file has to be created with `sbt dist -Dconfig.file=conf/name_the_conf_here.conf`
    * the zip file is in the dist folder of your play app

### Virtual maschine lifecycle

* use the windows command line `cmd` and not cygwin/git bash int the directory where the Vagrantfile is
* `vagrant up` creates the virtual maschine
    * this may take a while the first time because it downloads an prepared image for Debian Squeeze
	* assure your firewall does not block the download
* `vagrant reload` restartes the virtual maschine
    * usefull if the configuration changes
	* usefull if new artifact is deployed
* `vagrant destroy` deletes the virtual maschine
* `vagrant ssh` opens a ssh session to the maschine
* `vagrant halt` shuts down a virtual maschine

### Ports

* Vagrant forwards ports, for example port 80 on the virtual maschine is available via port 4080
    * so you can use http://localhost:4080
	* for other port forwards look at the Vagrantfile
* port 80 of the virtual maschine (not your maschine!) has an apache with 2 loadbalanced play instances
* port 8080/8081 contains docear instances

### Addtitional notes

* Docear takes a while to start
* write shellscripts to build and deploy the apps
* don't change files directly in this reposity. Fork this repository and create pull requests.
* Docear should log into the logs folder, so you can read it without ssh but with your favorite text editor