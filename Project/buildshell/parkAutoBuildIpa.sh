#-------------------------
#-脚本类型: 苹果App打包  -
#-编写名称: 杨亚霖		  -
#-编写日期: 2016/03/18  -
#-版   本:  V1.0
#-------------------------
#!/bin/bash

#当前目录
HOMEPATH=`pwd`
BUILD_DATE=$(date +%Y_%m_%d_%H_%M_%S)

#打包工程路径
PROJECT_PATH="${HOMEPATH}/../ios_newapp/AppNest"
INFO_PLIST_PATH="${PROJECT_PATH}/AppNestPhone/Info.plist"
#build文件夹路径
BUILD_PATH="${HOMEPATH}/autobuild"
#导出路径
EXPORT_PATH="${HOMEPATH}/../../TusParkCloud_${BUILD_DATE}.ipa"
#log path
log_path="${HOMEPATH}/log.log"

#开始编译工程
workspaceName="AppNest.xcworkspace"
configuration="Release"
scheme="AppNestPhone"

# four types
development="Development"
enterprise="Enterprise"
appstore="AppStore"
adhoc="AdHoc"

#Enterprise CA certificate name and mobileprovision uuid
enterpriseDevTeam="E2CU52X6UR"
enterpriseCodeSignIdentity="iPhone Distribution: Beijing Nation Sky Network"
enterpriseProvisioningProfile="19f0eaf2-2d91-4459-bc68-49da5bba6a01"
#AppStore CA certificate name and mobileprovision uuid
appstoreDevTeam="EDUG9F7VKL"
appstoreCodeSignIdentity="iPhone Distribution: Tus-Digital technology (Beijing) Co., Ltd. (EDUG9F7VKL)"
appstoreProvisioningProfile="5eed9c20-f0d3-4497-a5ff-e9acde7da9a6"


#参数检测
if [ $# -lt 1 ];then
type=$enterprise
fi

while getopts 't:' optname
do
    case "$optname" in
    t)
        if [ ${OPTARG} != $enterprise ] && [ ${OPTARG} != $appstore ] ;then
            echo "Usage: -t [Development|Enterprise|AdHoc|AppStore]"
            echo ""
        exit 1
        fi
        type=${OPTARG}
        ;;
    *)
    echo "Error! Unknown error while processing options"
    echo ""
    exit 2
    ;;
    esac
done

rm -f $log_path

#切换默认钥匙链生效
echo "解锁钥匙串访问"
security unlock-keychain -p "nationsky" "$HOME/Library/Keychains/login.keychain"

#seting build params

function replaceBundleId() {
	sed -i "" "s/$1/$2/g" $PROJECT_PATH/AppNest.xcodeproj/project.pbxproj
    echo "$1 已更改bundle ID 为：$2"
}

function replaceCer() {
	# develop team
	sed -i "" "s/DEVELOPMENT_TEAM = EDUG9F7VKL;/DEVELOPMENT_TEAM = $1;/g" $PROJECT_PATH/AppNest.xcodeproj/project.pbxproj
	# profile
	sed -i "" "s/PROVISIONING_PROFILE_SPECIFIER = tuspark;/PROVISIONING_PROFILE_SPECIFIER = $2;/g" $PROJECT_PATH/AppNest.xcodeproj/project.pbxproj
	# cer
	sed -i "" "s/PROVISIONING_PROFILE = $enterpriseProvisioningProfile;/PROVISIONING_PROFILE = $3;/g" $PROJECT_PATH/AppNest.xcodeproj/project.pbxproj
	# cer
	# sed -i "" "s/PROVISIONING_PROFILE = $enterpriseProvisioningProfile;/PROVISIONING_PROFILE = $3;/g" $PROJECT_PATH/AppNest.xcodeproj/project.pbxproj
}

