#!/bin/bash -e


#This is installed in stage1/02-net-tweaks
rm "${ROOTFS_DIR}/etc/hostname"

install -m 644 files/hostnamecp.service "${ROOTFS_DIR}/etc/systemd/system/hostnamecp.service"
install -m 644 files/hostnamegen.service "${ROOTFS_DIR}/etc/systemd/system/hostnamegen.service"

on_chroot << EOF
systemctl enable hostnamecp
systemctl enable hostnamegen
EOF
