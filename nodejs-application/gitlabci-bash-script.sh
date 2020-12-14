#!/bin/bash

AWS_ENVIRONMENT=$1
PACKAGE_VERSION=$2
AWS_ACCESS_KEY_ID_QA=$3
AWS_SECRET_ACCESS_KEY_QA=$4
S3_DIRECTORY=$5

AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION_QA
S3_BUCKET_NAME=$DEFAULT_S3_QA
ENV_DOMAIN=$ENV_DOMAIN_QA

# Configuring aws credentials
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID_QA
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY_QA
aws configure set region $AWS_DEFAULT_REGION
aws configure set default.s3.max_concurrent_requests 20


# replacing placeholders with appropriate variables
jsfile=$(find $CI_PROJECT_DIR/some/path/with/artifacts -name "main.*.js")
echo $jsfile
sed -i "s/<env_domain>/$ENV_DOMAIN/g" $jsfile

# getting application version from package.json file
VERSIONS=$(jq -r ".deployTags" $CI_PROJECT_DIR/app/package.json)
echo $VERSIONS
IFS=','
read -ra S3KEYS <<< "$VERSIONS"
IFS=' '

# uploading artifacts to S3 bucket
for key in "${S3KEYS[@]}" ; do
	echo "The S3 key is $key"
	aws s3 sync $CI_PROJECT_DIR/app/$S3_DIRECTORY s3://$S3_BUCKET_NAME/$key/deploy --acl public-read --delete --exclude ".git/*" &
	aws s3 sync $CI_PROJECT_DIR/app/$S3_DIRECTORY s3://$S3_BUCKET_NAME/$key/builds/$PACKAGE_VERSION --exclude ".git/*" &
done


# discovering necessary cloudfront distributions to invalidate
cloudfrontdistids=$(aws cloudfront list-distributions | jq -r ".DistributionList.Items[].ARN")
IFS=$'\n'
cloudfrontids=($cloudfrontdistids)
IFS=' '

wait

for key in "${S3KEYS[@]}" ; do
	for dist in "${cloudfrontids[@]}" ; do
		if [[ $(aws cloudfront list-tags-for-resource --resource $dist | jq -r ".Tags.Items[1].Value") == $key ]]
		then
 			CLOUDFRONT_DISTRIBUTION_ID=$(cut -d "/" -f 2 <<< "$dist")
 			echo "The dist id with $key tag is $CLOUDFRONT_DISTRIBUTION_ID"
			aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*" &
 		fi
	done
done

wait
echo "All necessary cloudfronts invalidated"
