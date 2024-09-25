## Setting up rushminer FPGA miner on mmpOS:

Official support is TBA anytime soon. There is launcher script that handles options. Here is some basic command line to get the hang of it:  
```
--algo gram --pool %pool_server%:%pool_port% --worker %rig_name%%miner_id% --wallet %wallet_address% --device FK33 --device C1100 --device ECU50 \
	--option "-g -t ECU50 ramp -t 550" --option "-g -t FK33 ramp -t 620" --option "-g -t C1100 ramp -t 400" \
	--voltage "setvolt -D ECU50,FK33,C1100 -T 600,650,550 -t 90 --progress 4"
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
>       --option "-g -t ECU50 ramp -t 550" \
>       --option "-g -t FK33 ramp -t 620" \
>       --option "-g -t C1100 ramp -t 400"
>
### Set voltage individually per serial or device(You can fetch serials via cli using miner command):    
*Using device type:*  
>	--voltage "setvolt -D ECU50,FK33,C1100 -T 600,650,550 -t 90 --progress 4"  
>
*Using serial:*  
>	--voltage "setvolt -d 50241A29CR9T,153300000944,XFL1WCO4STQT -V 600,650,550 -t 90 --progress 4"  
>
*Script supports --option that will allow passing additional --ftdi-cmd arguments.*  
*Supported devices currently: FK33, TH53, TH53M, TH55, ECU50, C1100, BCU1525, U200, CVP13 - use with --device option.*

## Original miner documentation can be found here:  
[Rushminer](https://github.com/quayd/RushMiner) 
