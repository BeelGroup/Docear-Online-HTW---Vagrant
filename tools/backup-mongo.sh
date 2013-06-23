echo "Backup tool to download collection content as JSON"
echo "needing two parameters:"
echo "1: the ssh command to login, for example 'ssh username@staging.my.docear.org'"
echo "2: the folder where to save the JSON files, without a trailing slash, example: '/tmp'"



# backup-mongo.sh "ssh michaelschleichardt@staging.my.docear.org" /tmp

set -x

ssh_cmd=$1
download_folder=$2

load_json() {
    collection_name=$1
    ${ssh_cmd} 'mongoexport --collection '${collection_name}' --db mydocear --jsonArray' > ${download_folder}/${collection_name}.json
}

load_json files
load_json projects
load_json mindMapMetaData