#!/bin/sh

i=0
while read line;do
	link=`echo "$line"`
	echo $link
	wget "https://github.com$link" -O user_pages/$i
    i=`expr $i + 1`
done
