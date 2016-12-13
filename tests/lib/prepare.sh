#!/bin/bash
. $TESTSLIB/utilities.sh

echo "Wait for firstboot change to be ready"
while ! snap changes | grep -q "Done"; do
	snap changes || true
	snap change 1 || true
	sleep 1
done

echo "Ensure fundamental snaps are still present"
. $TESTSLIB/snap-names.sh
for name in $gadget_name $kernel_name $core_name; do
	if ! snap list | grep -q $name ; then
		echo "Not all fundamental snaps are available, all-snap image not valid"
		echo "Currently installed snaps:"
		snap list
		exit 1
	fi
done

echo "Kernel has a store revision"
snap list | grep ^${kernel_name} | grep -E " [0-9]+\s+canonical"

snap_install network-manager

# Snapshot of the current snapd state for a later restore
if [ ! -f $SPREAD_PATH/snapd-state.tar.gz ] ; then
	systemctl stop snapd.service snapd.socket
	tar czf $SPREAD_PATH/snapd-state.tar.gz /var/lib/snapd /etc/netplan
	systemctl start snapd.socket
fi

# And also snapshot NetworkManager's state
if [ ! -f $SPREAD_PATH/nm-state.tar.gz ]; then
	systemctl stop snap.network-manager.networkmanager
	tar czf $SPREAD_PATH/nm-state.tar.gz /var/snap/network-manager
	systemctl start snap.network-manager.networkmanager
fi

# Make sure the original netplan configuration is applied and active
netplan generate
netplan apply

# For debugging dump all snaps and connected slots/plugs
snap list
snap interfaces
