# NFS Setup
sudo ufw disable
sudo apt install nfs-common -y
mkdir -p ~/client_nfs_share
sudo mount master:/home/dev/nfs_share ~/client_nfs_share
mount | grep client_nfs_share

echo $(hostname) > ~/client_nfs_share/$(hostname).txt

sleep 5
#sudo fuser -kim /mnt/hgfs/tmp/client_nfs_share
sudo umount ~/client_nfs_share/
mount | grep client_nfs_share