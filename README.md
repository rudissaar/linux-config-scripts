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

 * [arch-post-install](./arch-post-install)
   * [hla.sh](./arch-post-install/hla.sh)
   * [mate-desktop.sh](./arch-post-install/mate-desktop.sh)
   * [vim.sh](./arch-post-install/vim.sh)
 * [debian-post-install](./debian-post-install)
   * [disable-history.sh](./debian-post-install/disable-history.sh)
   * [enable-colours.sh](./debian-post-install/enable-colours.sh)
   * [mariadb.sh](./debian-post-install/mariadb.sh)
   * [openvpn-smart.sh](./debian-post-install/openvpn-smart.sh)
   * [openvpn.sh](./debian-post-install/openvpn.sh)
   * [vim.sh](./debian-post-install/vim.sh)
   * [wet-server.sh](./debian-post-install/wet-server.sh)
 * [fedora-post-install](./fedora-post-install)
   * [adobe-flash.sh](./fedora-post-install/adobe-flash.sh)
   * [apache-netbeans.sh](./fedora-post-install/apache-netbeans.sh)
   * [fasm.sh](./fedora-post-install/fasm.sh)
   * [grub-efi.sh](./fedora-post-install/grub-efi.sh)
   * [hla.sh](./fedora-post-install/hla.sh)
   * [libvirt-qemu-kvm.sh](./fedora-post-install/libvirt-qemu-kvm.sh)
   * [mariadb.sh](./fedora-post-install/mariadb.sh)
   * [minetest-server.sh](./fedora-post-install/minetest-server.sh)
   * [nfs-server.sh](./fedora-post-install/nfs-server.sh)
   * [nginx-php-stack.sh](./fedora-post-install/nginx-php-stack.sh)
   * [nouveau-off.sh](./fedora-post-install/nouveau-off.sh)
   * [old-kernels.sh](./fedora-post-install/old-kernels.sh)
   * [onionshare.sh](./fedora-post-install/onionshare.sh)
   * [openvpn.sh](./fedora-post-install/openvpn.sh)
   * [pam-su-no-password.sh](./fedora-post-install/pam-su-no-password.sh)
   * [replace-lightdm-with-gdm.sh](./fedora-post-install/replace-lightdm-with-gdm.sh)
   * [samba-server-public.sh](./fedora-post-install/samba-server-public.sh)
   * [selinux-off.sh](./fedora-post-install/selinux-off.sh)
   * [teamspeak3-client.sh](./fedora-post-install/teamspeak3-client.sh)
   * [vim.sh](./fedora-post-install/vim.sh)
 * [rhel-post-install](./rhel-post-install)
   * [nfs-server.sh](./rhel-post-install/nfs-server.sh)
   * [rsyslog-server.sh](./rhel-post-install/rsyslog-server.sh)
   * [samba-server-public.sh](./rhel-post-install/samba-server-public.sh)
   * [selinux-off.sh](./rhel-post-install/selinux-off.sh)
   * [vim.sh](./rhel-post-install/vim.sh)

