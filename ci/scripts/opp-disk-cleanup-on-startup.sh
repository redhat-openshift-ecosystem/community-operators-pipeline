#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#
# The Azure provided machines typically have the following disk allocation:
# Total space: 85GB
# Allocated: 67 GB
# Free: 17 GB
# This script frees up 28 GB of disk space by deleting unneeded packages and
# large directories.
# The Flink end to end tests download and generate more than 17 GB of files,
# causing unpredictable behavior and build failures.
#
echo "=============================================================================="
echo "Freeing up disk space on CI system"
echo "=============================================================================="

echo "Pruning docker storage"
docker system prune -af
echo "Removing large packages"
sudo apt-get purge -y azure-cli google-cloud-cli hhvm google-chrome-stable \
    firefox powershell mono-devel mono-llvm-tools monodoc-manual mono-utils \
    msbuild microsoft-edge-stable '^dotnet-.*' '^llvm-.*' 'php.*' \
    '^aspnetcore-runtime-.*' '^temurin-.*' '^r-base-.*' \
    {cpp,g{cc,++},gfortran}-{9,10,11,12} libstdc++-{9,10,11,12}-dev
sudo apt-get autoremove --purge -y
sudo apt-get clean
echo "Removing large directories"
sudo rm -rf /usr/share/dotnet/ /opt/hostedtoolcache/{CodeQL,go}/ /opt/microsoft/ \
    /usr/local/.ghcup /usr/local/julia1.*
df -h
FREE_GBS="$(df -PBG / | awk '$NF=="/"{print $4}' | tr -dc 0-9)"
if [ "$FREE_GBS" -lt "36" ] ; then
    echo "WARNING: RUNNING LOW ON DISK SPACE"
    echo "====== disk space report"
    echo "=== packages"
    dpkg-query -Wf '${db:Status-Status} ${Installed-Size}\t${Package}\n' | sed -ne 's/^installed //p' | sort -n | tail -n 100
    echo "=== directories"
    sudo find / -mindepth 2 -maxdepth 2 -xdev -type d | xargs sudo du -ks | sort -n | tail -n 25
    echo "=== directories in /usr/local"
    sudo find /usr/local -mindepth 1 -maxdepth 1 -xdev -type d | xargs sudo du -ks | sort -n | tail -n 25
    echo "=== docker images"
    docker system df
    echo "====== end disk space report"
fi

sudo mkdir -p /mnt/storage
sudo chown "$(id -u):$(id -g)" /mnt/storage
sudo mkdir -p ~/.config/containers
printf '[storage]\ngraphroot = "/mnt/storage"\n' > ~/.config/containers/storage.conf
podman system reset
