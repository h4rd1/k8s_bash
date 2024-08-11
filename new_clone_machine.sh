#!/bin/sh
#
# Script changing the machine-id of a system
#
# KCS: https://access.redhat.com/solutions/3600401
#
# Author: Renaud Métrich <rmetrich@redhat.com>
#
# Run instructions:
#     # ./kcs3600401.sh [ MACHINE-ID ]
#
# The script will use systemd-machine-id-setup unless a machine-id is specified
# as first argument.
# The script will restore everything on error.

set -e

RESTORE_CMDS=()

restore_on_error() {
	set +e
	echo "Error detected, restoring original files!" >&2
	for cmd in "${RESTORE_CMDS[@]}"; do
		echo "Executing: $cmd"
		eval $cmd
	done
	echo "Exiting on error" >&2
	exit 2
}

trap restore_on_error ERR

if [ -n "$1" ] && ! echo -n "$1" | grep -q -E '^[0-9a-f]{32}$'; then
    echo "ERROR: specified machine-id is not a valid machine-id, it should exact contain 32 hexadecimal digits" >&2
    exit 1
fi

# Step 1
echo "STEP 1 - collecting original machine-id"
OLDM=$(cat /etc/machine-id)
echo "Original machine-id: $OLDM"

# Step 2
echo "STEP 2 - backing up original machine-id"
mv /etc/machine-id /etc/machine-id.kcs3600401
RESTORE_CMDS+=( "mv /etc/machine-id.kcs3600401 /etc/machine-id" )

# Step 3
echo "STEP 3 - assigning new machine-id"
if [ -n "$1" ]; then
    echo "$1" > /etc/machine-id
else
    systemd-machine-id-setup
fi
NEWM=$(cat /etc/machine-id)
echo "New machine-id: $NEWM"

if [ $OLDM == $NEWM ]; then
    echo "INFO: original and new machine-id are identical, nothing to do"
    rm /etc/machine-id.kcs3600401
    exit 0
fi

# Step 4
echo "STEP 4 - fixing Grub configuration files"
for file in $(find /boot/loader/entries -name "$OLDM-*"); do
    cp $file $file.kcs3600401 && sed -i "s/$OLDM/$NEWM/" $file && mv $file $(echo "$file" | sed "s/$OLDM/$NEWM/")
    RESTORE_CMDS+=( "mv $file.kcs3600401 $file" )
done
for file in /etc/grub2.cfg /etc/grub2-efi.cfg; do
    [ -e $file ] || continue
    cp $file $file.kcs3600401 && sed -i "s/$OLDM/$NEWM/" $file
    RESTORE_CMDS+=( "mv $file.kcs3600401 $file" )
done

# Step 5
echo "STEP 5 - fixing Grub environment file"
mv /boot/grub2/grubenv /boot/grub2/grubenv.kcs3600401
RESTORE_CMDS+=( "mv /boot/grub2/grubenv.kcs3600401 /boot/grub2/grubenv" )
grub2-editenv /boot/grub2/grubenv create
for line in $(grub2-editenv /boot/grub2/grubenv.kcs3600401 list); do
    grub2-editenv /boot/grub2/grubenv set "$(echo "$line" | sed "s/$OLDM/$NEWM/")"
done

# Step 6
echo "STEP 6 - regenerating all initramfs files"
for file in $(/bin/ls -1 /boot/initramfs-*.$(uname -m).img); do
    mv $file /root/$(basename $file).kcs3600401
    RESTORE_CMDS+=( "mv /root/$(basename $file).kcs3600401 $file" )
done
echo "Regenerating the initramfs files, this may take some time..."
dracut --regenerate-all

# Step 7
echo "STEP 7 - fixing rescue kernel and initramfs files"
for file in $(/bin/ls -1 /boot/vmlinuz-*-$OLDM /boot/initramfs-*-$OLDM.img 2>/dev/null); do
    cp $file /root/$(basename $file).kcs3600401 && mv $file $(echo $file | sed "s/$OLDM/$NEWM/")
    RESTORE_CMDS+=( "mv $(echo $file | sed "s/$OLDM/$NEWM/") $file" )
done

# Step 8
echo "STEP 8 - rebooting"
echo "All done, please reboot manually ..."

# Step 9
echo "STEP 9 - after reboot"
echo "You may run the following command to delete the backup files:"
echo rm $(find /boot /root -name "*.kcs3600401")

exit 0

# vi: set autoindent expandtab softtabstop=4 shiftwidth=4 :
