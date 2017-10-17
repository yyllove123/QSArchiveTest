#!/bin/bash
#

rm buildParams.config
configcontent="
CFBundleDisplayName=启迪园区云
CFBundleShortVersionString=2.0.0
CFBundleVersion=12
CFBundleIdentifier=com.nationsky.tuspark

meapFileServerIP=portal.tuspark.com12
meapFileServerPath=disk12
meapFileServiceJws=fstp.jws12

meapServerIP=portal.tuspark.com12
meapServerPath=gateway12
meapServiceJws=open.jws12
homePagePath=11https://portal.tuspark.com/gateway/app/w2ATQ96zo2tV5vUNwUB6xGno/index.html"

arr=$(echo $configcontent|tr "," "\n")
for x in $arr; do
  echo $x >> buildParams.config
done

sh parkAutoBuildIpa.sh -t Enterprise
#Enterprise  AppStore