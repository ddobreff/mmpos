# Qubic mining on mmpOS


Official qubic.li, rqiner and qubicmine.pro clients are included as native miners:
<br>

## :warning: For best experience, please use latest mmpOS image. Here are the basic requirements:

-   The CPU where you run the Client must support AVX2 or AVX512 CPU instructions
    `cat /proc/cpuinfo | grep avx2`(check if `avx2` is in the result)
-   RAM >= 16GB improves CPU it/s
-   Higher RAM frequencies improves CPU it/s
-   Do not overload your CPUs with threads, instead, aim to find the sweetpoint

<br>

## GPU driver requirements:
-	Default AMD OpenCL driver is required for mining which currently is 23.20.1 or latest ROCm[6.1.0].
-	CUDA 12 capable driver. We recommend going to latest or beta using `mmp nvidia-install latest` or `mmp nvidia-install beta` in CLI.

### Custom placeholder per rig configuration video guide:
-	[![Click to see video](/movs/8190556357408478139.gif)](/movs/8190556357408478139.mov)  


### Qubic.li original client configuration:
**Sample Configuration for CPUs**
![Profile](/imgs/qli-cpu.png)  
> If you don't add `--trainer` it will automatically choose best.
> Use option `--hugepages` as custom placeholder too to setup different hugepages per Rig.  

```
--trainer AVX512|AVX2|Generic --cpu-threads $(nproc)
```

**Sample Configuration for AMD GPUs**
![Profile](/imgs/qli-amd.png)  

```
--trainer AMD
```

**Sample Configuration for NVIDIA GPUs**
![Profile](/imgs/qli-nvidia.png)  

```
--trainer CUDA12
```
>[!IMPORTANT]  
> Make sure you use `--acccesstoken` for Qubic.li original client as argument and in wallet too.  
> Qubic.li usually uses accessToken which is generated on their pool setup - this is not Qubic ID!!!  

### Providers using official Qubic client.  
>Jetski-pool: Use `URL: wps.qubjetski.xyz` and add option `--provider jetski`.  
> NOTE: Jetski pool requires your wallet, so make sure you provide it with either options available(--payoutid or --account).  
>Minerlab.io: Use URL: `wps.minerlab.io` and add option `--provider minerlab`.  
>NOTE: Minerlab.io is account based, so make sure you provide `--account or --payoutid` option in your miner profile as account id and not wallet.  

### Qubicmine.pro.  
>[Guide moved here](/QUBICMINE_PRO.MD)  

### Qubic solutions client configuration:
**CPU configuration explanation** 
> By default our script determines the capabilities of your CPU and chooses the best version for it.
> Its all built in so you don't need to do anything except set your custom placeholder `%custom_cpu_threads%` as explained in video.
> If you wish to utilize all CPU threads available use `$(nproc)` as your CPU thread value.  

**NVIDIA GPUs**  
> By default command arguments should be sufficient to run normally.

**AMD GPUs**  
> [!IMPORTANT]  
> Qubic solutions do not support native AMD miner, but we can use ZLUDA in order to mine on AMD GPUs. Follow instructions below.  

## :wrench: Custom miner settings

