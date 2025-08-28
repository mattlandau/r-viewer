# Welcome to R-Viewer

This project provides a way to view footage from Rhombus Systems cameras on a Roku device. It also provides static snapshots from cameras in a video wall. 

Currently, it is alpha/beta stage. This repository intends to include at least a minimally viable product.

## Prerequisites

 1. You will need a Rhombus API key that includes a role that includes at least View & Manage device access for the locations in your organization. You can follow these instructions for gaining an API key: https://docs.rhombus.com/
    
 2. You will need a Roku device that has developer mode enabled: https://developer.roku.com/docs/developer-program/getting-started/developer-setup.md
 
 3. For running the app, you will need the VS Code Brightscript Language plug in (https://marketplace.visualstudio.com/items?itemName=RokuCommunity.brightscript) **OR** comfortability side-loading apps onto your Roku

### For VS Code Support

> This project was created using [`npx create-roku-app`](https://github.com/haystacknews/create-roku-app)

1. Install the project dependencies if you haven't done that yet.

2. Open the `bsconfig.json` file and enter the password for your Roku device.

3. Optionally you can hardcode your Roku device's IP in the `host` field. If you do so make sure to remove the `host` entry from the `.vscode/launch.json` settings.

4. Go to the `Run and Debug` panel.

5. Select the option `Launch Rhombus Viewer (dev)`
