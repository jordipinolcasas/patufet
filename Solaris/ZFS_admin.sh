




#NFS SERVER - 
svcs network/nfs/server
share -F NFS {DIR}
zfs set mountpoint={dir} {dataset}
zfs set sharenfs=on {dataset}
zfs set share.nfs.rw=\* {dataset}
zfs get share





