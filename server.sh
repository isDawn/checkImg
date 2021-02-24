#!/bin/bash

# 检测项目中存在是否不在使用的img

cloneBasePath=$(cd `dirname $0`; pwd)

cloneProjectName='cloneResourcesProject'

CLONE_PATH="$cloneBasePath/$cloneProjectName"

echo "clonePath_____$CLONE_PATH"

# bundles
bundles=('')

# 要查找图片的分支
branchNameList=('')

# 无效图片列表
abandonedImgList=()

# 检测无效图片
checkInvalidImg() {
    branchNameList=$1

    echo "checkInvalidImg branchNameList=>:【$1】" 

    # 切换到资源文件夹
    cd 'cloneResourcesProject'

    resFileName=$(ls $pwd)

    echo "cloneProject 资源本地文件$resFileName"

    for branch in ${branchNameList[@]}
    do
        list=()
        # 获取当前分支的所有图片
        for file in ${resFileName[@]}
        do
            cd $file
            git checkout $branch
            git pull
            project_path=$(cd `dirname $0`; pwd)
            project_name="${project_path##*/}"
            echo "切换project_name =====>$project_name"
            for findImgUrl in $(find $project_path -name *.png -o -name *.jpg)
            do
                echo "查询到的img————$findImgUrl"
                list[${#list[@]}]=$findImgUrl
            done
            cd ..
        done

        echo "list +++++++ branch:$branch ========${#list[@]}"

        # 检测图片在当前环境下是否在使用
        pushd ${CLONE_PATH} >/dev/null 2>&1
        writeFile "--------------------------------------------------------------------------" 'abandonedImgLog.md'
        writeFile "###${branch}" 'abandonedImgLog.md'
        writeFile "--------------------------------------------------------------------------" 'abandonedImgLog.md'
        for imgUrl in ${list[@]}
        do
            file=$(basename -s .png $imgUrl | xargs basename -s @2x | xargs basename -s @3x)
            case1="$file.png"
            case2="$file@2x.png"
            case3="$file@3x.png"
            case1_result=$(ack -i $case1)
            case2_result=$(ack -i $case2)
            case3_result=$(ack -i $case3)
			result="$case1_result$case2_result$case3_result"
            if [ -z "$result" ];then
                echo "未使用图片，检测结果 ==========>${imgUrl}";
                abandonedImgList[${#abandonedImgList[@]}]="${imgUrl}"
                writeFile "" 'abandonedImgLog.md'
                writeFile "${imgUrl}" 'abandonedImgLog.md'
            fi
        done
        unset list
        popd >/dev/null 2>&1
    done
	
	length=${#abandonedImgList[*]}
	if [ $length -eq 0 ];then
		echo "太牛比了，竟然没有重复图片";
		return
	fi

    read -p '是否需要自动删除[y/n]' yesOrNo

    if test $yesOrNo = 'y' 
	then
        rmImgList  "${abandonedImgList[*]}"
    fi

    cd ..
}

rmImgList() {
	list=$1
    for item in ${list[@]}
	do
		rm -rf $item
	done
	echo "已完成删除，感谢使用～"
}

cloneProject() {
    checkPList=$1
    clonePath=$2
    rm -rf $clonePath;
    mkdir $clonePath
    cd $clonePath
    for i in ${checkPList[@]}
    do
        echo "开始拉取 ====> $i"
        git clone $i
    done;
    cd ..
    echo "项目拉取完毕，已经存入$2"
}

writeFile() {
    content=$1
    fileName=$2
    if [ ! -f "$fileName" ];
    then
        touch $fileName
    fi
    echo ${content}>>$fileName;
}

main() {
    # 在线拉取资源文件
    cloneProject "${bundles[*]}" $cloneProjectName

    # 检测无效图片
    checkInvalidImg "${branchNameList[*]}"
}

main