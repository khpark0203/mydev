if [ ! -z $1 ]; then
	sleep 5
fi
xmodmap -e "keycode 94 = backslash bar"
xmodmap -e "keycode 79 = KP_Insert"
xmodmap -e "keycode 81 = KP_Prior"
xmodmap -e "keycode 89 = KP_Next"
xmodmap -e "keycode 87 = KP_End"
xmodmap -e "keycode 90 = KP_Insert"
xmodmap -e "keycode 91 = KP_Delete"
xmodmap -e "keycode 83 = KP_Delete"
xmodmap -e "keycode 80 = KP_Home"
xmodmap -e "keycode 85 = KP_Next"
xmodmap -e "keycode 88 = KP_Down"
xmodmap -e "keycode 84 = KP_End"