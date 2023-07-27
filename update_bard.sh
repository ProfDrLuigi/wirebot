#!/bin/bash
#

echo "Checking Repo ..."

pip3 install --upgrade GoogleBard > /dev/null

py_path=$( python3 -c "import pkg_resources; print(pkg_resources.resource_filename('Bard', ''))" )
version=$( curl -sS https://raw.githubusercontent.com/acheong08/Bard/main/setup.py | grep "version=" | sed -e 's/.*="//g' -e 's/".*//g' )

echo "$py_path"
echo "$version"

line1="import subprocess"

if [[ $(grep -c "$line1" "$py_path"/Bard.py) -gt 0 && $(grep -c "$line2" "$py_path"/Bard.py) -gt 0 ]]; then
    echo "Nothing to update. Version $version is already installed."
    exit
fi

sed -i "0,/.*bard_version=.*/ s/.*bard_version=.*/bard_version=\"$version\"/g" wirebot.sh

sed -i '/import json/a\
import subprocess
' "$py_path"/Bard.py

sed -i '/print("Google Bard\:")/a\
            f = open("gpt.history", "w+")\n            sys.stdout = f' "$py_path"/Bard.py

sed -i '/    print()/a\
            f.close()\n            sys.stdout = sys.__stdout__\n            home_dir = os.path.expanduser("~")\n            script_path = os.path.join(home_dir, ".wirebot", "wirebot.sh")\n            subprocess.call(["bash", script_path, "bard"])' "$py_path"/Bard.py

#screen -S wirebot -p wirebot -X stuff "#style balanced"^M

