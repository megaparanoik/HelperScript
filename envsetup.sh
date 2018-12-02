#!/bin/bash

CURRENT_DIR=$(pwd)
export KERN_PATH=${CURRENT_DIR}/kernel
export BUILD_KERNEL=${CURRENT_DIR}/out/kernel

export FS_PATH=${CURRENT_DIR}/buildroot
export BUILD_ROOTFS=${CURRENT_DIR}/out/fs


function kernel_qemu()
{
	echo ">>>Starting to build the kernel"
	cd ${KERN_PATH}
	make ARCH=i386 O=${BUILD_KERNEL}_qemu defconfig
	cd ${BUILD_KERNEL}_qemu
	make $@ -j4
	cd ${CURRENT_DIR}
}

function kernel_orange()
{
	echo ">>>Starting to build the kernel"
	cd ${KERN_PATH}
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- O=${BUILD_KERNEL}_orange sunxi_gl_defconfig
	cd ${BUILD_KERNEL}_orange
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $@ -j4
	if [ -z $@ ] 
	then
		echo ">>>Starting to build modules"
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules -j4
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install INSTALL_MOD_PATH=${BUILD_KERNEL}_orange_modules -j4
	fi
	cd ${CURRENT_DIR}
}

function fs()
{
	echo ">>>Starting to build the FS"
	cd ${FS_PATH}
	make O=${BUILD_ROOTFS} qemu_x86_GL_defconfig
	cd ${BUILD_ROOTFS}
	make $@ ${FLAGS}
	cd ${CURRENT_DIR}
}

function fs_orange()
{
	echo ">>>Starting to build the FS"
	cd ${FS_PATH}
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- O=${BUILD_ROOTFS} orangepi_one_GL_defconfig
	cd ${BUILD_ROOTFS}
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $@ ${FLAGS}
	cd ${CURRENT_DIR}
}


function mashine()
{
	echo "Runing machine"

	qemu-system-i386 \
	-kernel ${BUILD_KERNEL}/arch/x86/boot/bzImage \
	-append "root=/dev/sda" \
	-hda ${BUILD_ROOTFS}/images/rootfs.ext3 \
	-redir tcp:8022::22 &

	gnome-terminal&
}

function upload_to_user()
{
	if [ -z $1 ]; then
		echo "You must pass a filename!"
	else
		echo "uploading $1 to user"
		sshpass -p "pass" scp $1 qemu:/home/user
		if [ $? ]; then
			echo "OK"
		else
			echo "Fail"
		fi
	fi
}

echo
echo
echo "fs() 				: Build root fs"
echo "fs() clean 			: Clean root fs"
echo "kernel() 			: Build kernel"
echo "kernel_orange()			: Build kernel for Orange Pi One"
echo "kernel() clean			: Clean build kernel"
echo "mashine()			: Start virtual mashine"
echo "upload_to_user() file.ko	: Upload file to user folder"
echo
echo