-   **Download profile json from:** [Download JSON](https://github.com/ddobreff/mmpos/releases/download/v0.5.0/qubic-rqiner-zluda.json)
-   **Click on miner profiles->Import from JSON:** ![Profile](/imgs/import_profile.png)`.
-   **Add pool and select wallet and thats it!**
>[!IMPORTANT]  
> Qubic solutions use QUBIC ID which is 60 character long WALLET.  

### Apoolminer
## :wrench: Custom miner settings

-   **Download profile json from:** [Download JSON](https://github.com/ddobreff/mmpos/releases/download/v1.3.2/apoolminer-qubic.json)
-   **Click on miner profiles->Import from JSON:** ![Profile](/imgs/import_profile.png)`.
-   **Add pool and select wallet and thats it!**
>[!IMPORTANT]  
> a-pool.io uses their own account ids, please refer to their website for more info `https://www.apool.io/`.  

### Usually used NVIDIA overclocks:
**Moderate**  
2000 series `Locked core clock: 1385, Smart memory tune: compute-heavy/med, Core offset: 200`  
3000 series `Locked core clock: 1500, Smart memory tune: compute-heavy/med, Core offset: 250`  
4000 series `Locked core clock: 2400, Smart memory tune: compute-heavy/med, Core offset: 250`  
**Heavy**  
2000 series `Locked core clock: 1500, Smart memory tune: compute-heavy/def, Core offset: 150`  
3000 series `Locked core clock: 1600, Smart memory tune: compute-heavy/def, Core offset: 200`  
4000 series `Locked core clock: 2900, Smart memory tune: compute-heavy/def, Core offset: 200`  

### Usually used AMD overclocks:

**Moderate**  
RDNA series: `Absolute core clock: 1266, Smart memory tune: compute-heavy/def, Voltage: 750-800`  
RDNA2 series: `Absolute core clock: 1400, Smart memory tune: compute-heavy/def, Voltage: 625-675`  
RDNA3 series: `Absolute core clock: 2200, Smart memory tune: compute-heavy/def, Voltage offset: -250`  
**Heavy**  
RDNA series: `Absolute core clock: 1400, Smart memory tune: compute-heavy/def, Voltage: 800-850`  
RDNA2 series: `Absolute core clock: 1600, Smart memory tune: compute-heavy/def, Voltage: 700-750`  
RDNA3 series: `Absolute core clock: 2600, Smart memory tune: compute-heavy/dev, Voltage offset: -300`  

## Due to QUBIC moving for scheduled mining scheme we've implemented a trigger to switch miner profiles on idle. 

### :wrench: `Initiate command prior to miner launch` concept: 

Fetch all profiles(limit 100) and post them via `Initiate command prior to miner launch`.  
Make sure to export API_TOKEN, and FID(farm id).  
CLI command:  
```
export API_TOKEN=Your-API-Token-from-profiles
Use this to fetch Farm IDs: `curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/farms |jq -r '.[]|{name: .name, id'}`"  
Or if you haven't renamed your farm use this:  
FID=$(curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/farms | jq -r '.[] | select(.name == "Default" and .own_access_role == "ROLE_FARM_OWNER") | .id')  
Then use this to fetch miner profiles limited to 100:  
curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/${FID}/miner_profiles?limit=100 |jq -r .  
```
You can also fetch profiles by coin(QUBIC example, but it can be any supported coin):  
```
curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/${FID}/miner_profiles?limit=100 |jq -r '.[] | select(.coin == "QUBIC") | {name: .name, id'}
```
And in `Initiate command prior to miner launch` add this:  
```
SW_CNF_FILE="/tmp/config.txt"
rm -f /tmp/idle_state.txt
cat <<- EOF > $SW_CNF_FILE 
API_TOKEN="YOUR-API-TOKEN"  # You can get this if you're at least supporter tier from profile.
FID="YOUR-FARM-ID" # Go to farms on dashboard and copy uuid link of your farm.
RID="%rig_uuid%" # This is global placeholder!
PRIMARY_PROFILE="YOUR-PRIMARY-QUBIC-PROFILE" # UUID of primary qubic miner.
SECONDARY_PROFILE="YOUR-IDLE-PROFILE" # UUID of secondary miner.
EOF
```
> SW_CNF_FILE for qubic client and qubicmine.pro is /tmp/config.txt, for apoolminer is /tmp/apool_config.txt  

### :wrench: Using direct API concept: 

We've added [qubic-switch.sh](/scripts/qubic-switch.sh) script that monitors Qubic SEED and if its idle period it switches to your secondary profile.  
Also we've added ability to add `+cpu` to your rig names in case you use your CPU to mine other coin or again QUBIC but with CPU.  
Content is almost the same as with previous method, but we've removed rig UUID from config and added qubic accesstoken for qubic API connection.   
>config.txt content:
>
```
API_TOKEN="YOUR-API-TOKEN"  # You can get this if you're at least supporter tier from profile.
FID="YOUR-FARM-ID" # Go to farms on dashboard and copy uuid link of your farm.
PRIMARY_PROFILE="YOUR-PRIMARY-QUBIC-PROFILE" # UUID of primary qubic miner.
SECONDARY_PROFILE="YOUR-IDLE-PROFILE" # UUID of secondary miner.
CPU_PROFILE="YOUR-CPU-PROFILE" # Add it in case you use cpu profile
QUBIC_ACCESSTOKEN="Your qubic.li accesstoken" # This is not your QUBIC WALLET!!!
```
> rigs.txt content:
>
```
rig1
rig2+cpu
rig3
rig4
```
These are your rig's names. In this particular example rig2 mines with CPU.  
Finally add the script to your crontab(use `sudo crontab -e`):
```
 * * * * * /home/miner/qubic-switch.sh >/dev/null 2>&1
```
>
Of course you can modify the script to switch only CPU profiles.  
Feel free to publish changes.   

