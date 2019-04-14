#! /bin/sh

### Extract CDP number 265

#suwind < vikinggraben.su key=cdp min=465 max=465 | sugain tpow=2.0 > 265cdp.su

## Do NMO correction with water velocity
sunmo < 265cdp.su vnmo=1450 > junk.su
suxwigb < 265cdp.su title="CDP 265" label1="Time(sec)" label2="offset" key=offset perc=99 &
suxwigb < junk.su title="CDP 265, water velocity" label1="Time(sec)" label2="offset" key=offset perc=99 &
suvelan < 265cdp.su nv=240 dv=10.0 fv=1200.0 | suximage title="Velocity spectrum, CDP 265" label1="Time (sec)" label2="Velocity (m/s)" perc=99 f2=1200 d2=10.0 &

## Hyperbolic Radon transform to remove multiples
suradon < junk.su offref=-3237 interoff=-262 pmin=-1000 pmax=1000 \
dp=8 choose=0  igopt=2  depthref=370 | suximage \
label1="Tau (sec)" label2="p" title="Hyperbolic Radon transform of NMO'ed CDP 265" perc=99 &

suradon < junk.su offref=-3237 interoff=-262 pmin=-2000 pmax=2000 \
dp=8 choose=1  igopt=2 pmula=-400 pmulb=0 depthref=370 | \
sunmo vnmo=1450 invert=1  > junk1.su
suxwigb < junk1.su title="CDP 265, multiples removed" label1="Time(sec)" label2="offset" key=offset perc=99 &
suvelan < junk1.su nv=240 dv=10.0 fv=1200.0 | suximage title="Velocity spectrum, demultipled CDP 265" label1="Time (sec)" label2="Velocity (m/s)" perc=99  f2=1200 d2=10.0 &

## Estimated multiples with Hyperbolic Radon transform
suradon < junk.su offref=-3237 interoff=-262 pmin=-2000 pmax=2000 \
dp=8 choose=2  igopt=2 pmula=-400 pmulb=0 depthref=370 | \
sunmo vnmo=1450 invert=1  > junk2.su
suxwigb < junk2.su title="CDP 265, estimated multiples" label1="Time(sec)" label2="offset" key=offset perc=99 &
suvelan < junk2.su nv=240 dv=10.0 fv=1200.0 | suximage title="Velocity spectrum, multiples of CDP 265" label1="Time (sec)" label2="Velocity (m/s)" perc=99 f2=1200 d2=10.0 &

exit 0