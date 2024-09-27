## Setting up rushminer FPGA miner on mmpOS:
Since 25.09.2024 rushminer has been officially integrated as native miner in mmpOS.  
There is launcher script that handles options. Here is some basic command line to get the hang of it:  
```
--algo gram --pool %pool_server%:%pool_port% --worker %rig_name%%miner_id% --wallet %wallet_address%  \
	--voltage "setvolt -D ECU50,FK33,C1100 -T 600,650,550 -t 90 --progress 4" \
	--device FK33 --device C1100 --device ECU50 \
	--ftdi-cmd="monitor -t 5500 -p 200 --unit-count=1" \
	--ftdi-cmd="-g -t ECU50 ramp -t 550" \
	--ftdi-cmd="-g -t FK33 ramp -t 620" \
	--ftdi-cmd="-g -t C1100 ramp -t 400"
```
In the above example, we set cclk to 550Mhz on ECU50(U50C) devices, 620 on FK33 and 400 on C1100.  
Voltage is set to 600 on ECU50, 650 on FK33 and 550 on C1100(not sure if that's possible to go below 600 - its just an example).  
`--option` and `--voltage` are just interpreter of `--ftdi-cmd=` but executed in different order.  

## Voltage support:
On CVP13(VU13P) and BCU1525(VU9P) voltage is controlled either via nextjtag or bwtools.  
On ForestKitten33, U50C(ECU50), Varium C1100, TUL TH53/TH53M/TH55 voltage is controlled by calling external executable `changeVoltage(teamredminer)`.  
Since we cannot provide it inside different miner package we try to link it internally if already installed.  

## Additional settings:
### Per device clock settings:
>	--ftdi-cmd="monitor -t 5500 -p 200 --unit-count=1" \
>       --ftdi-cmd="-g -t ECU50 ramp -t 550" \
>       --ftdi-cmd="-g -t FK33 ramp -t 620" \
>       --ftdi-cmd="-g -t C1100 ramp -t 400"
>
### Set voltage globally(must be placed before --device argument):  
>	--voltage "setvolt -v 600 -t 90 -a --progress 4"  
>
### Set voltage individually per serial or device(You can fetch serials via cli using miner command):    
*NEW* Setting voltage by device type:  
>	--voltage "setvolt -D ECU50,FK33,C1100 -T 600,650,550 -t 90 --progress 4"  
>
*NEW* Setting voltage by serial:  
>	--voltage "setvolt -d 50241A29CR9T,153300000944,XFL1WCO4STQT -V 600,650,550 -t 90 --progress 4"  
>
*Supported devices currently: FK33, TH53, TH53M, TH55, ECU50, C1100, BCU1525, U200, CVP13 - use with --device option.*  
*Option `--device <FPGA_DEV>` is reusable and can be supplied as many times as the different devices you have on your rig.*  

### Example mmpOS profile export(1 FK33, 2 ECU50, 1 C1100):  
```
{"miner_profile":{"name":"GRAM-Rushminer","coin":"TON","os":"linux","commandline":"--algo gram --pool %pool_server%:%pool_port% --worker %rig_name% --wallet %wallet_address% --voltage \"setvolt -D ECU50,FK33,C1100 -T 600,650,600 -t 90 --progress 4\" --device FK33 --device C1100 --device ECU50 --ftdi-cmd=\"monitor -t 5500 -p 200 --unit-count=1\" --ftdi-cmd=\"-g -t ECU50 ramp -t 460\" --ftdi-cmd=\"-g -t FK33 ramp -t 560\" --ftdi-cmd=\"-g -t C1100 ramp -t 400\"","miner":"rushminer.default","miner_version":"latest","api_port":3333,"platforms":[]},"pools":[{"url":"ton.hashrate.to","port":"4002","username":"%wallet_address%.%rig_name%%miner_id%","password":"x","name":"GRAM-icemining","coin":"TON","ssl":false}]}
```

### Example mmpOS profile export(1 FK33, 1 TH53M):  
```
{"miner_profile":{"name":"Rushminer-GRAM","coin":"TON","os":"linux","commandline":"--algo gram --pool %pool_server%:%pool_port% --worker %rig_name%%miner_id% --wallet %wallet_address%  --voltage \"setvolt -v 650 -t 90 -a --progress 4\" --device FK33 --device TH53M --ftdi-cmd=\"monitor -t 5500 -p 200 --unit-count=1\" --ftdi-cmd=\"ramp -t 400\"  --max-clock 600","miner":"rushminer.default","miner_version":"latest","api_port":3333,"platforms":[]},"pools":[{"url":"fi.ton.hashrate.to","port":"4002","username":"%wallet_address%.%rig_name%%miner_id%","password":"x","name":"gram icemining","coin":"TON","ssl":false}]}
```
*NOTE* You can always use custom placeholders to set your voltage and clocks per device.  
Name it `fpga_config` for example and edit the placeholder per rig like that:  
>	--voltage "setvolt -D ECU50,FK33,C1100 -T 600,650,600 -t 90 --progress 4" \
>	--device FK33 --device C1100 --device ECU50 \
>	--ftdi-cmd="monitor -t 5500 -p 200 --unit-count=1" \
>	--ftdi-cmd="-g -t ECU50 ramp -t 460" \
>	--ftdi-cmd="-g -t FK33 ramp -t 560" \
>	--ftdi-cmd="-g -t C1100 ramp -t 400"
>
After that in your miner profile as last argument to default arguments add `%custom_fpga_config%` and it will be applied per rig.  
## Original miner documentation can be found here:  
[Rushminer](https://github.com/quayd/RushMiner) 
