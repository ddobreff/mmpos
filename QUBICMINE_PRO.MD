# How to mine qubic on [Qubicmine.pro](https://qubicmine.pro/get-started)


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
> The switch from default qubic.li client is `--provider qubicmine`

**Sample Configuration for CPUs**
![Profile](/imgs/qubicmine-cpu.png)  
> If you don't add `--trainer` it will automatically choose best.  
> Use option `--hugepages` as custom placeholder too to setup different hugepages per Rig.  

```
--trainer AVX512|AVX2|Generic --provider qubicmine --cpu-threads %custom_cpu_threads%
```

**Sample Configuration for AMD GPUs**
![Profile](/imgs/qubicmine-amd.png)  

```
--trainer AMD --provider qubicmine
```

**Sample Configuration for NVIDIA GPUs**
![Profile](/imgs/qubicmine-nvidia.png)  

```
--trainer CUDA12 --provider qubicmine
```
>![IMPORTANT] Make sure you use `--payoutid` for qubicmine.pro client as argument and in wallet too. 
>![IMPORTANT] Qubicmine.Pro uses QUBIC ID which is 60 character long WALLET.  

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

