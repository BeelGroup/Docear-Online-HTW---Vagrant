echo "Backup tool to download collection content as JSON from the MongoDB database mydocear"
echo "usage:"
echo $0  "'ssh username@staging.my.docear.org'"
# example call: backup-mydocear-mongo.sh "ssh michaelschleichardt@staging.my.docear.org"
#restoring:
#upload json files to the server
#example for files collection:
#mongoimport --jsonArray --db mydocear --collection files --file files.json

if [ $# -ne 1 ]; then
  echo "error: command line argument for ssh login is missing"
  exit 1
fi

ssh_cmd=$1

load_json() {
    collection_name=$1
    ${ssh_cmd} 'mongoexport --collection '${collection_name}' --db mydocear --jsonArray' > ${collection_name}.json
}

load_json files
load_json projects
load_json mindMapMetaData