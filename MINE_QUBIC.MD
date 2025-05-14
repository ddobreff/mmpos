# Qubic mining on mmpOS


Official qubic.li and qubicmine.pro clients are included as native miners:
<br>

## :warning: For best experience, please use latest mmpOS image. Here are the basic requirements:

-   The CPU where you run the Client must support AVX2 or AVX512 CPU instructions
    `cat /proc/cpuinfo | grep avx2`(check if `avx2` is in the result)
-   RAM >= 16GB improves CPU it/s
-   Higher RAM frequencies improves CPU it/s
-   Do not overload your CPUs with threads, instead, aim to find the sweetpoint

<br>

## GPU driver requirements:
-	Default AMD OpenCL driver is required for mining which currently is 23.20.1 or latest ROCm[6.2.2].
-	CUDA 12 capable driver. We recommend going to latest or beta using `mmp nvidia-install latest` or `mmp nvidia-install beta` in CLI.

### Custom placeholder per rig configuration video guide:
-	[![Click to see video](/movs/8190556357408478139.gif)](/movs/8190556357408478139.mov)  


### Qubic.li original client configuration:
**Sample Configuration for CPUs**
![Profile](/imgs/qli-cpu.png)  
> If you don't add `--trainer` (*NOTE: in v3.0 option has been renamed to `--cputrainer` or `--gputrainer`*) it will automatically choose best.
> Use option `--hugepages` as custom placeholder too to setup different hugepages per Rig.  

```
--trainer|--cputrainer AVX512|AVX2|Generic --cpu-threads $(nproc)
```

**Sample Configuration for NVIDIA GPUs**
![Profile](/imgs/qli-nvidia.png)  

```
--trainer|--gputrainer CUDA
```
>[!IMPORTANT]  
> Make sure you use `--acccesstoken` for Qubic.li original client as argument and in wallet too.  
> Qubic.li usually uses accessToken which is generated on their pool setup - this is not Qubic ID!!!  

### Providers using official Qubic client.  
>Jetski-pool: Use `URL: wps.qubjetski.xyz` and add option `--provider jetski`.  
> NOTE: Jetski pool requires your wallet, so make sure you provide it with either options available(--payoutid or --account).  
>Minerlab.io: Use URL: `wps.minerlab.io` and add option `--provider minerlab`.  
>NOTE: Minerlab.io is account based, so make sure you provide `--account or --payoutid` option in your miner profile as account id and not wallet.  


### Qubic solutions client configuration:
**CPU configuration explanation** 
> By default our script determines the capabilities of your CPU and chooses the best version for it.
> Its all built in so you don't need to do anything except set your custom placeholder `%custom_cpu_threads%` as explained in video.
> If you wish to utilize all CPU threads available use `$(nproc)` as your CPU thread value or skip it as thats default.  

**NVIDIA GPUs**  
> By default command arguments should be sufficient to run normally.
**Update**  
> Since version 3.0 Qubic client has been placed as unified package that can simulatenously mine on your CPU and GPU.  
> Qubicmine.PRO client has been added as separate miner to reduce updates of both miners.  

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

