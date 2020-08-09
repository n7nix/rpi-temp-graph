#/bin/bash

xmlbuf=$(curl -fsSk "http://10.0.42.31/state.xml" | grep "sensor")
# xmlbuf=$(curl -fsSk "http://10.0.42.31/state.xml")

case $1 in
    1)
	echo "$(echo $xmlbuf | awk '{print $1}' | cut -d '>' -f2 | cut -d '<' -f1) "
    	;;
    2)
	echo "$(echo $xmlbuf | awk '{print $2}' | cut -d '>' -f2 | cut -d '<' -f1) "
    	;;
    3)
	echo "$(echo $xmlbuf | awk '{print $3}' | cut -d '>' -f2 | cut -d '<' -f1) "
    	;;
    *)
	echo -n "$(echo $xmlbuf | awk '{print $1}' | cut -d '>' -f2 | cut -d '<' -f1) "
	echo -n "$(echo $xmlbuf | awk '{print $2}' | cut -d '>' -f2 | cut -d '<' -f1) "
	echo -n $xmlbuf | awk '{print $3}' | cut -d '>' -f2 | cut -d '<' -f1
	;;
esac
