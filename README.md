# kpsync
Bash script for syncing KeepassXC databases

# Configuration
By default, this script will look for a .kpsync file in the user's home directory. This file can be configurated in this way:
```sh
# dropbox api key for reading and writing files (requires to be issued with files.metadata.write, files.metadata.read, files.content.write, files.content.read scopes)
DROPBOX_AUTH="DROPBOX_API_KEY"
# where the KDBX file is for syncing
KDBX_FILE_PATH=/home/tsu/Documents/Passwords.kdbx
# where the KDBX file is in dropbox (if it doesn't exist, it will be created)
DROPBOX_PATH=/kpsync/Passwords.kdbx
# whether to silence curl results or not (defaults to 0, meaning no output)
CURL_OUTPUT=0
```
