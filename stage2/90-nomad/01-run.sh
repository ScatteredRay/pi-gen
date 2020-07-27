#!/bin/bash -e

cat <<EOF > /pi-gen/deploy/key_${IMG_DATE}-${IMG_NAME}
${CONSUL_ENCRYPTION_KEY}
EOF

# For some reason curl isn't using the correct path
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

## In theory this is provided by the docker package, so shouldn't need this.
#on_chroot << EOF
#curl -sSL https://get.docker.com/ | sh
#usermod -aG docker $FIRST_USER_NAME
#EOF

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
    install -m 644 files/clientboot.service "${ROOTFS_DIR}/etc/systemd/system/clientboot.service"
    install -m 644 files/server.txt "${ROOTFS_DIR}/boot/server.txt"

on_chroot << EOF
systemctl enable clientboot
EOF
fi

