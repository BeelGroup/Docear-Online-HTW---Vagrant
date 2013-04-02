## Installation

* https://www.virtualbox.org/wiki/Downloads
    * tested with VirtualBox 4.2.6 for Windows hosts 
* http://vagrantup.com/
     * click "Download Now"
	 * tested with vagrant_1.0.5.msi on Windows 7 Home Premium 64bit
* checkout with depth 1: git clone --depth 1 git@github.com:Docear/HTW-vagrant.git

## Steps to view app in Browser
1. `vagrant up` creates the virtual maschine and starts it
    * this may take a while the first time because it downloads an prepared image for Debian Squeeze
	* assure your firewall does not block the download
1. after this the virtual maschine is started and the prompt returns
1. put freeplane zip into artifacts/mindmap-backend
1. put play zip into artifacts/play-frontend
1. if it not starts connect with ssh and run `sudo service mindmap-backend-redeploy restart; sudo service play-frontend-redeploy restart; sudo touch /home/import/mindmap-backend/freeplane_bin-1.2.21.zip; sudo touch /home/import/play-frontend/docear-frontend-0.1-SNAPSHOT.zip`
1. you can view the app in your browser with https://localhost:4443/
2. If you change the puppet related files or deploy a new artifact call `vagrant reload`
    * to change the artifact to a new version, drop it into the artifacts folder and overwrite the existing file
1. logs are provided in the local folder logs
1. if you want to shutdown the virtual maschine call `vagrant halt`
2. if you want to delete the virtual maschine call `vagrant destroy`

## SSH
* Linux: vagrant ssh
    * with non vagrant user: `ssh -p 2222 vornamenachname@localhost -o StrictHostKeyChecking=no`
* Windows: Putty with user vagrant, password vagrant and port 2222 on 127.0.0.1
* further information to work with the server: https://github.com/Docear/HTW-Frontend/wiki/Deployment

## Working with the VM

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
    * on windows: use Putty, username: vagrant, password: vagrant, Port 2222
* `vagrant halt` shuts down a virtual maschine

### Ports

* Vagrant forwards ports, for example port 22 on the virtual maschine is available via port 2222



### Addtitional notes

* Docear takes a while to start
* write shellscripts to build and deploy the apps
* don't change files directly in this reposity. Fork this repository and create pull requests.
* Docear should log into the logs folder, so you can read it without ssh but with your favorite text editor

# Puppet
* http://docs.puppetlabs.com/references/2.7.latest/
* http://docs.puppetlabs.com/guides/language_guide.html
