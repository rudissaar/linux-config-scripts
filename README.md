# Linux Config Scripts

The main purpose of this repository is to contain Linux shell scripts
that can be triggered on system without needing to have a bunch of dependencies.
Only requirements that you should have is `bash` and `wget` command
and in most cases internet connection.

### Examples:
You can use the following syntax to execute scripts:
```
bash <(wget -O - https://.../linux-config-scripts/master/debian-post-install/openvpn.sh)
```

You can also use this syntax to execute a script that doesn't require any interaction:
```
wget -O - https://.../linux-config-scripts/master/debian-post-install/vim.sh | bash
```

You should also be able to call them from `chef`, if you are planning to run scripts on multiple servers.

Many scripts include tweakable variables, if you wish to modify them then you should save script on disk before you execute it.
