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

echo "Listing 100 largest packages"
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -n 100
echo "=== docker system df"
docker system df
df -h
echo "Pruning docker storage"
docker system prune -af
echo "Removing large packages"
sudo apt-get purge -y azure-cli google-cloud-sdk hhvm google-chrome-stable \
    firefox powershell mono-devel mono-llvm-tools monodoc-manual mono-utils \
    msbuild microsoft-edge-stable '^ghc-8.*' '^dotnet-.*' '^llvm-.*' 'php.*' \
    '^aspnetcore-runtime-.*' '^temurin-.*' '^r-base-.*' \
    {cpp,g{cc,++},gfortran}-{9,10,11} libstdc++-{9,10,11}-dev
sudo apt-get autoremove --purge -y
sudo apt-get clean
echo "Removing large directories"
rm -rf /usr/share/dotnet/ /opt/hostedtoolcache/{CodeQL,go}/ /opt/microsoft/
df -h
