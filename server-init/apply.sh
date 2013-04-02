if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user. Call with sudo." 2>&1
  exit 1
fi

BASEDIR=$(dirname $0)
cd ${BASEDIR}

deploy_env=prod
if [ `hostname` == "v22013031569111142.yourvserver.net" ]; then
    deploy_env="staging"
fi
service play-frontend-redeploy stop
service play-frontend stop
service mindmap-backend-redeploy stop
service mindmap-backend stop

export FACTER_deploy_environment=$deploy_env
export FACTER_stuff_folder='/root/puppet-stuff'
puppet apply --modulepath "${FACTER_stuff_folder}/puppet/modules" "${FACTER_stuff_folder}/puppet/manifests/default.pp"
