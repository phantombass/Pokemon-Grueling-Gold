#!/Data/Updater/bin/sh
curl -o "version_temp" https://raw.githubusercontent.com/phantombass/Pokemon-Grueling-Gold/master/version
link=`cat version_temp`
echo 'mkfile() { mkdir -p "$(dirname "$1")" && touch "$1" ;  }' >> ~/.bashrc
source ~/.bashrc
mkfile Data/Changes/${link}/changes
rm version_temp