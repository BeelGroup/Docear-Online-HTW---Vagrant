 

#http://docs.puppetlabs.com/guides/installation.html#installing-from-gems-not-recommended
sudo apt-get remove --assume-yes puppet
sudo apt-get --assume-yes autoremove 
sudo apt-get install --assume-yes rubygems && \
sudo gem install --no-rdoc --no-ri puppet -v 2.7.19 && \
sudo puppet resource group puppet ensure=present && \
sudo puppet resource user puppet ensure=present gid=puppet shell='/sbin/nologin' && \
sudo cp /var/lib/gems/1.8/gems/puppet-2.7.19/conf/auth.conf /etc/puppet/auth.conf && \
sudo puppet --version