#!/bin/sh
# see https://github.com/jart/cosmopolitan/blob/5907304049f37c9ed77593974d13202829443bea/README.md#linux

if [ "$(uname -s)" = "Linux" ]; then
    sudo wget -O /usr/bin/ape https://cosmo.zip/pub/cosmos/bin/ape-$(uname -m).elf
    sudo chmod +x /usr/bin/ape
    sudo sh -c "echo ':APE:M::MZqFpD::/usr/bin/ape:' >/proc/sys/fs/binfmt_misc/register"
    sudo sh -c "echo ':APE-jart:M::jartsr::/usr/bin/ape:' >/proc/sys/fs/binfmt_misc/register"
    echo "APE loader installed successfully on Linux system"
else
    echo "This script is only for Linux systems"
    exit 1
fi