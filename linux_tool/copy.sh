if [ $# -eq 0 ]; then
	echo "argv....."
	exit 0
fi

COPY_SCRIPT="copy_tool.sh"
echo "GO COPY $1"

cd $1
./$COPY_SCRIPT
