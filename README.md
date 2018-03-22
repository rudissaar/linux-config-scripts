# linux-config-scripts

The main purpose of this repository is to contain Linux shell scripts
that can be triggered on system without needing to have bunch of dependencie.
Only requirements that you should have is `bash` and `wget` command
and in most cases internet connection.

### Examples:
To execute script that doesn't require any interaction.
```
wget -O - https://raw.../linux-config-scripts/master/debian-post-install/vim.sh | bash
```

If script does require interaction, you should this syntax, it's recommend syntax to use for both of them:
```
bash <(wget -O - https://raw.githubusercontent.com/rudissaar/linux-config-scripts/master/debian-post-install/openvpn.sh
```

You should also be able to call them from `chef`, if you are planning to run scripts on multiple servers.

Many scripts include tweakable variables, if you wish to modify them then you should save script on disk before you execute it.
