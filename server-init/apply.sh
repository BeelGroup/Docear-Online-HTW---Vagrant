if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Call with sudo." 2>&1
  exit 1
fi

deploy_env=prod
if [ `hostname` == "v22013031569111142.yourvserver.net" ]; then
    deploy_env="staging"
fi
sudo service play-frontend stop
sudo service mindmap-backend stop
export FACTER_deploy_environment=$deploy_env
export FACTER_stuff_folder='/root/puppet-stuff'
puppet apply --modulepath "${FACTER_stuff_folder}/puppet/modules" "${FACTER_stuff_folder}/puppet/manifests/default.pp"
