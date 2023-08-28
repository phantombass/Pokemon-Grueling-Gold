#!/Data/Updater/bin/sh
vers=($(git tag))
curl -o "version_temp" https://raw.githubusercontent.com/phantombass/Pokemon-Grueling-Gold/master/version
link=`cat version_temp`
printf "%s\n" "${vers[@]}" > vers_temp
vers=`cat vers_temp`
for version in ${vers}
do
	before="${version}"
	after="${link}"
	echo ${before}
	echo ${after}
	files=($(git diff --name-only ${before}...${after} -- . :^Data/Updater))
	for file in ${files[@]}
	do
		echo $file
	done
	echo 'mkfile() { mkdir -p "$(dirname "$1")" && touch "$1" ;  }' >> ~/.bashrc
	source ~/.bashrc
	mkfile Data/Changes/${before}/changes
	printf "%s\n" "${files[@]}" > Data/Changes/${before}/changes
done
rm "version_temp"
rm "vers_temp"
rm -r Data/Changes/master