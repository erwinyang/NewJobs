#!/bin/bash

cate="pages"
list=`ls $cate`
for i in $list;do
     echo "${i}"
     perl parse_pages.pl $cate/${i} >>github_users
done
