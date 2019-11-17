#! /bin/sh

ELASTIC_IP={{ vip_address }}
echo $ELASTIC_IP
  # replace it with the Elastic IP address you
  # allocated from the aws console

echo "disassociating the Elastic IP $ELASTIC_IP from the instance"
# bring down the Elastic IP
aws ec2 disassociate-address --public-ip $ELASTIC_IP
exit 0
