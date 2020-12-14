#!/bin/bash

aws_access_key_id=$1
aws_secret_access_key=$2
aws configure set aws_access_key_id $aws_access_key_id
aws configure set aws_secret_access_key $aws_secret_access_key
aws configure set default.region us-east-1

function send_status() {
	aws ses send-email --from notifications@example.com --to dl@example.com --subject "Build Notification (Docker)" --text "$1"
}

send_status "Docker build started"
	
eval $(aws ecr get-login --no-include-email) > build.log 2>&1 
if [ $? -ne 0 ]; then
	last_log=$(cat build.log)
	send_status "Docker build failed (ecr login). $last_log"
	exit 1
fi

for name in */ ; do
	aws ecr create-repository --repository-name ${name::-1}
	cat repo_policy.json | sed 's/##POLICY_ID##/'${name::-1}'/g' > repo_policy_final.json
	echo $name
	pushd $name
	version=$(cat ./version)
	# docker load -i $CI_PROJECT_DIR/docker-cache/${name::-1}.tar || true
	docker build -t ${name::-1}:$version . 2>&1 | tee build.log
	if [ $? -ne 0 ]; then
		last_log=$(cat build.log)
		send_status "Docker build failed (docker build). $last_log"
		exit 1
	fi

	docker tag ${name::-1}:$version 123456789.dkr.ecr.us-east-1.amazonaws.com/${name::-1}:$version
	docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/${name::-1}:$version	

	docker tag ${name::-1}:$version 123456789.dkr.ecr.us-east-1.amazonaws.com/${name::-1}:latest
	docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/${name::-1}:latest	
	popd
	aws ecr set-repository-policy --repository-name ${name::-1} --policy-text file://repo_policy_final.json
	rm repo_policy_final.json
done

send_status "Docker build finished successfully"