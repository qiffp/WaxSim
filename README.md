# WaxSim

A wrapper around DVTiPhoneSimulatorRemoteClient, to install and run apps in the iOS simulator.

## Installation

Compiling and installing uses the `xcodebuild` command. By default it installs the app in `/usr/local/bin`.

`xcodebuild install`

To customize the installation location use the `DSTROOT` and `INSTALL_PATH` build variables. For example, to compile into a local `bin` directory:

`xcodebuild install DSTROOT=. INSTALL_PATH=/bin`

## Use

Most basic use:

`waxsim /path/to/MyApp.app`

To see all usage options, type `waxsim` with no arguments:

```
usage: waxsim [options] app-path
example: waxsim -s 2.2 /path/to/app.app
Available options are:
  -s sdk  SDK version to use (-s 6.1). Defaults to the latest SDK available.
  -d device Device to use (-d iPad). Options are 'iPad' and 'iPhone'. Defaults to iPhone.
  -e VAR=value  Environment variable to set (-e CFFIXED_HOME=/tmp/iphonehome)
  -a Lists the available SDKs.
  -h Prints out this wonderful documentation!
```
