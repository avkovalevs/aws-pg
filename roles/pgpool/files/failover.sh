#!/bin/sh
failed_node=$1
new_master=$2
(
date
echo "Failed node: $failed_node"
set -x
/usr/bin/ssh -T -l postgres $new_master "/usr/bin/repmgr -f /etc/repmgr.conf standby promote 2>/dev/null 1>/dev/null <&-"
exit 0;
) 2>&1 | tee -a /tmp/pgpool_failover.log
