#!/Data/Updater/bin/sh
vers=`cat Data/Updater/version`
curl -o "version_temp" https://raw.githubusercontent.com/phantombass/Pokemon-Grueling-Gold/master/version
link=`cat version_temp`
before="${vers}"
after="${link}"
echo ${before}
echo ${after}
files=($(git diff --name-only ${before}...${after}))
length=${#files[@]}
for file in ${files[@]}
do
	echo $file
done
printf "%s\n" "${files[@]}" > Data/Updater/changes
rm "version_temp"
curl -o "version_temp" https://raw.githubusercontent.com/phantombass/Pokemon-Grueling-Gold/master/version
link=`cat version_temp`
rm "version_temp"
files=`cat Data/Updater/changes`
length=${#files[@]}
for (( i=0; i<${length}; i++ ))
do 
	curl -o ${files[$i]} https://github.com/phantombass/Pokemon-Grueling-Gold/raw/${link}/${files[$i]}
done