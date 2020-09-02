sudo cp ./auto_complete/* /etc/bash_completion.d/
echo "Copy to /etc/bash_completeion.d [`ls -m ./auto_complete`]"
sudo cp ./script/* /usr/local/bin/
echo "Copy to /usr/local/bin [`ls -m ./script`]"
cd /usr/local/bin
if [ ! -f gitm ]; then
	sudo ln -s mgit gitm
	echo "link in /usr/local/bin [mgit -> gitm]"
fi
sync
