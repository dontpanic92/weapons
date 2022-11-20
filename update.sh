echo "Fetching latest..."
git fetch

echo "Checkout to deagle branch"
git checkout deagle

echo "Updateing source..."
cp -r addons ~/server/serverfiles/csgo
cp -r cfg ~/server/serverfiles/csgo

echo "Compiling..."
~/server/serverfiles/csgo/addons/sourcemod/scripting/spcomp64 ~/server/serverfiles/csgo/addons/sourcemod/scripting/weapons.sp -o~/server/serverfiles/csgo/addons/sourcemod/plugins/weapons.smx

echo "Done"
