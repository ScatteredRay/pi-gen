docker-machine.exe create --driver amazonec2 --amazonec2-instance-type "t3.small" --amazonec2-region us-west-2 pi-dockerhost
docker-machine.exe ssh pi-dockerhost sudo apt-get install qemu qemu-user-static binfmt-support
docker-machine.exe ssh pi-dockerhost sudo modprobe binfmt_misc