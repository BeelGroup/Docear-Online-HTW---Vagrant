if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Call with sudo." 2>&1
  exit 1
fi

export FACTER_deploy_environment='dev' 
puppet apply --modulepath '/vagrant/puppet/modules' /vagrant/puppet/manifests/default.pp
