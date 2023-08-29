#!/Data/Updater/bin/sh
version=`cat version`
curl -o Data/Changes/${version}/changes https://raw.githubusercontent.com/phantombass/Pokemon-Grueling-Gold/Release/Data/Changes/${version}/changes
curl -o Data/Changes/${version}/deleted https://raw.githubusercontent.com/phantombass/Pokemon-Grueling-Gold/Release/Data/Changes/${version}/deleted