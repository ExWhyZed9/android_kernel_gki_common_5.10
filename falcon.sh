#!/bin/bash

#set -e

 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##

DIR=`readlink -f .`
MAIN=`readlink -f ${DIR}/..`
export CLANG_PATH=$MAIN/clang-r416183b/bin
export PATH=${BINUTILS_PATH}:${CLANG_PATH}:${PATH}
make -j8 CC='ccache clang' ARCH=arm64 LLVM=1 LLVM_IAS=1 O=out gki_defconfig

THREAD="-j$(nproc --all)"

# Basic Information
DEFCONFIG="gki_defconfig"

DEVICE=xaga

DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")

TANGGAL=$(date +"%F%S")

ANYKERNEL3_DIR=$PWD/AnyKernel3/

FINAL_KERNEL_ZIP=Falcon-X-${DEVICE}-${TANGGAL}.zip

# Verbose Build
VERBOSE=0
##----------------------------------------------------------##

# Exports

export CLANG_PATH=$MAIN/clang-r416183b/bin/
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=$MAIN/clang-r416183b/bin/aarch64-linux-gnu- CC=clang CXX=clang++

export ARCH=arm64
export SUBARCH=$ARCH
export KBUILD_BUILD_USER=Priyanshu

# Speed up build process
MAKE="./makeparallel"

##----------------------------------------------------------##

# Start build
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Clean build always lol
echo -e "$red***********************************************"
echo "          STARTING THE ENGINE         "
echo -e "***********************************************$nocol"
echo -e "$yellow***********************************************"
echo "         CLEANING, PLEASE WAIT A BIT         "
echo -e "***********************************************$nocol"
mkdir -p out
make O=out clean

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING Falcon-X KERNEL          "
echo -e "***********************************************$nocol"

mkdir -p out
make O=out clean

make CC="ccache clang" CXX="ccache clang++" LLVM=1 LLVM_IAS=1 O=out $DEFCONFIG
make CC='ccache clang' CXX="ccache clang++" LLVM=1 LLVM_IAS=1 O=out $THREAD \
    CONFIG_MEDIATEK_CPUFREQ_DEBUG=m CONFIG_MTK_IPI=m CONFIG_MTK_TINYSYS_MCUPM_SUPPORT=m \
    CONFIG_MTK_MBOX=m CONFIG_RPMSG_MTK=m CONFIG_LTO_CLANG=y CONFIG_LTO_NONE=n \
    CONFIG_LTO_CLANG_THIN=y CONFIG_LTO_CLANG_FULL=n 2>&1 CONFIG_KSU=y | tee kernel.log

##----------------------------------------------------------##

# Verify Files

echo "**** Verify Image.gz & dtbo.img ****"
ls $PWD/out/arch/arm64/boot/Image.gz
ls $PWD/out/arch/arm64/boot/dtbo.img
ls $PWD/out/arch/arm64/boot/dtb.img

       if ! [ -a "$PWD/out/arch/arm64/boot/Image.gz" ];
          then
              echo -e "$blue***********************************************"
              echo "          BUILD THROWS ERRORS         "
              echo -e "***********************************************$nocol"
              rm -rf out/
              for i in *.log
              do
              curl -F "document=@$i" --form-string "caption=" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}&parse_mode=HTML"
              done
              rm -rf error.log
              exit 1
          else
             echo -e "$blue***********************************************"
             echo "    KERNEL COMPILATION FINISHED, STARTING ZIPPING         "
             echo -e "***********************************************$nocol"
             rm -rf error.log 
       fi

##----------------------------------------------------------##

# Anykernel 3 time!!
echo "**** Verifying AnyKernel3 Directory ****"
ls $ANYKERNEL3_DIR
echo "**** Removing leftovers ****"
rm -rf $ANYKERNEL3_DIR/Image.gz
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/dtb.img
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP

echo "**** Copying Image.gz & dtbo.img ****"
cp $PWD/out/arch/arm64/boot/Image.gz $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtb.img $ANYKERNEL3_DIR/

echo -e "$cyan***********************************************"
echo "          Time to zip up!          "
echo -e "***********************************************$nocol"
cd $ANYKERNEL3_DIR/
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP

echo -e "$yellow***********************************************"
echo "         Done, here is your sha1         "
echo -e "***********************************************$nocol"
cd ..
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANYKERNEL3_DIR/Image.gz
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/dtb.img
rm -rf out/
rm -rf kernel.log

sha1sum $FINAL_KERNEL_ZIP

##----------------------------------------------------------##
##----------------------------------------------------------##
##----------------------------------------------------------##

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"

##----------------------------------------------------------##
##----------------------------------------------------------##
##----------------------------------------------------------##

echo -e "$red***********************************************"
echo "         Uploading to telegram         "
echo -e "***********************************************$nocol"

# Upload Time!!
for i in *.zip
do
curl -F "document=@$i" --form-string "caption=" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}&parse_mode=HTML"
done

echo -e "$cyan***********************************************"
echo "          All done !!!         "
echo -e "***********************************************$nocol"
##----------------------------------------------------------##
##----------------------------------------------------------##
##----------------------------------------------------------##
