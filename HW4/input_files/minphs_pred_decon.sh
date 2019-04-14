#! /bin/sh
WIDTH=420
HEIGHT=400
WIDTHOFF1=0
WIDTHOFF2=430
WIDTHOFF3=860
HEIGHTOFF1=0
HEIGHTOFF2=410

###PURPOSE###
# We make some simple data: 8 traces with 2-way reverberations and
# a weak tilting reflector hidden underneath the reverberations.  The
# spike data is convolved with the minimum phase wavelet specified below.
# Then a tiny bit of noise is added--tiny because: (1) the definition
# of signal to noise is stringent--based on the biggest amplitude
# on the trace and (2) these are single traces, usually you'd have
# a cmp gather and the ultimate goal of stacking to combat noise.

# In this demo, we do gapped decon
# (prediction error filtering).  You are to assume that the decon
# parameters are estimated from the autocorrelation shown in frame two.

# Construction of the minimum phase wavelet with Mathematica:
# (2-z)(3+z)(3-2z)(4+z)(4-2z)(4+3z)//(CoefficientList[#,z])&
#     {1152, -384, -904, 288, 174, -34, -12}


MINLAG_PEF=0.004 ### Gap length in predictive deconvolution
MAXLAG_PEF=0.60  ### Operator length


SNR=25         ### Signal to Noise ratio
PNOISE=0.0001    ### Pre-whitening parameter

# First make the synthetic data for the deconvolution demo.
######START OF MODEL######
I=${CWPROOT}/include
L=${CWPROOT}/lib

make

# make a minimum phase wavelet

suspike ntr=1 nspk=1 ix1=1 it1=1 > spike.su
suconv < spike.su filter=1152,-384,-904,288,174,-34,-12 > minphs_wavelet.su



./traces |
suaddhead ns=512 |
sushw key=dt a=4000 |
suconv sufile=minphs_wavelet.su | sugain tpow=1.0 > nonoise_minphs_modeldata.su

## Add some noise to the data with signal to noise ratio = SNR

suaddnoise < nonoise_minphs_modeldata.su > minphs_modeldata.su sn=$SNR

rm traces
######END OF MODEL######

# Plot the data
suxwigb < minphs_modeldata.su title="Data: 64ms reverbs" \
	windowtitle="Data" \
	label1="Time (sec)" label2="Trace" \
    wbox=$WIDTH hbox=$HEIGHT xbox=$WIDTHOFF1 ybox=$HEIGHTOFF1 &
 
# Plot the autocorrelation
 suacor < minphs_modeldata.su ntout=101 | \
 suxwigb f1=-0.2 title="Autocorrelation of Data" \
	windowtitle="AutoCorr" \
	label1="Time (sec)" label2="Trace" \
	wbox=$WIDTH hbox=$HEIGHT xbox=$WIDTHOFF2 ybox=$HEIGHTOFF1 &

# The autocorrelation shows that:
#       wavelet extends to about 30ms
#       period of reverberations is 64ms
# this accords well with the actual 64ms reverberations and wavelet of 24ms


# Plot the spectrum
suspecfx < minphs_modeldata.su | suxwigb \
    title="Ampl. spectrum before decon" \
    label1="Frequency (Hz)" label2="Trace" \
    wbox=$WIDTH hbox=$HEIGHT xbox=$WIDTHOFF3 ybox=$HEIGHTOFF1 &
 
######DECON EXAMPLES######



# Only Predictive error filtering
supef < minphs_modeldata.su pnoise=$PNOISE minlag=$MINLAG_PEF maxlag=$MAXLAG_PEF > minphs_pef_modeldata.su



# Decon may boost noise, apply bandpass filtering
sufilter < minphs_pef_modeldata.su f=5,20,80,110 amps=0,1,1,0 > minphs_filt_pef.su

suxwigb < minphs_filt_pef.su label1="Time"  label2="Trace" \
    title="Spiking, then PEF, min Phase" \
    windowtitle="PEF" \
    wbox=$WIDTH hbox=$HEIGHT xbox=$WIDTHOFF1 ybox=$HEIGHTOFF2 &

# Plot the autocorrelation after PEF

suacor < minphs_filt_pef.su ntout=101 | \
    suxwigb f1=-0.2 title="Autocorrlation of PEF data, min Phase" \
    label1="Time (sec)" label2="Trace" \
    wbox=$WIDTH hbox=$HEIGHT xbox=$WIDTHOFF2 ybox=$HEIGHTOFF2 &

# Plot the spectrum
suspecfx < minphs_filt_pef.su | suxwigb \
    title="Ampl. spectrum after decon" \
    label1="Frequency (Hz)" label2="Trace" \
    wbox=$WIDTH hbox=$HEIGHT xbox=$WIDTHOFF3 ybox=$HEIGHTOFF2 &

exit 0