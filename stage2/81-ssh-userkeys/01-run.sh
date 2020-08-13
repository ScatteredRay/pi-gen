#!/bin/bash -e

install -m 755 files/userkeys.sh "${ROOTFS_DIR}/usr/local/bin/userkeys.sh"
sed  "${ROOTFS_DIR}/usr/local/bin/userkeys.sh" -i -e "s|SSH_KEYS_SERVER|${SSH_KEYS_SERVER}|"

install -m 644 files/sshd_config "${ROOTFS_DIR}/etc/ssh/sshd_config"
