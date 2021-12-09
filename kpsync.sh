#!/bin/bash

. ~/.kpsync

CURL_ARGS='--silent'
EXPORT_ARGS='-o /dev/null'
if [ "$CURL_OUTPUT" = "1" ] ; then
	CURL_ARGS=""
	EXPORT_ARGS=""
fi

function date_to_unix() {
	date --date "$1" -u +"%s"
}
function date_to_tz() {
	date --date "$1" -u +"%Y-%m-%dT%H:%M:%SZ"
}

CUR_FILE_TIMESTAMP=`stat -c %y "$KDBX_FILE_PATH"`
CUR_FILE_UNIX=`date_to_unix "$CUR_FILE_TIMESTAMP"`
CUR_FILE_TZ=`date_to_tz "$CUR_FILE_TIMESTAMP"`

function get_json_param() {
 echo $1 | grep -Po "(?<=\"$2\":)(.*?)(?=})" | cut -d '"' -f2 
}

function export_file() {
	curl $CURL_ARGS -X POST https://content.dropboxapi.com/2/files/upload \
  --header "Authorization: Bearer $DROPBOX_AUTH" \
  --header 'Content-Type: application/octet-stream' \
  --header "Dropbox-API-Arg: {\"path\":\"$DROPBOX_PATH\",\"mode\":{\".tag\":\"overwrite\"},\"client_modified\": \"$CUR_FILE_TZ\"}" \
  --data-binary @"$KDBX_FILE_PATH" $EXPORT_ARGS
}


function import_file() {
	curl -X POST https://content.dropboxapi.com/2/files/download \
  --header "Authorization: Bearer $DROPBOX_AUTH" \
  --header "Dropbox-API-Arg: {\"path\":\"$DROPBOX_PATH\"}" -o $KDBX_FILE_PATH $CURL_ARGS
}

METADATA_JSON=`curl -X POST https://api.dropboxapi.com/2/files/get_metadata --header "Authorization: Bearer $DROPBOX_AUTH" --header 'Content-Type: application/json' --data "{\"path\":\"$DROPBOX_PATH\"}" $CURL_ARGS`
METADATA_JSON_ERROR=`get_json_param "$METADATA_JSON" error_summary`
JSON_ERROR_CODE=`echo $METADATA_JSON_ERROR | cut -d "/" -f2`


if [ "$JSON_ERROR_CODE" = "not_found" ] ; then
	echo "File at \"$DROPBOX_PATH\" not found, uploading the current one."
	export_file
elif [ "$JSON_ERROR_CODE" = "" ] ; then
	FILE_MODIFIED_TIMESTAMP=`get_json_param "$METADATA_JSON" client_modified`
	FILE_MOD_UNIX=`date_to_unix "$FILE_MODIFIED_TIMESTAMP"`

	if [ "$FILE_MOD_UNIX" -lt "$CUR_FILE_UNIX" ] ; then
		echo "dropbox date ($FILE_MOD_UNIX) older than current file date ($CUR_FILE_UNIX) ! updating"
		export_file
		exit 0
	elif [ "$FILE_MOD_UNIX" -gt "$CUR_FILE_UNIX" ] ; then
		echo "dropbox date ($FILE_MOD_UNIX) newer than current file date ($CUR_FILE_UNIX) ! importing"
		import_file
		exit 0
	else
		echo "already in sync !"
		exit 0	
	fi
else
	echo "An error occurred. $METADATA_JSON $JSON_ERROR_CODE"
	exit 1
fi
