#!/bin/bash
####################################################################
# BEGIN LICENSE                                                    #
# Copyright MMPOS 2025 <support@mmpos.eu>                          #
# END LICENSE                                                      #
####################################################################
####################################################################
# SUPPORTED:						           #
#   Ubuntu      14.04+ based distros				   #
####################################################################

# -- Check if mining distro is supported for overwriting first
[ -r /etc/os-release ] && . /etc/os-release

if [[ "$VERSION_ID" =~ ^(14|16|18|20|22|24)\.04$ ]]; then
    echo "Your ubuntu version is: $VERSION_ID"
else
    echo  "You are running unsupported linux distribution! Exiting..." && exit
fi

if [ "$EUID" -ne 0 ]; then
    echo "This script should be run as root, not user!"
    echo "Type:"
    echo "sudo su -"
    echo "cd /tmp; wget https://raw.githubusercontent.com/ddobreff/mmpos/refs/heads/main/scripts/mmp_rewrite.sh; chmod +x mmp_rewrite.sh"
    echo "./mmp_rewrite.sh"
    exit
fi

# -- COLORS
BLACK='\033[0;30m'
DGRAY='\033[1;30m'
RED='\033[0;31m'
BRED='\033[1;31m'
GREEN='\033[0;32m'
BGREEN='\033[1;32m'
YELLOW='\033[0;33m'
BYELLOW='\033[1;33m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
PURPLE='\033[0;35m'
BPURPLE='\033[1;35m'
CYAN='\033[0;36m'
BCYAN='\033[1;36m'
LGRAY='\033[0;37m'
WHITE='\033[1;37m'
BLINK='\033[33;5;7m'
NOCOLOR='\033[0m'

# -- MMP Virtual Filesystem
MMPVFS="mmp2fs"
MMPVFS_CFG_START="503808"
MMPVFS_CFG_COUNT="38912"
MMPVFS_LOG="/tmp/mmp2fs.log"

# -- Console nice loggers --
function infologger() {
    test -t 1 && echo -e "${DGRAY}<< `date +%Y.%m.%d-%H:%M:%S` >>${NOCOLOR} $*"
}

# -- Active interface
iiface=$(/sbin/ip -o link show |awk '{print $2,$9}' |grep "UP" |sed 's/://g' | awk '{print $1}' |head -n1)
if [[ -z $iiface ]]; then
    iiface="eth0"
fi

# -- Sanity check for internet access
function check_connection_status() {
    #  -- Performing sanity check for aquired IP Address --
    while [ 1 ]; do
        if [ $(ip add sh dev $iiface | grep "inet "| wc -l) -ne 0 ]; then
            break
        fi
        sleep 1
    done
    # -- IP Address aquired --
    checknetwork=$1
    while [ $checknetwork -ne 0 ]; do
        `which nc` -z "$2" "$3" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo 0
            return
        fi
        let checknetwork-=1
        sleep 1
    done
    echo 1
}

