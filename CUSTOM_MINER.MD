# Custom miner setup for mmpOS

You can make any executable as custom miner in mmpOS.  
All miners are unarchived in directory `/opt/mmp/miners/custom-$(echo -n "your-download-url/miner.tar.gz" | sha256sum | cut -c1-5)`

## Table of Contents
1. [mmp-external.conf](#mmp-externalconf)
2. [mmp-stats.sh](#mmp-statssh)
    - [How to get PCI Bus id in mmpOS?](#how-to-get-pci-bus-id-in-mmpos)
    - [Example GPU json output](#example-gpu-json-output)
    - [Example CPU json output](#example-cpu-json-output)
    - [Example FPGA json output](#example-fpga-json-output)
    - [Per device share monitoring](#per-device-share-monitoring)
    - [Example mmp-stats.sh files](#example-mmp-statssh-files)
3. [How to pack your custom miner](#how-to-pack-your-custom-miner)
4. [How to use your custom miner](#how-to-use-your-custom-miner)
5. [Final step after successful setup of your custom miner](#final-step-after-successful-setup-of-your-custom-miner)

---

##### mmp-external.conf
This file is considered generic for storing miner name and version.  
It is used entirely for your information purpose, we do not display anything it contains.  
General content:  
```bash
# The name of the miner ex. myfirstminer  
EXTERNAL_NAME=myfirstminer
# Miner version  
EXTERNAL_VERSION=1.0
```  
##### mmp-stats.sh
Stats collector file used by `mmp agent`.

This script is used by `mmp agent` to push stats to `mmp dashboard`.  
**A few rules to follow:**  
-    PCI Bus or Index count must always match Hashrate count as `busid`.
-    Index can be removed when you provide PCI Bus Ids as `index`.
-    PCI Bus must be argjson and should either be decimal or hex as `busid`.
-    For FPGA monitoring you either provide USB Bus id or Serial as `uid`.
-    For CPU monitoring you mark busid as arg and name it `cpu`. - see CPU example:
-    Hashrate format is either float or integer in argjson as `hash`.
-    Units can be `hs, khs, mhs, ghs, ths` as `units`
-    `air` means Accepted, Invalid, Rejected and its in arg format. 
>
#### How to get PCI Bus id in mmpOS?  
Call the function below with `get_bus_ids 10de` for NVIDIA or 1002 for AMD, or none for Intel.
>
```
get_bus_ids() {
    local vendor_id="$1"
    local gpu_info_json="/run/gpu-info.json"
    local busids=()

    local vendor
    vendor_id=$(echo "$vendor_id" | tr -d '[:space:]')
    case "$vendor_id" in
        10de) vendor="nvidia" ;;
        1002) vendor="amd_sysfs" ;;
        *)    vendor="intel_sysfs" ;;
    esac

    local bus_ids
    bus_ids=$(jq -r ".device.GPU.${vendor}_details.busid[]" "$gpu_info_json" 2>/dev/null)

    if [[ -z "$bus_ids" ]]; then
        exit 1
    fi

    while read -r bus_id; do
        local hex=${bus_id:5:2}
        busids+=($((16#$hex)))
    done <<< "$bus_ids"
    echo "${busids[*]}"
}
```
#### Example GPU json output:  
```javascript
{
  "busid": [
    1,
    2,
    3,
    4,
    5,
    6
  ],
  "hash": [
    111.0,
    112.0,
    113.0,
    114.0,
    115.0,
    116.0
  ],
  "units": "hs",
  "air": [
    "5",
    "1",
    "2"
  ],
  "miner_name": "myfirstminer",
  "miner_version": "1.0"
}
```

#### Example CPU json output:  
```javascript
{
  "busid": [
    "cpu"
  ],
  "hash": [
    111.0,
  ],
  "units": "hs",
  "air": [
    "5",
    "1",
    "2"
  ],
  "miner_name": "myfirstminer",
  "miner_version": "1.0"
}
```
> You can mix cpu and gpu hashrate but first you should provide `cpu` as busid followed by GPU busids.  

#### Example FPGA json output:  
```javascript
{
  "uid": [
  "50241A29CNC9",
  "50241A29CR9T",
  "153300000944",
  "153300000791",
  "XFL1WCO4STQT",
  "TH53M0809009"
  ],
  "hash": [
    111.0,
    112.0,
    113.0,
    114.0,
    115.0,
    116.0,
  ],
  "units": "hs",
  "air": [
    "5",
    "1",
    "2"
  ],
  "miner_name": "myfirstminer",
  "miner_version": "1.0"
}
```
#### Per device share monitoring:  
Since 10th of October we now support per device share monitoring. Here's additional json data that can be added to current json format:  
```javascript
  "shares": {
    "accepted": [ // Accepted shares per device(current example is for 6 devices)
      1, // Matches index/bus of first device
      0,
      0,
      0,
      0,
      1 // Matches index/bus of last device
    ],
    "rejected": [ // This will be shown as rejected %
      0,
      0,
      0,
      0,
      0,
      0
    ],
    "invalid": [ // This will display error rate per device on dashboard.
      0,
      0,
      0,
      0,
      0,
      0
    ]
  }
```
*NOTE!*  Currentlu `ar`/`air` is required also to show total shares per hour. So don't forget to include it too.   
#### Example mmp-stats.sh files:   
-	Using logfile parser [mmp-stats.sh](/custom_miner/mmp-stats-logfile.txt)
-	Using miner api parser [mmp-stats.sh](/custom_miner/mmp-stats-api.txt)
-	Using new format LOG file parser for [Rushminer](https://github.com/quayd/RushMiner): [mmp-stats.sh](/custom_miner/mmp-stats-ext2.txt)
> Make sure mmp-stats.sh is executable and it contains:  
```bash
#!/usr/bin/env bash
or
#!/bin/bash
DEVICE_NUM=$1 # -- This indicates the number of devices agent seeks stats for.
LOG_FILE=$2 # -- This gives the log file provided by agent on call.
```
> header

## How to pack your custom miner: 
Must be packed in `tar.gzip` format or meaning `.tar.gz` or `.tgz` inside directory.  
Name of the directory is not relevant because our agent already renames it to `custom-$(echo -n "your-download-url/miner.tar.gz" | sha256sum | cut -c1-5)`  

Sample command to create miner archive
```bash
tar -czf myfirstminer-1.0.tgz myfirstminer
```


## How to use your custom miner: 
After you've packed and uploaded your miner somewhere, you are ready to take the next step - using it!  

**Create miner profile and select custom miner, place your url as listed below:**  
![Custom](/imgs/custom_miner1.png)
> Make sure to select proper pool too.

**Move to advanced settings:**  
![Custom](/imgs/custom_miner2.png)
> In arguments field you provide proper arguments supported by your custom miner, you can point directly to miner binary or create abstract
> executable like `miner.sh`

Sample `miner.sh` executable script.
```bash
#!/usr/bin/env bash
trap 'while killall myminerbinary > /dev/null 2>&1;do sleep 1;done;exit 0' SIGTERM
    ./myminerbinary --api-port 5001
```

## Final step after successful setup of your custom miner:
Now its time to share it with other mmpOS users :)  
Click on your newly created miner profile and click on export button - see example below.  
![Custom](/imgs/export_miner.png)

Et Voila!  

