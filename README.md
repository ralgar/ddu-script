# Update Nvidia Display Driver on Windows

## Overview

A Windows PowerShell script to cleanly update your Nvidia display driver,
 using Display Driver Uninstaller and Chocolatey.

## Getting Started

### Prerequisites

The only prerequisite is that you have [Chocolatey](https://chocolatey.org/install)
 installed.

### Usage

1. Download the script to your computer.

1. Right click on the script and choose *Run with Powershell*.

1. Follow the prompts, and be sure to answer **Yes** to all questions.

### Additional Info

Your device will reboot into Safe Mode, purge the old driver, and then reboot
 again before installing the latest driver. You will be prompted several times
 during this process, you should always answer **Yes**.

Do not interrupt the process before it is complete. The script will inform you
 when it has completed the driver installation/upgrade.
