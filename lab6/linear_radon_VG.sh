#! /bin/sh

### Extract CDP number 450

susort < vikinggraben.su cdp offset | suwind key=cdp min=450 max=450 | sugain tpow=2.0 > 450cdp.su

## Do NMO correction with water velocity
sunmo < 450cdp.su vnmo=1450 > junk.su
suxwigb < 450cdp.su title="CDP 450" label1="Time(sec)" label2="offset" key=offset perc=99 &
suxwigb < junk.su title="CDP 450, water velocity" label1="Time(sec)" label2="offset" key=offset perc=99 &
suvelan < 265cdp.su nv=240 dv=10.0 fv=1200.0 | suximage title="Velocity spectrum, CDP 450" label1="Time (sec)" label2="Velocity (m/s)" perc=99 f2=1200 d2=10.0 &

## Radon transform to remove multiples
suradon < junk.su offref=-3237 interoff=-262 pmin=-2000 pmax=2000 \
dp=8 choose=0  igopt=3   | suximage \
label1="Tau (sec)" label2="p" title="Linear Radon transform of NMO'ed CDP 450" perc=99 &

suradon < junk.su offref=-3237 interoff=-262 pmin=-2000 pmax=2000 \
dp=8 choose=1  igopt=3 pmula=-400 pmulb=100 | \
sunmo vnmo=1450 invert=1  > junk1.su
suxwigb < junk1.su title="CDP 450, multiples removed" label1="Time(sec)" label2="offset" key=offset perc=99 &
suvelan < junk1.su nv=240 dv=10.0 fv=1200.0 | suximage title="Velocity spectrum, demultipled CDP 450" label1="Time (sec)" label2="Velocity (m/s)" perc=99  f2=1200 d2=10.0 &

## Estimated multiples with Radon transform
suradon < junk.su offref=-3237 interoff=-262 pmin=-2000 pmax=2000 \
dp=8 choose=2  igopt=3 pmula=-400 pmulb=100  | \
sunmo vnmo=1450 invert=1  > junk2.su
suxwigb < junk2.su title="CDP 450, estimated multiples" label1="Time(sec)" label2="offset" key=offset perc=99 &
suvelan < junk2.su nv=240 dv=10.0 fv=1200.0 | suximage title="Velocity spectrum, multiples of CDP 450" label1="Time (sec)" label2="Velocity (m/s)" perc=99 f2=1200 d2=10.0 &

exit 0