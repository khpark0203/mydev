if [ $# -eq 0 ]; then
	echo "argv....."
	exit 0
fi

COPY_SCRIPT="copy_tool.sh"

cd $1
./$COPY_SCRIPT

echo "GO COPY $1"