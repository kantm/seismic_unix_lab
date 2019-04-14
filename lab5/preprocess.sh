#! /bin/sh

### Pre-processing steps to be applied to CDP gathers to ready the data for velocity analysis:

### 1. Muting direct arrivals
### 2. Gain
### 3. Predictive deconvolution
### 4. Band pass filtering

### We will pick 100 CDPs of Viking Graben data

suwind < vikinggraben.su key=cdp min=401 max=500 > 100cmp.su

### Mute direct arrivals: helps with velocity analysis
### We first form a "supergather" in CMP domain by stacking along offsets

susort offset < 100cmp.su | sustack key=offset | sugain jon=1 > superCMP.su

### View the supergather and pick t and x values

suxiwgb < superCMP.su key=offset &

### Mute the direct arrivals in CMP gathers using sumute. Modify the following command:

sumute < 100 cmp.su tmute= xmute= > mute_100cmp.su


### Gain the data and make it minimum phase. Modify the following command:

sugain < mute_100cmp.su agc=1 | sushape wfile=resamp_farfield.su dfile=minphs_farfield.su nshape=1500 > gain_minphs.su

### Do Predictive error filtering after nmo and inverse nmo. Modify the following command

sunmo < gain_minphs.su vnmo=1450 smute=5.0 | supef minlag=0.02 maxlag=0.6 | sunmo vnmo=1450 invert=1 smute=5.0 > decon100cdp.su



exit 0