# -- Check for installed package
function chk_pkg_installed() {
    pkg_name=$1
    if [ $(dpkg-query -W -f='${Status}' $pkg_name 2>/dev/null | grep -c "ok installed") -ne 0 ]; then
        return 0
    else
        return 1
    fi
}
# -- Prepare for overwriting current system
function mmp_prep_image() {
    if
    [ $(free -m | grep Mem | awk '{ print $2 }') -lt 3000 ] && infologger "${RED} Error: not enough memory. At least 4GB RAM is required ${NOCOLOR}" && exit
    [ $(which lsof | wc -l) == 0 ] && infologger "${RED} Error: lsof not found. Make sure You have curl installed. For example apt-get install lsof ${NOCOLOR}" exit 0
    NVME=$(ls -l /sys/block/ | awk '$11 != "" && $11 !~ "^../devices/virtual" { print $9; }' |grep "^nvme")
    SATA=$(ls -l /sys/block/ | awk '$11 != "" && $11 !~ "^../devices/virtual" { print $9; }' |grep "^sd")
    ROOT_DEVICE=$(mount -v | fgrep 'on / ' |awk '{print $1}')
    # Double check the device for SATA/USB
    if [[ "$ROOT_DEVICE" =~ "sd" ]] && [[ "$SATA" =~ "sd" ]]; then
        DEVICE=$(echo "$ROOT_DEVICE" |sed 's/\([[:digit:]]\)//')
        infologger "${GREEN} Found SATA/USB interface device: ${DEVICE} ${NOCOLOR}"
        # Double check the device for NVME
    elif [[ "$ROOT_DEVICE" =~ "nvme" ]] && [[ "$NVME" =~ "nvme" ]]; then
        DEVICE=$(echo "$ROOT_DEVICE" |awk '{print $1}' |cut -d p -f1)
        infologger "${YELLOW} Found NVME interface device: ${DEVICE} !!! This is Experimental !!! ${NOCOLOR}"
    else
        infologger "${RED} Unknown device, bailing! ${NOCOLOR}"
        exit
    fi
    if ! chk_pkg_installed "exfat-fuse" || ! chk_pkg_installed "lsof"; then
        infologger "${CYAN} Exfat fuse is not installed! Installing now... ${NOCOLOR}"
        export DEBIAN_FRONTEND=noninteractive
        export DEBIAN_PRIORITY=critical
        if ! apt -y install exfat-fuse lsof >/dev/null 2>&1; then
            infologger "${RED} OS does not support automatic installs! ${NOCOLOR}"
            /usr/bin/wget -q http://launchpadlibrarian.net/130674098/exfat-utils_1.0.1-1_amd64.deb -O /tmp/exfat-utils_1.0.1-1_amd64.deb /dev/null 2>&1
            /usr/bin/wget -q http://launchpadlibrarian.net/130699386/exfat-fuse_1.0.1-1_amd64.deb -O /tmp/exfat-fuse_1.0.1-1_amd64.deb /dev/null 2>&1
            cd /tmp;
            if ! /usr/bin/dpkg -i exfat-utils_1.0.1-1_amd64.deb exfat-fuse_1.0.1-1_amd64.deb; then
                infologger "${RED} Giving up messing with ethOS... ${NOCOLOR}"
            fi
        fi
    fi
    then
        mmp_do_image $DEVICE
    else
        infologger "${RED} No can do that! ${NOCOLOR}"
    fi
}

# -- Check md5sum
function check_md5() {
    URL=$1
    IMAGE=$2
    if [[ "$IMAGE" =~ "mmp-latest" ]]; then
        MD5EXT="md5sum"
        VFS="${MMPVFS}"
    elif [[ "$IMAGE" =~ "${MMPVFS}" ]]; then
        MD5EXT="md5"
        VFS="./"
    else
        echo "Unsupported MD5 extension" && exit
    fi
    rem_md5="$(curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" -sL $URL/${IMAGE}.${MD5EXT}| cut -d ' ' -f 1)"
    loc_md5="$(md5sum /${VFS}/${IMAGE} | cut -d ' ' -f 1)"

    if [ "$rem_md5" == "$loc_md5" ]; then
        return 0
    else
        return 1
    fi
}

