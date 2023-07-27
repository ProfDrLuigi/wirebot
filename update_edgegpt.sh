#!/bin/bash
#

echo "Checking Repo ..."

python3 -m pip install EdgeGPT --upgrade > /dev/null

py_path=$( python3 -c "import pkg_resources; print(pkg_resources.resource_filename('EdgeGPT', ''))" )
version=$( curl -sS https://raw.githubusercontent.com/acheong08/EdgeGPT/main/setup.py | grep "version=" | sed -e 's/.*="//g' -e 's/".*//g' )

line1="import os"
line2="import subprocess"

if [[ $(grep -c "$line1" "$py_path"/main.py) -gt 0 && $(grep -c "$line2" "$py_path"/main.py) -gt 0 ]]; then
    echo "Nothing to update. Version $version is already installed."
    exit
fi

sed -i "0,/.*edgegpt_version=.*/ s/.*edgegpt_version=.*/edgegpt_version=\"$version\"/g" wirebot.sh

sed -i '/import json/a\
import os\nimport subprocess\n
' "$py_path"/main.py

sed -i '/p_hist("\\nYou\:")/a\
        home_dir = os.path.expanduser("~")\n        script_path = os.path.join(home_dir, ".wirebot", "wirebot.sh")\n        subprocess.call(["bash", script_path, "edgegpt"])
' "$py_path"/main.py

screen -S wirebot -p wirebot -X stuff "#style balanced"^M

echo "Updated to Version $version"
