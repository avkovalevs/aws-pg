#! /bin/sh

ELASTIC_IP={{ vip_address }}
  # replace it with the Elastic IP address you
  # allocated from the aws console
  INSTANCE_ID={{ instance_id)
  # replace it with the instance id of the Instance
  # this script is installed on

echo "Assigning Elastic IP $ELASTIC_IP to the instance $INSTANCE_ID"
# bring up the Elastic IP
aws ec2 associate-address --instance-id $INSTANCE_ID --public-ip $ELASTIC_IP

exit 0
