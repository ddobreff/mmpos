# MMP Plugins Documentation

## Table of Contents
- [Overview](#overview)
- [Plugin Directory Structure](#plugin-directory-structure)
  - [Archive Structure (Before Unarchiving)](#archive-structure-before-unarchiving)
  - [After Unarchive Structure](#after-unarchive-structure)
- [Plugin Workflow](#plugin-workflow)
- [Example `launch.sh`](#example-launchsh)
- [Key Updates](#key-updates)
- [Warning](#warning)

## Overview
The `mmp-plugins` system allows for managing plugins within the `/mmp-misc/plugins/` directory. Plugins are stored as archives in the `/mmp-misc/plugins/archive` directory and are dynamically extracted to a separate directory within `/mmp-misc/plugins/` when needed. Each plugin is started via its `launch.sh` script.

## Plugin Directory Structure

### Archive Structure (Before Unarchiving)
Initially, plugins are packaged as archives and stored in the `/mmp-misc/plugins/archive/` directory. The typical structure looks like this:

/mmp-misc └── plugins └── archive └── yourplugin.tar.gz

### After Unarchive Structure
When a plugin is unarchived, it is extracted into the `/mmp-misc/plugins/` directory, and the extracted content is placed into a folder named after the plugin. Inside this folder, the plugin's logic resides in the `launch.sh` script, which is executed to control(optional) and monitor(optional) the plugin. The structure after unarchiving is:

/mmp-misc └── plugins └── yourplugin └── launch.sh

## Plugin Workflow

1. **Archiving**: Plugins are initially stored as compressed files (`.tar.gz`) within the `/mmp-misc/plugins/archive` directory.
   
2. **Unarchiving**: The plugin system unarchives the plugin into the `/mmp-misc/plugins/yourplugin` directory.

3. **Execution**: Inside the unarchived plugin folder, the main script that controls the plugin is `launch.sh`. This script is responsible for:
   - Monitoring and managing the plugin.
   - Starting and stopping the plugin process.
   - Logging outputs for troubleshooting and monitoring.
   - In fact it can do anything you make it do. Its entirely up to you to add its content.

4. **Monitoring**: The `launch.sh` script should handle the monitoring of the plugin, ensuring that the plugin operates correctly and can be restarted if necessary(optional).

## Example `launch.sh`

Here's a basic example of what a `launch.sh` script could look like inside a plugin folder:

```bash
#!/bin/bash

# Example of plugin monitoring and control logic
echo "Starting your plugin..."

# Start the plugin (replace this with your actual plugin start command)
./yourplugin-executable &

# Capture the PID of the plugin process
PLUGIN_PID=$!

# Log the PID for monitoring
echo "Plugin started with PID: $PLUGIN_PID"

# Monitor the plugin's process
while true; do
    if ! kill -0 $PLUGIN_PID 2>/dev/null; then
        echo "Plugin process has stopped. Restarting..."
        ./yourplugin-executable &
        PLUGIN_PID=$!
        echo "New plugin process started with PID: $PLUGIN_PID"
    fi
    sleep 5  # Check every 5 seconds
done
```
### Key Updates:
- **`plugins.json`**: Explained that it is meant to enable or disable plugins in the future, and it is not yet activated for manual configuration. Once functional, it will provide an easy way to manage plugins via dashboard.
### Warning:
:warning: Be warned that when you reset configurations with using `mmp reset` ether `--soft` or `--hard`, all plugins are delete except the built-in ones.
