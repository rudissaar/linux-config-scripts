# linux-config-scripts

The main purpose of this repository is to contain Linux shell scripts
that can be triggered on system without needing to have bunch of dependencies,
only requirements that you should have is `bash` and `wget` command
and in most cases internet connection.

Example:
```
wget -O - https://raw.githubusercontent.com/rudissaar/linux-config-scripts/master/debian-post-install/vim.sh | bash
```

Many scripts include tweakable variables, if you with to modify them then you should save script on disk before you execute it.
