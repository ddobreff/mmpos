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

### Qubicmine.Pro client configuration:  

[Guide moved here](/QUBICMINE_PRO.MD)    

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
CLI command: `curl -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/${FID}/miner_profiles?limit=100 |jq -r .`

```
rm -f /tmp/idle_status.txt
cat <<- EOF > /tmp/config.txt 
API_TOKEN="YOUR-API-TOKEN"  # You can get this if you're at least supporter tier from profile.
FID="YOUR-FARM-ID" # Go to farms on dashboard and copy uuid link of your farm.
RID="%rig_uuid%" # This is global placeholder!
PRIMARY_PROFILE="YOUR-PRIMARY-APOOLMINER-PROFILE" # UUID of primary qubic miner.
SECONDARY_PROFILE="YOUR-IDLE-PROFILE" # UUID of secondary miner.
EOF
```
