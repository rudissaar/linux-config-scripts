#!/usr/bin/env bash

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Upgrade packages.
dnf update -y

# Install yum-utils to clean up kernels later.
dnf install -y yum-utils

# Remove old kernels.
package-cleanup -y --oldkernels --count=1

# Remove everything that is not used by any package.
dnf autoremove -y

# Remove repository's cache.
dnf clean all

