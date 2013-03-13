if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Call with sudo." 2>&1
  exit 1
fi

export FACTER_deploy_environment='dev' 
export FACTER_stuff_folder='/root/puppet-stuff'
puppet apply --modulepath "${FACTER_stuff_folder}/puppet/modules" "${FACTER_stuff_folder}/puppet/manifests/default.pp"
