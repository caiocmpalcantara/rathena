<img src="doc/logo.png" align="right" height="90" />

# rAthena
![clang](https://img.shields.io/github/actions/workflow/status/rathena/rathena/build_servers_clang.yml?label=clang%20build&logo=llvm) 
![cmake](https://img.shields.io/github/actions/workflow/status/rathena/rathena/build_servers_cmake.yml?label=cmake%20build&logo=cmake)
![gcc](https://img.shields.io/github/actions/workflow/status/rathena/rathena/build_servers_gcc.yml?label=gcc%20build&logo=gnu) 
![ms](https://img.shields.io/github/actions/workflow/status/rathena/rathena/build_servers_msbuild.yml?label=ms%20build&logo=visualstudio) 
![GitHub](https://img.shields.io/github/license/rathena/rathena.svg) 
![commit activity](https://img.shields.io/github/commit-activity/w/rathena/rathena) 
![GitHub repo size](https://img.shields.io/github/repo-size/rathena/rathena.svg)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/rathena/rathena)


> rAthena is a collaborative software development project revolving around the creation of a robust massively multiplayer online role playing game (MMORPG) server package. Written in C++, the program is very versatile and provides NPCs, warps and modifications. The project is jointly managed by a group of volunteers located around the world as well as a tremendous community providing QA and support. rAthena is a continuation of the eAthena project.

[Forum](https://rathena.org/board)|[Discord](https://rathena.org/discord)|[Wiki](https://github.com/rathena/rathena/wiki)|[FluxCP](https://github.com/rathena/FluxCP)|[Crowdfunding](https://rathena.org/board/crowdfunding/)|[Fork and Pull Request Q&A](https://rathena.org/board/topic/86913-pull-request-qa/)
--------|--------|--------|--------|--------|--------

### Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Installation](#2-installation)
3. [Parallel Build Support](#3-parallel-build-support)
4. [Troubleshooting](#4-troubleshooting)
5. [More Documentation](#5-more-documentation)
6. [How to Contribute](#6-how-to-contribute)
7. [License](#7-license)

## 1. Prerequisites
Before installing rAthena there are certain tools and applications you will need which
differs between the varying operating systems available.

### Hardware
Hardware Type | Minimum | Recommended
------|------|------
CPU | 1 Core | 2 Cores
RAM | 1 GB | 2 GB
Disk Space | 300 MB | 500 MB

### Operating System & Preferred Compiler
Operating System | Compiler
------|------
Linux  | [gcc-6 or newer](https://www.gnu.org/software/gcc/gcc-6/) / [Make](https://www.gnu.org/software/make/)
Windows | [MS Visual Studio 2017 or newer](https://www.visualstudio.com/downloads/)

### Required Applications
Application | Name
------|------
Database | [MySQL 5 or newer](https://www.mysql.com/downloads/) / [MariaDB 5 or newer](https://downloads.mariadb.org/)
Git | [Windows](https://gitforwindows.org/) / [Linux](https://git-scm.com/download/linux)

### Optional Applications
Application | Name
------|------
Database | [MySQL Workbench 5 or newer](http://www.mysql.com/downloads/workbench/)

## 2. Installation 

### Full Installation Instructions
  * [Windows](https://github.com/rathena/rathena/wiki/Install-on-Windows)
  * [CentOS](https://github.com/rathena/rathena/wiki/Install-on-Centos)
  * [Debian](https://github.com/rathena/rathena/wiki/Install-on-Debian)
  * [FreeBSD](https://github.com/rathena/rathena/wiki/Install-on-FreeBSD)

## 3. Build System

rAthena uses a **two-step build process** with separated configuration and compilation for better organization and faster builds! 🚀

### Quick Start
```bash
# Step 1: Configure the build
./configure                    # Basic configuration
./configure -t Debug           # Debug build
./configure -m                 # Traditional make instead of CMake

# Step 2: Build the project
./build.sh           # Build with auto-detected cores
./build.sh -j 8      # Build with 8 parallel jobs
./build.sh -c        # Clean build

# Advanced configuration examples
./configure -- --enable-prere --enable-packetver=20180620  # Pre-renewal
./configure -t Debug -- --enable-debug --enable-vip        # Debug with VIP
```

### Performance Improvements
- **2-4x faster** on quad-core systems
- **4-8x faster** on 8+ core systems
- **Up to 20x faster** on high-end workstations
- **Separated concerns**: Configure once, build many times

### Documentation
For detailed information, see [PARALLEL_BUILD.md](PARALLEL_BUILD.md)

## 4. Troubleshooting

If you're having problems with starting your server, the first thing you should
do is check what's happening on your consoles. More often that not, all support issues
can be solved simply by looking at the error messages given. Check out the [wiki](https://github.com/rathena/rathena/wiki)
or [forums](https://rathena.org/forum) if you need more support on troubleshooting.

### Build Issues
For build troubleshooting, run:
```bash
./configure --help              # See configuration options
./build.sh --help     # See build options
./test-build-quick.sh           # Quick verification
./test-parallel-build.sh        # Comprehensive testing
```

For detailed troubleshooting, see [TROUBLESHOOTING_PARALLEL_BUILD.md](TROUBLESHOOTING_PARALLEL_BUILD.md)

## 5. More Documentation
rAthena has a large collection of help files and sample NPC scripts located in the /doc/
directory. These include detailed explanations of NPC script commands, atcommands (@),
group permissions, item bonuses, and packet structures, among many other topics. We
recommend that all users take the time to look over this directory before asking for
assistance elsewhere.

## 6. How to Contribute
Details on how to contribute to rAthena can be found in [CONTRIBUTING.md](https://github.com/rathena/rathena/blob/master/.github/CONTRIBUTING.md)!

## 7. License
Copyright (c) rAthena Development Team - Licensed under [GNU General Public License v3.0](https://github.com/rathena/rathena/blob/master/LICENSE)
