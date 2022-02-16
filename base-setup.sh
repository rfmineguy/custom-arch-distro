#variables
# linux-hostname
# linux-username
# linux-install-drive

if [[ $OS_TYPE != "linux-gnu"* ]]; then
    echo "This script will only run properly on fresh install of arch linux"
    echo "Running this on anything other than arch linux is not recommended, exitting script"
    echo "Seriously don't run this on anything you care about, severe work in progress"
    echo "AND DO NOT JUST COMMENT OUT THIS SAFEGUARD, its here because this script can erase your drives if your not careful"
    exit 4
fi

introduction() {
    echo "Welcome to my Arch Linux install script!!"
    echo "Just a few steps and we'll be off!"
    echo "  This script will : "
    echo "      1. Setup the linux user"
    echo "      2. Partition the drives correctly"
    echo "      3. Setup wifi and timezones"
    echo "  Run the other scripts to complete the full installation of the distro"
}

retrieve_user_data() {
    echo "Retrieving user data now"
    read -p 'Please enter your arch linux hostname : ' linux_hostname
    read -p 'Please enter your arch linux username : ' linux_username
    
    fdisk -l
    read -p 'Please enter your installation drive : ' linux_install_drive

    echo "Username : ${linux_hostname}"
    echo "Hostname : ${linux_hostname}"
    echo "Install drive : ${linux_install_drive}"
}

partition_drives() {
    echo "The drive will have three partitions"
    echo " /dev/sda1 - EFI Boot"
    echo " /dev/sda2 - SWAP"
    echo " /dev/sda3 - /home"
    echo "This will wipe the selected drive, are you sure you want to continue"
    
    #delete existing partitions
    (
        echo d;
        echo d;
        echo d;
        echo d;
        echo w;
    ) | sudo fdisk /dev/sda
    
    #create fresh new partitions
    (
                    #dev/sda1
        echo n;     #new partition
        echo p;     #primary
        echo ;      #<enter> (default)
        echo ;      #<enter> (default)
        echo +550M; #550mb boot space
        echo t;     #change partition type
        echo ;      #use default (1)
        echo ef;    #uefi
    
        echo n;    
        echo p;     
        echo ;
        echo ;
        echo +2G;   #2 gig swap space
        echo t;     #change partition type
        echo ;      #use default (2)
        echo 82;    #swap space
    
        echo n;
        echo p;
        echo ;      #<enter> (default)
        echo ;      #<enter> (default)
        echo ;      #use rest of disk for main partition
        echo t;     #change partition type
        echo ;      #use default (3)
        echo 83;    #linux
    
        echo w;
    ) | sudo fdisk /dev/sda
    
    read -p 'Listing current partition mapping. Confirm this is correct. (y/n) ' promptConfirmed
    echo "$promptConfirmed"
}

setup_base() {
    echo "Setting up the basic arch linux install"
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt

    ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
    hwclock --systohc
    pacman -S vim
    
    #set up locales
    #vim /etc/locale.gen            (how to automate this?)
    echo "Setting locale to en_us, to override change /etc/locale.gen manually and run locale-gen"
    echo "LANG=en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen

    #set up hosts file
    echo "
    127.0.0.1	localhost
	::1		localhost
	127.0.1.1	${linux_username}.localdomain   ${linux_username}	
    " >> /etc/hosts

    echo "============================================"
    echo "Setting up user"
    echo "============================================"
    passwd
    useradd -m ${linux_username}
    passwd ${linux_username}

    usermod -aG wheel,audio,video,optical,storage ${linux_username}

    pacman -S sudo
    visudo

    echo "============================================"
    echo "Setting up grub, and other programs that allow the system to boot"
    echo "============================================"
    pacman -S grub efibootmgr dosfstools os-prober mtools
    mkdir /boot/EFI
    mount /dev/sda1 /boot/EFI

    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    grub-mkconfig -o /boot/grub/grub.cfg

    echo "============================================"
    echo "Setting up networking and git"
    echo "============================================"
    pacman -S networkmanager git
    systemctl enable NetworkManager

    echo "Finished with initial setup"
    exit

    umount -l /mnt

    echo "Now reboot and remove the installation media to boot into your freshly installed arch linux"
}

#call the introduction function
introduction

#call the retrieve_user_data function
retrieve_user_data

#call the partition_drives functions
partition_drives

#time to set up the base installation
setup_base

#fdisk -l        #list the partitions created
pause
