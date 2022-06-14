#!/bin/bash
set -e
rm -rf local_deploy



# 先執行參數調用，接者執行複製，然後進行取代，再進行編譯，最後發佈

#遠端調用
parameterURl="http://${CONTROL_IPPORT}/buildParameter/api/getProductJobParameterResult.show?productName=${DEPLOY_TARGET}&jobName=${JOB_NAME}&DEBUG_MODE=${DEBUG_MODE}&DOCKER_TYPE=${DOCKER_TYPE}"
echo 下載參數檔 ${parameterURl}
curl -s -L ${parameterURl} --output parameter.sh
source ${PWD}/parameter.sh

export

# 執行預設複製動作
sh k8s/jenkins/${SUBDIR}/${JOB_NAME}/do/mainCP.sh


# 判斷傳入的參數 ${DOCKER_TYPE} 去執行對應 do 裡面的檔案
filePath2="k8s/jenkins/${SUBDIR}/${JOB_NAME}/do/DOCKER_TYPE/${DOCKER_TYPE}.sh"
if [ -f ${filePath2} ]
then
  echo "sh ${filePath2}"
  sh ${filePath2}
else
  echo "${filePath2} not found"
fi


# 判斷傳入的參數 ${DEPLOY_TARGET} 去執行對應 do 裡面的檔案
filePath1="k8s/jenkins/${SUBDIR}/${JOB_NAME}/do/DEPLOY_TARGET/${DEPLOY_TARGET}.sh"
if [ -f ${filePath1} ]
then
  echo "sh ${filePath1}"
  sh ${filePath1}
else
  echo "${filePath1} not found"
fi



# 執行主要參數取代
sh k8s/jenkins/${SUBDIR}/${JOB_NAME}/do/main.sh

#複寫遊戲版號
GIT_COMMIT_SHORT="";
if   [ "$VERSION_ID" = "" ]
then
  GIT_COMMIT_SHORT=${GIT_COMMIT:0:7};
else
  GIT_COMMIT_SHORT=$VERSION_ID;
fi
echo '{ "version":"'$GIT_COMMIT_SHORT'" }' > assets/resources/Game/config/clientinfo.json

rm package-lock.json

#npm i




# build & deploy

echo $DOCKER_TYPE

imageURL="http://${CONTROL_IPPORT}/imageList/api/getImageVersion.show?jobName=${JOB_NAME}-${DOCKER_TYPE}-${DEPLOY_TARGET}-${GAME_ID}&gitVersion=${GIT_COMMIT_SHORT}"
if [ "$BUILD_IMAGE" == "true" ]
then
  echo "強制編譯"
  imageURL="http://${CONTROL_IPPORT}/imageList/api/getImageVersion.show?jobName=${JOB_NAME}-${DOCKER_TYPE}-${DEPLOY_TARGET}-${GAME_ID}gitVersion=${GIT_COMMIT_SHORT}"

  # build Game
  echo "Build Cocos Creator Game"

  npm install gulp --save-dev
  npm install gulp-imagemin --save-dev
  npm install gulp-htmlmin --save-dev
  npm install gulp-file-inline --save-dev
  npm install gulp-javascript-obfuscator --save-dev
  npm install vinyl-sourcemaps-apply --save-dev
  npm install md5-typescript --save-dev


  echo /Applications/CocosCreator${COCOS_VERSION}.app/Contents/MacOS/CocosCreator --path $WORKSPACE --build "platform=web-mobile"$debug_command
  /Applications/CocosCreator${COCOS_VERSION}.app/Contents/MacOS/CocosCreator --path $WORKSPACE --build "platform=web-mobile"$debug_command

fi

echo 下載imageURL ${imageURL}
curl -s -L ${imageURL} --output imageUrl.sh

# 不編譯且 VERSION_ID 有帶入的情況下，強制設定 imgerUrl 內容
if [ "$BUILD_IMAGE" == "false" ] && [ "$VERSION_ID" != "" ]
then
  echo ${REG_ADDR}/${REG_SPACE}/${DOCKER_TYPE}:$DEPLOY_TARGET-$DOCKER_TYPE-$GAME_ID-$VERSION_ID > imageUrl.sh
fi

imageUrl=`cat imageUrl.sh`
if [ $imageUrl == "null" ]
then
  imageClear=true
  if   [ "$VERSION_ID" = "" ]
  then
    TAG_VERSION=$JOB_NAME-$BUILD_NUMBER
  else
    TAG_VERSION=$DEPLOY_TARGET-$DOCKER_TYPE-$GAME_ID-$VERSION_ID
  fi
  if [ "$BUILD_IMAGE" == "true" ]
  then
    docker build -t ${REG_ADDR}/${REG_SPACE}/${DOCKER_TYPE}:$TAG_VERSION .  --no-cache
    #docker push     ${REG_ADDR}/${REG_SPACE}/${DOCKER_TYPE}:$TAG_VERSION
    /usr/local/bin/gcloud docker -- push ${REG_ADDR}/${REG_SPACE}/${DOCKER_TYPE}:$TAG_VERSION
    docker rmi      ${REG_ADDR}/${REG_SPACE}/${DOCKER_TYPE}:$TAG_VERSION
    echo "image 上傳完畢"
  else
    echo "不 build"
    imageClear=false
  fi

  export IMG_LATEST=${REG_ADDR}/${REG_SPACE}/${DOCKER_TYPE}:$TAG_VERSION
  echo ${IMG_LATEST}

  # 注意要先送出才有 IMG_LATEST
  if [ $imageClear = true ]
  then
    curl "http://${CONTROL_IPPORT}/imageList/api/receiveImageUrlVersion.show?jobName=${JOB_NAME}-${DOCKER_TYPE}-${DEPLOY_TARGET}-${GAME_ID}&ImageUrl=${IMG_LATEST}&gitVersion=${GIT_COMMIT_SHORT}"
  fi

else
  IMG_LATEST=$imageUrl
  TAG_VERSION=`echo $imageUrl|cut -d ':' -f 2`
fi

# statefulset yaml 替換資料
sed -i ''  "s/<BASE_IMG_VERSION>/${BASE_IMG_VERSION}/g" ${YAMLFILE}
sed -i ''  "s|<IMG_LATEST>|${IMG_LATEST}|g"             ${YAMLFILE}
sed -i ''  "s/<DB_ENV>/${DB_ENV}/g"                     ${YAMLFILE}
sed -i ''  "s/<GAME_ID>/${GAME_ID}/g"                   ${YAMLFILE}

if [ "$DEPLOY_IMAGE" == "true" ]
then
  /bin/bash -e k8s/server/tool/sh/CheckImagesUpload.sh  ${DEPLOY_TARGET} ${REG_ADDR} ${REG_SPACE}  ${DOCKER_TYPE}  $TAG_VERSION GCP
  if  [ "$FORCE_RECREATE" = "false" ]
  then
    kubectl apply -f  ${YAMLFILE}
  else
    kubectl replace -f  ${YAMLFILE} --force
  fi
else
  echo "不發布"
fi
