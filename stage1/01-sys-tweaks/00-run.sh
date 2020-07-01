#!/bin/bash -e

install -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -m 644 files/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

# Write passwords to a file.
cat <<EOF > /pi-gen/deploy/users_${IMG_DATE}-${IMG_NAME}
${FIRST_USER_NAME} ${FIRST_USER_PASS}
root ${ROOT_PASS}
EOF

cat <<EOF > /pi-gen/deploy/key_${IMG_DATE}-${IMG_NAME}
${CONSUL_ENCRYPTION_KEY}
EOF

on_chroot << EOF
if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
fi
echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
echo "root:${ROOT_PASS}" | chpasswd
EOF


