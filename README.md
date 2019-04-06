# Linux Config Scripts

The main purpose of this repository is to contain Linux shell scripts
that can be triggered on system without needing to have a bunch of dependencies.
Only requirements that you should have is `bash` and `wget` command
and in most cases internet connection.

## Examples
You can use the following syntax to execute scripts:
```
bash <(wget -O - https://.../linux-config-scripts/master/debian-post-install/openvpn.sh)
```

You can also use this syntax to execute a script that doesn't require any interaction:
```
wget -O - https://.../linux-config-scripts/master/debian-post-install/vim.sh | bash
```

You should also be able to call them from `chef`, if you are planning to run scripts on multiple servers.

Many scripts include tweakable variables, if you wish to modify them then
you should save script on disk before you execute it.

## Contents

 * [rhel-post-install](./rhel-post-install)
   * [nfs-server.sh](./rhel-post-install/nfs-server.sh)
   * [selinux-off.sh](./rhel-post-install/selinux-off.sh)
   * [rsyslog-server.sh](./rhel-post-install/rsyslog-server.sh)
   * [vim.sh](./rhel-post-install/vim.sh)
   * [samba-server-public.sh](./rhel-post-install/samba-server-public.sh)
 * [debian-post-install](./debian-post-install)
   * [disable-history.sh](./debian-post-install/disable-history.sh)
   * [mariadb.sh](./debian-post-install/mariadb.sh)
   * [wet-server.sh](./debian-post-install/wet-server.sh)
   * [vim.sh](./debian-post-install/vim.sh)
   * [enable-colours.sh](./debian-post-install/enable-colours.sh)
   * [openvpn.sh](./debian-post-install/openvpn.sh)
   * [openvpn-smart.sh](./debian-post-install/openvpn-smart.sh)
 * [arch-post-install](./arch-post-install)
   * [vim.sh](./arch-post-install/vim.sh)
   * [mate-desktop.sh](./arch-post-install/mate-desktop.sh)
   * [hla.sh](./arch-post-install/hla.sh)
 * [fedora-post-install](./fedora-post-install)
     * [grub-efi.sh](./fedora-post-install/grub-efi.sh)
     * [nouveau-off.sh](./fedora-post-install/nouveau-off.sh)
     * [old-kernels.sh](./fedora-post-install/old-kernels.sh)
     * [selinux-off.sh](./fedora-post-install/selinux-off.sh)
     * [nfs-server.sh](./fedora-post-install/nfs-server.sh)
     * [teamspeak3-client.sh](./fedora-post-install/teamspeak3-client.sh)
     * [samba-server-public.sh](./fedora-post-install/samba-server-public.sh)
     * [vim.sh](./fedora-post-install/vim.sh)
     * [mariadb.sh](./fedora-post-install/mariadb.sh)
     * [minetest-server.sh](./fedora-post-install/minetest-server.sh)
     * [openvpn.sh](./fedora-post-install/openvpn.sh)
     * [fasm.sh](./fedora-post-install/fasm.sh)
     * [onionshare.sh](./fedora-post-install/onionshare.sh)
