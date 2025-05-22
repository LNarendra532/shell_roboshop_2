#!/bin/bash

# Get all running EC2 instances with their Name tag and Instance ID
# Store as a map (name -> id) or paired array

# Get instance ID and Name using jq-like query
readarray -t instance_info < <(
  aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='Name']|[0].Value]" \
    --output text
)

# Create associative array (requires Bash 4+)
declare -A instance_map

# Populate map: Name -> InstanceID
for line in "${instance_info[@]}"; do
  instance_id=$(echo "$line" | awk '{print $1}')
  name=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
  
  instance_map["$name"]=$instance_id
done

# Print the instance names and IDs
echo "Instance Name -> ID map:"
for name in "${!instance_map[@]}"; do
  echo "$name -> ${instance_map[$name]}"
done
