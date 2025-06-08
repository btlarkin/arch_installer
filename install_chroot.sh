#!/bin/bash

# Block device and boot mode
uefi=$(cat /var_uefi); hd=$(cat /var_hd);

# Naming the system
cat /comp > /etc/hostname && rm /comp


