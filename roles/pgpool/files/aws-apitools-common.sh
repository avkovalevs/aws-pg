# Set path for AWS API tools packages
export AWS_PATH=/opt/aws
export PATH=$PATH:$AWS_PATH/bin

if [ -z "${JAVA_HOME}" ]; then
    if [ -d /usr/java/latest ]; then
        # prefer third-party JDK if present
        export JAVA_HOME=/usr/java/latest
    elif [ -d /usr/lib/jvm/java ]; then
        export JAVA_HOME=/usr/lib/jvm/java
    elif [ -d /usr/lib/jvm/jre ]; then
        export JAVA_HOME=/usr/lib/jvm/jre
    fi
fi

# Source environment variables for each set of tools

for aws_product in $(find /opt/aws/apitools /opt/aws/amitools -maxdepth 1 -type l 2>/dev/null); do
    [ -e $aws_product/environment.sh ] && source $aws_product/environment.sh
done
unset aws_product

# Uncomment this line to specify AWS_CREDENTIAL_FILE
# (see /opt/aws/credential-file-path.template)
#export AWS_CREDENTIAL_FILE=/opt/aws/credentials.txt
