#!/bin/bash

CURRENT_DIR=$(pwd)
export KERN_PATH=${CURRENT_DIR}/kernel
export BUILD_KERNEL=${CURRENT_DIR}/out/kernel

export FS_PATH=${CURRENT_DIR}/buildroot
export BUILD_ROOTFS=${CURRENT_DIR}/out/fs


function kernel_qemu()
{
	echo
	echo ">>>Starting to build the kernel"
	echo
	cd ${KERN_PATH}
	make ARCH=i386 O=${BUILD_KERNEL}_qemu defconfig
	cd ${BUILD_KERNEL}_qemu
	make $@ -j4
	cd ${CURRENT_DIR}
}

function kernel_orange()
{
	echo
	echo ">>>Starting to build the kernel"
	echo
	cd ${KERN_PATH}
	make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- O=${BUILD_KERNEL}_orange sunxi_gl_defconfig
	cd ${BUILD_KERNEL}_orange
	make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $@ -j4
	if [ -z $@ ] 
	then
		echo
		echo ">>>Starting to build modules"
		echo
		make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules -j4
		make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install INSTALL_MOD_PATH=${BUILD_KERNEL}_orange_modules -j4
	fi
	cd ${CURRENT_DIR}
}

function fs_qemu()
{
	echo
	echo ">>>Starting to build the FS"
	echo
	cd ${FS_PATH}
	make O=${BUILD_ROOTFS}_qemu qemu_x86_GL_defconfig
	cd ${BUILD_ROOTFS}_qemu
	make $@ ${FLAGS}
	cd ${CURRENT_DIR}
}

function fs_orange()
{
	echo
	echo ">>>Starting to build the FS"
	echo
	cd ${FS_PATH}
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- O=${BUILD_ROOTFS} orangepi_one_GL_defconfig
	cd ${BUILD_ROOTFS}
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $@ ${FLAGS}
	cd ${CURRENT_DIR}
}


function mashine()
{
	echo
	echo "Runing machine"
	echo

	qemu-system-i386 \
	-kernel ${BUILD_KERNEL}_qemu/arch/x86/boot/bzImage \
	-append "root=/dev/sda" \
	-hda ${BUILD_ROOTFS}_qemu/images/rootfs.ext3 \
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
echo "fs_qemu() 			: Build root fs for QEMU x86"
echo "fs_orange() 			: Build root fs for Orange Pi One"
echo "---------------------------------------------------------------"
echo "kernel_qemu() 			: Build kernel for QEMU x86"
echo "kernel_orange()			: Build kernel for Orange Pi One"
echo "---------------------------------------------------------------"
echo "mashine()			: Start virtual mashine QEMU x86"
echo "upload_to_user() file.ko	: Upload file to user folder"
echo
echo