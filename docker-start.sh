#!/bin/sh
# set -euo pipefail
# set -o errexit
# set -o errtrace
IFS=$'\n\t'

export S3_ACL=${S3_ACL:-private}

test $MOUNT_POINT
# rm -rf ${MOUNT_POINT}
mkdir -p ${MOUNT_POINT}

if [ "$IAM_ROLE" == "none" ]; then
  export AWSACCESSKEYID=${AWSACCESSKEYID:-$AWS_ACCESS_KEY_ID}
  export AWSSECRETACCESSKEY=${AWSSECRETACCESSKEY:-$AWS_SECRET_ACCESS_KEY}

  echo 'IAM_ROLE is not set - mounting S3 with credentials from ENV'
  /usr/bin/s3fs ${S3_BUCKET} ${MOUNT_POINT} -o nosuid,nonempty,nodev,allow_other,default_acl=${S3_ACL},retries=5
else
  echo 'IAM_ROLE is set - using it to mount S3'
  /usr/bin/s3fs ${S3_BUCKET} ${MOUNT_POINT} -o iam_role=${IAM_ROLE},nosuid,nonempty,nodev,allow_other,default_acl=${S3_ACL},retries=5
fi

# exec "$@"

[ -z "$UID" ] && UID=0
[ -z "$GID" ] && GID=0

# echo >> /etc/xxx and not adduser/addgroup because adduser/addgroup
# won't work if uid/gid already exists.
echo -e "droppy:x:${UID}:${GID}:droppy:/droppy:/bin/false\n" >> /etc/passwd
echo -e "droppy:x:${GID}:droppy\n" >> /etc/group

# it's better to do that (mkdir and chown) here than in the Dockerfile
# because it will be executed even on volumes if mounted.
mkdir -p /config
mkdir -p /files

chown -R droppy:droppy /config
chown droppy:droppy /files

exec /bin/su -p -s "/bin/sh" -c "exec /usr/bin/droppy start --color -f /files -c /config" droppy
