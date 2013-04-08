set -x

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

echo "applying puppet scripts"
export FACTER_deploy_environment=$deploy_env
stuff_older='/home/import/server-configuration'
if [ -d "/vagrant" ]; then
    stuff_older='/vagrant'
fi
export FACTER_stuff_folder="$stuff_older"
puppet apply --modulepath "${FACTER_stuff_folder}/puppet/modules" "${FACTER_stuff_folder}/puppet/manifests/default.pp"

service play-frontend-redeploy start
service play-frontend start
service mindmap-backend-redeploy start
chmod ug+x /var/mindmap-backend/current/freeplane.sh
service mindmap-backend start