#!/bin/bash

echo "Please ensure you have configured your default AWS credentials in ~/.aws/credential. The account using the credential must have READ privileges to work."

echo ""
echo "By default this will run in the regions eu-west-1, eu-west-2, eu-east-1, eu-east-2, us-west-1 and us-west-2. To change this, add or remove regions in the list under 'declare -a REGIONS=()'"
echo ""

if [ ! $(which terraforming) ]; then
  while true; do
    read -p "Ruby gem 'terraforming' not installed. Install? (Requires sudo) [Y/N] " yn
    case $yn in
      [Yy]*) sudo gem install terraforming; break;;
      [Nn]*) echo Ruby gem 'terraforming' was not installed. Exiting.; exit 0;;
      *) echo Invalid answer. Please either type Y or N.;;
    esac
  done
fi

declare -a REGIONS=("eu-west-1" "eu-west-2" "us-east-1" "us-east-2" "us-west-1" "us-west-2")
RESOURCE_TYPES=$(terraforming | grep 'terraforming' | grep -v 'help' | awk '{print $2}')

for REGION in "${REGIONS[@]}"; do
    for TYPE in $RESOURCE_TYPES; do
        echo "Collecting resources for $TYPE in $REGION"
        mkdir -p ./aws-resources/$REGION/
        echo "/*" >> ./aws-resources/$REGION/resources.tf
        echo "### Resource Type: aws-$TYPE ###" >> ./aws-resources/$REGION/resources.tf
        echo "*/" >> ./aws-resources/$REGION/resources.tf
        terraforming $TYPE --region $REGION >> ./aws-resources/$REGION/resources.tf
        echo "Resources for $TYPE in $REGION added to ./aws-resources/$REGION/resources.tf"
    done
done