## Due to QUBIC moving for scheduled mining scheme we've implemented a trigger to switch miner profiles on idle. 
### Using Qubic client idle commands:
In version 2.0 options for switching during idle are `--command` and `--arguments`.  
Example: --command "/opt/mmp/miners/lolmniner-equihash/lolMiner" --arguments "-a AUTOLYKOS2..."  
3.0 has added two more options that can be used for Pre and Post.  
Example: --pre|postCommand "ping" --pre|postArguments "google.com"  
In version 3.3 new XMR options have been introduced: `--enable-xmr` or `--enable-monero` will enable XMR mining on your CPU directly to qubic client.  
You can provide monero options by passing `--xmr-opts` or `--monero-opts` "place-your-xmrig-options-here".  
We have enabled option `--gpus` which allows you to disable certain GPUs from mining.  
Option is case sensitive, it requires passing all GPUs as either 0 or -1.  
Example: --gpus "0,-1,0,-1" will disable GPU0 and GPU2, GPU1 and GPU3 will remain enabled.  
We highly recommend to use our API method below to achieve same result but with better stats and OC control.  
### :warning: Disclaimer! Do the below approach only on one mmpOS rig or other linux supporting crontab. Doesn't have to be set on every rig, just one is enough.  
Fetch all profiles(limit 100) and post them via `Initiate command prior to miner launch`.  
Make sure to export API_TOKEN, and FID(farm id).  
CLI command:  
```
export API_TOKEN=Your-API-Token-from-profiles
```
Use this to fetch Farm IDs:  
```
curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/farms |jq -r '.[]|{name: .name, id}'
```
Or if you haven't renamed your farm use this(Replace Default if you've renamed your farm differently):  
```
FID=$(curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/farms | jq -r '.[] | select(.name == "Default" and .own_access_role == "ROLE_FARM_OWNER") | .id')
```
Then use this to fetch miner profiles limited to 100:  
```
curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/${FID}/miner_profiles?limit=100 |jq -r .  
```
You can also fetch profiles by coin(QUBIC example, but it can be any supported coin):  
```
curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/${FID}/miner_profiles?limit=100 |jq -r '.[] | select(.coin == "QUBIC") | {name: .name, id'}
```
Final steps:   
We've added [qubic-switch.sh](/scripts/qubic-switch.sh) script that monitors Qubic SEED and if its idle period it switches to your secondary profile.  
Also we've added ability to add `+cpu` to your rig names in case you use your CPU to mine other coin or again QUBIC but with CPU.  
In above scenario rigs will switch both to CPU and GPU mining qubic during mining period and will switch to different CPU and GPU profiles on idle period.  
Introduced CPU mining only if you add `-cpu` to your rig name.   
Content is almost the same as with previous method, but we've removed rig UUID from config and added qubic accesstoken for qubic API connection.   
Look inside the script for more information on how to automate the proces.   
>config.txt content:
>
```
API_TOKEN="YOUR-API-TOKEN"  # You can get this if you're at least supporter tier from profile.
FID="YOUR-FARM-ID" # Go to farms on dashboard and copy uuid link of your farm.
MAIN_CPU_PROFILE="original cpu uuid profile mining during qubic idle"
MAIN_GPU_PROFILE="original gpu uuid profile mining during qubic idle"
QUBIC_CPU_PROFILE="qubic cpu profile uuid"
QUBIC_GPU_PROFILE="qubic gpu profile uuid"
QUBIC_ACCESSTOKEN="your pool.qubic.li access token"
```
> rigs.txt content:
>
```
rig1
rig2+cpu
rig3-cpu
rig4
```
These are your rig's names. In this particular example rig2 mines with CPU and rig3 is CPU mining only.  
While rig1 and rig4 are GPU mining only.  
Finally add the script to your crontab(use `sudo crontab -e`):
```
 * * * * * /home/miner/qubic/qubic-switch.sh >/dev/null 2>&1
```
>
# Here is an automated setup to simplify your settings:  
```
mkdir -p qubic && cd qubic;
wget https://raw.githubusercontent.com/ddobreff/mmpos/refs/heads/main/scripts/qubic-switch.sh -O qubic-switch.sh && chmod +x qubic-switch.sh;
export API_TOKEN=YOUR-API-TOKEN
FID=$(curl --silent -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/farms | jq -r '.[] | select(.name == "Default" and .own_access_role == "ROLE_FARM_OWNER") | .id')
cat <<- EOF > config.txt
API_TOKEN="REPLACE-THIS-WITH-YOUR-ACTUAL-API-KEY"
FID="$FID"
MAIN_GPU_PROFILE=""
MAIN_CPU_PROFILE=""
QUBIC_GPU_PROFILE=""
QUBIC_CPU_PROFILE=""
QUBIC_ACCESSTOKEN=""
EOF
(crontab -l 2>/dev/null | grep -v "/home/miner/qubic/qubic-switch.sh" ; echo "* * * * * /home/miner/qubic/qubic-switch.sh >/dev/null 2>&1") | crontab -
```
After that make sure to edit empty profile UUIDs and Qubic accesstoken.  
Of course you can modify the script to switch only CPU profiles.  
Feel free to publish changes.   

