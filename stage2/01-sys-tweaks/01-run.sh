#!/bin/bash -e

install -m 755 files/resize2fs_once	"${ROOTFS_DIR}/etc/init.d/"

install -d				"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d"
install -m 644 files/ttyoutput.conf	"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d/"

install -m 644 files/50raspi		"${ROOTFS_DIR}/etc/apt/apt.conf.d/"

install -m 644 files/console-setup   	"${ROOTFS_DIR}/etc/default/"

install -m 755 files/rc.local		"${ROOTFS_DIR}/etc/"

on_chroot << EOF
systemctl disable hwclock.sh
systemctl disable nfs-common
systemctl disable rpcbind
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
systemctl enable regenerate_ssh_host_keys
EOF

if [ "${USE_QEMU}" = "1" ]; then
	echo "enter QEMU mode"
	install -m 644 files/90-qemu.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
	on_chroot << EOF
systemctl disable resize2fs_once
EOF
	echo "leaving QEMU mode"
else
	on_chroot << EOF
systemctl enable resize2fs_once
EOF
fi

on_chroot << EOF
for GRP in input spi i2c gpio; do
	groupadd -f -r "\$GRP"
done
for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
  adduser $FIRST_USER_NAME \$GRP
done
EOF

on_chroot << EOF
setupcon --force --save-only -v
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

# For some reason curl isn't using the correct path
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

on_chroot << EOF
curl -sSL https://get.docker.com/ | sh
usermod -aG docker $FIRST_USER_NAME
EOF

curl -sSL https://releases.hashicorp.com/consul/1.7.2/consul_1.7.2_linux_armhfv6.zip -o "${STAGE_WORK_DIR}/consul.zip"
unzip "${STAGE_WORK_DIR}/consul.zip" -d "${ROOTFS_DIR}/usr/sbin/"
rm "${STAGE_WORK_DIR}/consul.zip"

install -d "${ROOTFS_DIR}/etc/consul"

install -m 644 files/consul.service "${ROOTFS_DIR}/etc/systemd/system/consul.service"

install -d "${ROOTFS_DIR}/etc/consul.d"

install -m 644 files/consul.hcl "${ROOTFS_DIR}/etc/consul.d/consul.hcl"
if [ "${NOMAD_SERVER}" == "1" ]; then
    install -m 644 files/consulserver.hcl "${ROOTFS_DIR}/etc/consul.d/server.hcl"
    cat <<EOF > "${ROOTFS_DIR}/etc/consul.d/encrypt.hcl"
encrypt = "${CONSUL_ENCRYPTION_KEY}"
EOF
fi

on_chroot << EOF
chown root:root /usr/sbin/consul
chmod 755 /usr/sbin/consul
systemctl enable consul
EOF

curl -sSL https://releases.hashicorp.com/nomad/0.11.1/nomad_0.11.1_linux_arm.zip -o "${STAGE_WORK_DIR}/nomad.zip"
unzip "${STAGE_WORK_DIR}/nomad.zip" -d "${ROOTFS_DIR}/usr/sbin/"
rm "${STAGE_WORK_DIR}/nomad.zip"

install -d "${ROOTFS_DIR}/etc/nomad"

install -m 644 files/nomad.service "${ROOTFS_DIR}/etc/systemd/system/nomad.service"

install -d "${ROOTFS_DIR}/etc/nomad.d"
install -m 644 files/nomad.hcl "${ROOTFS_DIR}/etc/nomad.d/nomad.hcl"
if [ "${NOMAD_SERVER}" == "1" ]; then
    install -m 644 files/server.hcl "${ROOTFS_DIR}/etc/nomad.d/server.hcl"
    cat <<EOF > "${ROOTFS_DIR}/etc/nomad.d/encrypt.hcl"
server {
    encrypt = "${CONSUL_ENCRYPTION_KEY}"
}
EOF
fi
install -m 644 files/client.hcl "${ROOTFS_DIR}/etc/nomad.d/client.hcl"

on_chroot << EOF
chown root:root /usr/sbin/nomad
chmod 755 /usr/sbin/nomad
systemctl enable nomad
EOF

if [ "${NOMAD_SERVER}" == "1" ]; then
    install -v -m 644 files/picluster.service "${ROOTFS_DIR}/etc/avahi/services/"
fi

if [ "${NOMAD_SERVER}" == "1" ]; then
    install -m 755 files/clientboot "${ROOTFS_DIR}/etc/init.d/clientboot"
    install -m 644 files/server.txt "${ROOTFS_DIR}/boot/server.txt"
fi

rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*