# -- Actual reimage process
function mmp_do_image() {
    DEVICE=$1
    read -r -p "Do you want to setup custom download URL(hit [Enter] if unsure)? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        read -p "Please input your custom url without mmp-latest.img.xz, ex: 'http://myimageurl.com/images/'#: " URL
    else
        infologger "${CYAN} No custom URL was specified, will use default...${NOCOLOR}"
    fi
    if [ -n "$URL" ]; then
        if [[ $(check_connection_status 5 $URL 80) -eq 0 ]]; then
            infologger "${GREEN} Good! Your custom URL is working ! ${NOCOLOR}"
        else
            URL="https://download.mmpos.eu/images"
            infologger "${BRED} Your custom URL isn't working - switching to default ! ${NOCOLOR}"
        fi
    else
        URL="https://download.mmpos.eu/images"
    fi
    # delete previously running enviroment if was runned
    infologger "${CYAN} Cleaning possible old virtual fs ${NOCOLOR}"
    # Check if we are running in chroot!
    if [[ ! -f "/mmp-init.sh" ]]; then
        umount /tmp/${MMPVFS}/proc >/dev/null 2>&1
        umount /tmp/${MMPVFS}/sys >/dev/null 2>&1
        umount /tmp/${MMPVFS}/dev >/dev/null 2>&1
        umount /tmp/${MMPVFS} >/dev/null 2>&1
        rm -rf /tmp/${MMPVFS} >/dev/null 2>&1
    else
        infologger "${RED} We are running in chroot! please exit chroot environment and restart the script! ${NOCOLOR}"
        exit
    fi
    infologger ""

    if [[ -f ${MMPVFS}.tar.xz ]] && [ $(check_md5 "$URL" "${MMPVFS}.tar.xz") ]; then
        infologger "${WHITE} mmp2fs already exists, skipping download! ${NOCOLOR}"
    else
        infologger "${CYAN} Downloading ${MMPVFS} from MMP repository... ${NOCOLOR}"
        if /usr/bin/curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" -kL -4 -# ${URL}/${MMPVFS}.tar.xz -o ${MMPVFS}.tar.xz
        then
            infologger "${GREEN} Successfully downloaded ${MMPVFS} from mirror ${NOCOLOR}"
        else
            infologger "${RED} Failed to download ${MMPVFS} from mirror, please restart process! ${NOCOLOR}"
            exit 1
        fi
        SRCMD5=$(curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" -sL $URL/${MMPVFS}.tar.xz.md5| cut -d ' ' -f 1)
        DSTMD5=$(md5sum ${MMPVFS}.tar.xz | awk '{ print $1 }')
        [ "$SRCMD5" != "$DSTMD5" ] && infologger "${RED} MD5 checksum doesn't match! Bailing! ${NOCOLOR}" && exit
    fi
    # create virtual enviroment in RAM
    infologger "${CYAN} Creating RAM disk... ${NOCOLOR}"
    /bin/mkdir -p /tmp/${MMPVFS}
    /bin/mount -t tmpfs -o size=2G none /tmp/${MMPVFS}
    /bin/tar xf ${MMPVFS}.tar.xz -C /tmp/
    sleep 0.5
    infologger "${CYAN} Mounting devfs, procfs and sysfs ${NOCOLOR}"
    mount -t proc proc /tmp/${MMPVFS}/proc >/dev/null 2>&1
    mount -o bind /sys  /tmp/${MMPVFS}/sys >/dev/null 2>&1
    mount -o bind /dev  /tmp/${MMPVFS}/dev >/dev/null 2>&1
    echo ${DEVICE} > /tmp/${MMPVFS}/DEVICE
    echo ${MMPVFS_CFG_START} > /tmp/${MMPVFS}/SEEK

    echo mmp-latest.img.xz > /tmp/${MMPVFS}/IMAGE
    # -- Downloading image to ${MMPVFS}
    if [ -f /tmp/${MMPVFS}/"mmp-latest.img.xz" ] && [ $(check_md5 "$URL" "mmp-latest.img.xz") ]; then
        infologger "${WHITE} Image already exists, skipping download! ${NOCOLOR}"
    else
        infologger "${CYAN} Downloading MMP image from $URL ${NOCOLOR}"
        if /usr/bin/curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" -kL -4 -# ${URL}/mmp-latest.img.xz -o /tmp/${MMPVFS}/mmp-latest.img.xz; then
            infologger "${GREEN} Successfully downloaded image from mirror ${NOCOLOR}"
        else
            infologger "${RED} Failed to download image from mirror, please restart process! ${NOCOLOR}"
            exit 1
        fi
        SRCMD5=$(curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" -sL $URL/mmp-latest.img.xz.md5sum| cut -d ' ' -f 1)
        DSTMD5=$(md5sum /tmp/${MMPVFS}/mmp-latest.img.xz | awk '{ print $1 }')
        [ "$SRCMD5" != "$DSTMD5" ] && infologger "${RED} MD5 checksum doesn't match! Bailing! ${NOCOLOR}" && exit
    fi
    # --
    infologger "${GREEN} Preparing config partition... ${NOCOLOR}"
    /bin/mkdir -p /tmp/${MMPVFS}/cfg
    xzcat /tmp/${MMPVFS}/mmp-latest.img.xz | dd of=/tmp/${MMPVFS}/config.img skip=${MMPVFS_CFG_START} count=${MMPVFS_CFG_COUNT} >/dev/null 2>&1
    if /bin/mount -o loop /tmp/${MMPVFS}/config.img /tmp/${MMPVFS}/cfg
    then
        # Basic autoconf.txt setup
        if [[ -z "${RIG_CODE}" ]]; then
            infologger "${CYAN} We need you to enter your ${NOCOLOR}${GREEN}Rig Code${NOCOLOR}${CYAN} from dashboard ${NOCOLOR}"
            until [[ $RIG_CODE =~ ^[0-9] ]]; do
                read -r -p "MMP Rig Code : " RIG_CODE
                echo
                read -r -p "Verify your MMP Rig Code : " RIG_CODE2
                while [ $RIG_CODE != $RIG_CODE2 ]; do
                    echo
                    infologger "${RED} Rig Code does not match! Please try again! ${NOCOLOR}"
                    read -r -p "MMP Rig Code : " RIG_CODE
                    echo
                    read -r -p "Verify your MMP Rig Code : " RIG_CODE2
                done
            done
            echo "RIG_CODE=${RIG_CODE}" > /tmp/${MMPVFS}/cfg/autoconf.txt
        else
            echo "RIG_CODE=${RIG_CODE}" > /tmp/${MMPVFS}/cfg/autoconf.txt
        fi
        sleep 0.5
        infologger "${RED} Your password will be set to default 'mmpOS', make sure you change it on first login! ${NOCOLOR}"
    else
        infologger "${RED} Please restart reimage, we were unable to mount config partition! ${NOCOLOR}"
        exit
    fi
    # End
    umount  /tmp/${MMPVFS}/cfg
    infologger "${CYAN} Flushing buffers... ${NOCOLOR}"
    sync
    #################################################
    # Actual checking starts here
    #################################################
    infologger "${CYAN} Stopping some system processes... ${NOCOLOR}"
    if [ ! -f "/opt/ethos/etc/version" ]; then
        screen -ls | egrep "^\s*[0-9]+.miner" | awk -F "." '{print $1}' | xargs kill -9 2>/dev/null
        su miner -c 'screen -wipe'
    fi
    if [ -f "/opt/ethos/etc/version" ]; then
        minestop && disallow
        mv -f /usr/bin/Xorg /usr/bin/Xorg.disable 2>/dev/null
        mv -f /usr/bin/X /usr/bin/X.disable 2>/dev/null
        mv -f /usr/bin/php /usr/bin/php.disable 2>/dev/null
        bash -c '/etc/init.d/udev stop'
        bash -c '/etc/init.d/acpid stop'
        bash -c '/etc/init.d/x11-common stop'
    fi
    i=1; while [ $i -lt 10 ]; do
        killall -9 Xorg 2>/dev/null
        killall -9 ssh-agent 2>/dev/null
        i=$((i+1))
    done

    i=1; while [ $i -lt 1000 ]; do
        ps ax | grep -v "mmp_rewrite" | grep -v "sshd: ethos" |grep -v "tmate" | grep -e "php\|ethos\|cron\|shellin\|Xorg\|xfce4\|at\|menu-cached\|conky\|irqbalance\|thermald\|dbus\|udev\|xfce4\|rsyslogd\|nodm\|udev\|acpid\|php\|atisetup\|Xorg" | awk '{ print $1 }' | xargs kill -9
        i=$((i+1))
    done

    swapoff -a 2>/dev/null

    lsof / | grep -v "mem\|txt\|rtd\|cwd" | awk '$4~/w/ || $4~/u/ { print $2 }' | xargs kill -9
    lsof / | grep -v "mem\|txt\|rtd\|cwd" | awk '$4~/w/ || $4~/u/ { print $2 }' | xargs kill -9
    lsof / | grep -v "mem\|txt\|rtd\|cwd" | awk '$4~/w/ || $4~/u/ { print $2 }' | xargs kill -9
    lsof / | grep -v "mem\|txt\|rtd\|cwd" | awk '$4~/w/ || $4~/u/ { print $2 }' | xargs kill -9
    [[ -f /proc/sys/kernel/hung_task_timeout_secs ]] && echo 0 > /proc/sys/kernel/hung_task_timeout_secs 2> /dev/null
    sysctl vm.dirty_bytes=600000000            1> /dev/null 2> /dev/null
    sysctl vm.dirty_background_bytes=300000000 1> /dev/null 2> /dev/null
    if [ -d /root/utils ]; then
        mv -f /root/utils/force_reboot.sh    /root/utils/force_reboot.sh.disable    2> /dev/null
        mv -f /root/utils/force_shutdown.sh  /root/utils/force_shutdown.sh.disable  2> /dev/null
        mv -f /root/utils/watchdog_system.sh /root/utils/watchdog_system.sh.disable 2> /dev/null
    fi
    if [ -d /hive ]; then
        miner stop
        crontab -r
        systemctl stop hive-watchdog.service
        systemctl stop hive.service
        systemctl stop hive-console.service
        systemctl stop avg_khs.service
        systemctl stop hivex.service
        echo "V" > /dev/watchdog
        screen -ls | grep -E "^\s*[0-9]+.[a-z_A-Z]" | grep -v "Sockets"| awk -F "." '{print $1}' | xargs kill -9
    fi
    sync
    # Actual process of rewriting
    infologger "${CYAN} Remounting root filesystem in R/O mode ${NOCOLOR}"
    /bin/mount | grep $DEVICE
    HDD=$(mount | grep "^${DEVICE}" | awk '{ print $3 }')
    for d in ${HDD}; do
        mount -o remount,ro $d
    done
    echo u > /proc/sysrq-trigger
    HDD=$(mount | grep "^${DEVICE}" | awk '{ print $3 }')
    for d in ${HDD}; do
        mount -o remount,ro $d
    done
    echo u > /proc/sysrq-trigger

    infologger "${CYAN} Status of root filesystems after remount  - should be RO - read-only ${NOCOLOR}"
    mount | grep "$DEVICE"
    MOUNT_RO=$(cat /proc/mounts | grep " / " | awk '{ print $4 }' | tr "," "\n" | grep "^rw$" | head -n 1 | wc -l)
    if [ "$MOUNT_RO" == 1 ]; then
        infologger  "${RED} Error root partion seems to be stil read-write mounted. Please if possible send screenshot of this screen to us ${NOCOLOR}"
        mv -f /usr/bin/Xorg.disable /usr/bin/Xorg
        mv -f /usr/bin/X.disable /usr/bin/X
        mv -f /usr/bin/php.disable /usr/bin/php
        sync
        exit
    fi
    infologger "${BRED} Switching to virtual enviroment... ${NOCOLOR}"
    cd /tmp/${MMPVFS}
    setsid chroot ./ /bin/sh /mmp-init.sh > /tmp/rewrite.log 2>&1 &
    infologger "${BRED} MMP Rewrite is running in the background. Logs are being written to /tmp/write.log. ${NOCOLOR}"
    infologger "${BRED} Displaying log output (press Ctrl+C to stop viewing logs without stopping the process): ${NOCOLOR}"
    tail -f /tmp/rewrite.log
}
# Execute the image process
mmp_prep_image
