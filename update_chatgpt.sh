#!/bin/bash
#

echo "Checking Repo ..."

python -m pip install --upgrade revChatGPT > /dev/null

py_path=$( python3 -c "import pkg_resources; print(pkg_resources.resource_filename('revChatGPT', ''))" )
version=$( curl -sS https://raw.githubusercontent.com/acheong08/ChatGPT/main/src/revChatGPT/version.py | sed -e 's/.*=\ "//g' -e 's/".*//g' )

echo "$py_path"
echo "$version"

line1="import subprocess"

if [[ $(grep -c "$line1" "$py_path"/V1.py) -gt 0 && $(grep -c "$line2" "$py_path"/V1.py) -gt 0 ]]; then
    echo "Nothing to update. Version $version is already installed."
    exit
fi

sed -i "0,/.*chatgpt_version=.*/ s/.*chatgpt_version=.*/chatgpt_version=\"$version\"/g" wirebot.sh

sed -i '/import json/a\
import subprocess\nimport os
' "$py_path"/V1.py

sed -i '/startswith("!continue")\:/a\            f = open("gpt.history", "w+")\n            sys.stdout = f' "$py_path"/V1.py

sed -i '/print(bcolors.ENDC)/ s/$/\n            print()\n            f.close()\n            sys.stdout = sys.__stdout__\n            home_dir = os.path.expanduser("~")\n            script_path = os.path.join(home_dir, ".wirebot", "wirebot.sh")\n            subprocess.call(["bash", script_path, "chatgpt"])/' "$py_path"/V1.py

sed -i '1693 s/^/            f = open("gpt.history", "w+")\n            sys.stdout = f\
/' "$py_path"/V1.py

sed -i '1706 s/^/            f.close()\n            sys.stdout = sys.__stdout__\n            home_dir = os.path.expanduser("~")\n            script_path = os.path.join(home_dir, ".wirebot", "wirebot.sh")\n            subprocess.call(["bash", script_path, "chatgpt"])\
/' "$py_path"/V1.py
