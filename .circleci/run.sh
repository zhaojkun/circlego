#!/usr/bin/env bash
# SUCCESSFUL', 'FAILED', 'INPROGRESS', 'STOPPED'
# 0             1           2              3
function run(){
    jobs=( "gotest" "golint" )
    for job in "${jobs[@]}"
    do
        notify go/${job} 3
    done
    
    local code=0
    for job in "${jobs[@]}"
    do
        dojob ${job}
        lc=$?
        if [ $lc -eq 0 ]; then
            notify go/${job} 0
        else
            notify go/${job} 1
            code=$lc
        fi
    done
    return $code
}

function dojob(){

    local job=$1
    echo ">>>>>>>>>>>>>>>>>>>>>>> start ${job} <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    $job
    local code=$?
    echo -e "\n>>>>>>>>>>>>>>>>>>>>>>> stop ${job} <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    return $code
}

function gotest(){
    make test
    return $?
}

function golint(){
    res=$(make lint)
    echo "$res"
    case "$res" in
        *should*) return 1 ;;
        *       ) return 0 ;;
    esac
    
}


function notify(){
    if [[ -n $CIRCLECI ]];then
        echo "circleci"
    else
        echo "Not circleci;ignore notify"
        return
    fi
    case "$CIRCLE_REPOSITORY_URL" in
        *bitbucket.org*) notifyBitbucket $1 $2;;
        *github.com*   ) notifyGithub $1 $2;;
        *              ) echo "unknown services";;
    esac
}

function notifyBitbucket(){
    # SUCCESSFUL', 'FAILED', 'INPROGRESS', 'STOPPED'
    # 0             1           2              3
    local states=( "SUCCESSFUL"  "FAILED"  "INPROGRESS" "STOPPED" )
    local key=$1
    local state=${states[$2]}
    curl -s -o /dev/null -w "%{http_code}" -X POST \
         https://api.bitbucket.org/2.0/repositories/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/commit/${CIRCLE_SHA1}/statuses/build \
         -H "authorization: Basic $BASICAUTH" \
         -H 'cache-control: no-cache' \
         -H 'content-type: application/json' \
         -H 'postman-token: b8d22d5a-0950-1f86-3d82-16af5a1448cd' \
         -d "{
    \"state\": \"${state}\",
    \"key\": \"${key}\",
    \"url\": \"https://circleci.com/bb/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/${CIRCLE_BUILD_NUM}?utm_campaign=vcs-integration-link&utm_medium=referral&utm_source=bitbucket-build-link\"
    }"
    echo ""
}

function notifyGithub(){
    # success', 'failure', 'pending', 'error'
    # 0             1           2              3
    local states=( "success" "failure" "pending" "error" )
    local key=$1
    local state=${states[$2]}
    curl -s -o /dev/null -w "%{http_code} " -X POST \
         https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/statuses/${CIRCLE_SHA1} \
         -H "authorization: token $GITHUBTOKEN" \
         -H 'cache-control: no-cache' \
         -H 'content-type: application/json' \
         -H 'postman-token: b0604e1a-a777-df11-f3ac-df86e1b12335' \
         -d "{
           \"state\": \"${state}\",
           \"target_url\": \"https://circleci.com/gh/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/${CIRCLE_BUILD_NUM}?utm_campaign=vcs-integration-link&utm_medium=referral&utm_source=github-build-link\",
           \"context\": \"${key}\"
           }"
    echo ""
}

run
if [ $? -eq 0 ];then
    echo "Succeed"
else
    echo "Failed"
    exit 1
fi
        

