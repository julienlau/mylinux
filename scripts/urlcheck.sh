#!/bin/bash

url=$1

ref=/tmp/url-ref.html
new=/tmp/url-new.html

curl -s $url | grep -v 'meta name="issued"' > $ref

i=0
while [[ $i -le 10000 ]]; do
    curl -s $url | grep -v 'meta name="issued"' > $new
    cmp $ref $new
    if [[ $? -ne 0 ]]; then
        echo "webpage updated $url"
        notify-send "urlcheck ! webpage updated $url"
        mv $new $ref
    fi
    sleep 60
done

rm -f $ref $new
