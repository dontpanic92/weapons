echo "Fetching latest..."
proxychains git fetch origin deagle

echo "Checkout to deagle branch"
git checkout origin/deagle

echo "Updating source..."
cp -r addons ~/server/serverfiles/csgo
cp -r cfg ~/server/serverfiles/csgo

echo "Compiling..."
/home/csgoserver/server/serverfiles/csgo/addons/sourcemod/scripting/spcomp64 /home/csgoserver/server/serverfiles/csgo/addons/sourcemod/scripting/weapons.sp -o/home/csgoserver/server/serverfiles/csgo/addons/sourcemod/plugins/weapons.smx

/home/csgoserver/server/serverfiles/csgo/addons/sourcemod/scripting/spcomp64 /home/csgoserver/server/serverfiles/csgo/addons/sourcemod/scripting/deagle.sp -o/home/csgoserver/server/serverfiles/csgo/addons/sourcemod/plugins/deagle.smx

echo "Done"