function replaceBuildParams() {
	echo "开始替换plist中参数" >> $log_path
	while read line; do
	key=`echo $line|awk -F '=' '{print $1}'`
	value=`echo $line|awk -F '=' '{print $2}'`

	if [[ $key == "CFBundleIdentifier" ]]; then 
		
		if [ $type == $appstore ]; then
			/usr/libexec/PlistBuddy -c "Set CFBundleIdentifier com.tuspark.cloud" $INFO_PLIST_PATH
			replaceBundleId "com.nationsky.tuspark" "com.tuspark.cloud"
		else
			/usr/libexec/PlistBuddy -c "Set CFBundleIdentifier ${value}" $INFO_PLIST_PATH
			replaceBundleId "com.nationsky.tuspark" $value
		fi
	else
		if [[ $value != "" ]]; then
		echo "替换: ${key}的值为: ${value}" >> $log_path
		/usr/libexec/PlistBuddy -c "Set ${key} ${value}" $INFO_PLIST_PATH
		fi

		if [[ $key == "CFBundleShortVersionString" ]]; then
			#statements
			VERSION=$value
		fi
	fi

	done < ${HOMEPATH}/buildParams.config
}

#clean project
function clean(){

	cd ${PROJECT_PATH}

	echo "\033[31mStart clean!\033[0m" >> $log_path
	rm -rf $BUILD_PATH
	mkdir $BUILD_PATH
	xcodebuild clean -configuration "$configuration" -alltargets CODE_SIGN_IDENTITY="$codeSignIdentity" PROVISIONING_PROFILE="$provisioningProfile" >> $log_path || exit
	echo "移除build路径 ${BUILD_PATH}" >> $log_path
    echo "\033[31mClean success!\033[0m" >> $log_path
}

function build() {
	if [ $type == $enterprise ]; then
	    codeSignIdentity=$enterpriseCodeSignIdentity
	    provisioningProfile=$enterpriseProvisioningProfile
	elif [ $type == $development ]; then
	    codeSignIdentity=$developmentCodeSignIdentity
	    provisioningProfile=$developmentProvisioningProfile
	elif [ $type == $appstore ]; then
	    codeSignIdentity=$appstoreCodeSignIdentity
	    provisioningProfile=$appstoreProvisioningProfile
	elif [ $type == $adhoc ];then
	    codeSignIdentity=$adhocCodeSignIdentity
	    provisioningProfile=$adhocProvisioningProfile
	fi

	clean

	replaceCer

    echo "\033[31mStart archive!\033[0m" >> $log_path
    xcodebuild -workspace "$workspaceName" -scheme "$scheme" -configuration "Release" CONFIGURATION_BUILD_DIR="$BUILD_PATH"  CODE_SIGN_IDENTITY="$codeSignIdentity" PROVISIONING_PROFILE="$provisioningProfile" >> $log_path || exit

    # xcodebuild archive -workspace "$workspaceName"  -scheme "$scheme" -configuration "$configuration" -archivePath "$BUILD_PATH" CONFIGURATION_BUILD_DIR="$configurationBuildDir" CODE_SIGN_IDENTITY="$codeSignIdentity" PROVISIONING_PROFILE="$provisioningProfile" >> $log_path || exit
    
    mkdir -p ${BUILD_PATH}/ipa/Payload/
	echo "创建ipa临时文件夹: ipa/Payload" >> $log_path
	cp -r ${BUILD_PATH}/*.app ${BUILD_PATH}/ipa/Payload/
	echo "复制.app 到${BUILD_PATH}/ipa/Payload/下" >> $log_path
	cd ${BUILD_PATH}/ipa
	echo "进入ipa下进行打包操作" >> $log_path
	zip -r ${BUILD_PATH}/${BUILD_DATE}.ipa ${BUILD_PATH}/ipa/Payload
	rm -rf ${BUILD_PATH}/ipa/Payload
	echo "删除临时目录Payload" >> $log_path

    scp ${BUILD_PATH}/${BUILD_DATE}.ipa ${EXPORT_PATH}
    echo "\033[31mArchive success!\033[0m" >> $log_path
}

#Apple ID if needed
appleid="yangyalin@nationsky.com"
applepassword="Yyl1314520"
function uploadIpa(){
    #upload iTunesConnect
    osascript -e 'display notification "Start release To AppStore" with title "Validate Start!"'
    altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"

    #validate
    "$altoolPath" --validate-app -f "$ipaPath" -u "$appleid" -p "$applepassword" -t ios --output-format xml
    osascript -e 'display notification "Release To AppStore" with title "Validate Complete!"'

    #upload
    "$altoolPath" --upload-app -f "$ipaPath" -u "$appleid" -p "$applepassword" -t ios --output-format xml
    osascript -e 'display notification "Release To AppStore" with title "Upload Complete!"'
}

replaceBuildParams

build

# if [ $type == $appstore ]; then
#     uploadIpa
# else
    # installIpa
# fi