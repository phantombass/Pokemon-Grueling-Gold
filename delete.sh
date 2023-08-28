#!/Data/Updater/bin/sh
curl -o "version_temp" https://raw.githubusercontent.com/phantombass/Pokemon-Grueling-Gold/master/version
link=`cat version_temp`
deleted=`cat "Data/Changes/${link}/deleted"`
for del in ${deleted}
do
      rm -r $del
done
rm version_temp
