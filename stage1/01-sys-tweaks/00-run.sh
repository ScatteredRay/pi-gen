#!/bin/bash -e

install -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -m 644 files/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

user_passwd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-8})
root_passwd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-8})
# Write passwords to a file.
cat <<EOF > /pi-gen/deploy/users
nd ${user_passwd}
root ${root_passwd}
EOF

on_chroot << EOF
if ! id -u pi >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" nd
fi
echo "nd:${user_password}" | chpasswd
echo "root:${root_password}" | chpasswd
EOF


