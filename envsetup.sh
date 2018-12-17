#!/bin/bash

CURRENT_DIR=$(pwd)
#kernel sources
export KERN_SRC_PATH=${CURRENT_DIR}/kernel
#output filder
export OUT=${CURRENT_DIR}/out

#Objects
export BUILD_KERNEL=${OUT}/kernel

#Ouptups kernel, modules, DT
export DT_OUT_PATH=${OUT}/release
export KERN_OUT_PATH=${OUT}/release
export MOD_OUT_PATH=${OUT}/release

#Outputs FS
export FS_PATH=${CURRENT_DIR}/buildroot
export BUILD_ROOTFS=${OUT}/fs

export WORKER=$(grep -c ^processor /proc/cpuinfo)

function kernel_qemu()
{
	echo
	echo ">>> Build the kernel for QEMU x86 in ${WORKER} threads"
	echo
	cd ${KERN_SRC_PATH}
	#Configuring
	make ARCH=i386 O=${BUILD_KERNEL}_qemu i386_gl_defconfig
	cd ${BUILD_KERNEL}_qemu
	#compile or clean
	make ARCH=i386 $@ -j${WORKER}
	cd ${CURRENT_DIR}
}

function orange()
{
	echo
	echo ">>> Build the kernel for Orange Pi One in ${WORKER} threads"
	echo
	cd ${KERN_SRC_PATH}
	#configure
	make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- O=${BUILD_KERNEL}_orange sunxi_gl_defconfig
	cd ${BUILD_KERNEL}_orange
	#compile or clean
	make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $@ -j${WORKER}

	#if not clean the install all
	if [ -z $@ ] 
	then
		echo
		echo ">>> Install kernel"
		echo
		mkdir -p ${KERN_OUT_PATH}
		make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- install INSTALL_PATH=${KERN_OUT_PATH}
		cp ${BUILD_KERNEL}_orange/arch/arm/boot/zImage ${KERN_OUT_PATH}/
		echo
		echo ">>> Build modules"
		echo
		#make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules -j4
		make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install INSTALL_MOD_PATH=${MOD_OUT_PATH}
		echo
		echo ">>> Install DTB"
		echo
		make LOCALVERSION="" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs_install INSTALL_PATH=${DT_OUT_PATH}

	fi
	cd ${CURRENT_DIR}
}

function fs_qemu()
{
	echo
	echo ">>> Build QEMU x86 FS"
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
	echo ">>> Start QEMU x86 machine"
	echo

	qemu-system-i386 \
	-kernel ${BUILD_KERNEL}_qemu/arch/x86/boot/bzImage \
	-append "root=/dev/sda" \
	-hda ${BUILD_ROOTFS}_qemu/images/rootfs.ext3 \
	-redir tcp:8022::22 &

	gnome-terminal&
}

function upload_to_qemu()
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

function upload_to_pi()
{
	if [ -z $1 ]; then
		echo "You must pass a filename!"
	else
		echo "uploading $1 to user"
		sshpass -p "0000" scp $1 pi:/home/alex/desktop
		if [ $? ]; then
			echo "OK"
		else
			echo "Fail"
		fi
	fi
}

function dtomake()
{
	if [ -z $@ ]
	then
	echo "PASS THE FILENAME!"
	return 1;
	fi

	LOCAL_DIR=$(pwd)
	#get filename without extension
	NAME=`echo "$@" | cut -d'.' -f1`

	#preparsing
	cpp -nostdinc -I ${KERN_SRC_PATH}/include -undef -x assembler-with-cpp  $@ ${NAME}.preprocessed

	#compile
	dtc -@ -I dts -O dtb  ${NAME}.preprocessed -o ${NAME}.dtbo

	#delete preparing
	rm ${NAME}.preprocessed

	echo "COMPLETE!"
}

echo
echo "==============================================================="
echo "kernel_qemu() 		  : Build kernel for QEMU x86"
echo "orange()		  : Build kernel, modules, DT for Orange Pi One"
echo "---------------------------------------------------------------"
echo "fs_qemu() 		  : Build root fs for QEMU x86"
echo "---------------------------------------------------------------"
echo "mashine()		  : Start virtual mashine QEMU x86"
echo "upload_to_qemu() file.ko  : Upload file to QEMU"
echo "upload_to_pi() file.ko    : Upload file to OrangePi One"
echo "dtomake()		  : Compile DT Overlay"
echo "==============================================================="
echo