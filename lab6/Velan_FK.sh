#! /bin/sh
# Velocity analyses for the cmp gathers and FK filtering for multiple suppression
# Authors: Dave Hale, Jack K. Cohen, with modifications by John Stockwell. Bharath Shekar added lines for FK filtering
# NOTE: Comment lines preceeding user input start with  ##
#set -x

### CDP gathers from Viking graben data after

### 1. Gain
### 2. Predictive deconvolution


#suwind < vikinggraben.su key=cdp min=401 max=500 > 401to500cdp.su
#sugain < 401to500cdp.su jon=1 | sushape wfile=resamp_farfield.su dfile=minphs_farfield.su nshape=1500 > t2minphs.su

#echo "Doing sorting and  deconvolution"
#susort < t2minphs.su cdp offset | sunmo vnmo=1450 smute=1.2 | supef minlag=0.02 maxlag=0.6 | sunmo vnmo=1450 invert=1 smute=1.2 > decon100cdp.su
#echo "Finished doing deconvolution"

## Set parameters
velpanel=decon100cdp.su	# gained and deconvolved seismic data,
			 		# sorted in cdp's
vpicks=intermediate_stkvel.p1	# output file of intermediate vnmo= and tnmo= values
normpow=0		# see selfdoc for suvelan
slowness=0		# see selfdoc for suvelan
cdpfirst=401		# minimum cdp value in data
cdplast=500		# maximum cdp value in data
cdpmin=401		# minimum cdp value used in velocity analysis
cdpmax=500		# maximum cdp value used in velocity analysis
dcdp=25		# change in cdp for velocity scans
fold=60		 	# only have 12 shots, otherwise would be
			#  64/2=32 for dsx=dgx, or maximum number
			#  of traces per cdp gather
dxcdp=50		# distance between successive midpoints
                        #    in full datas set


## Set velocity sampling and band pass filters
nv=240			# number of velocities in scan
dv=10.0			# velocity sampling interval in scan
fv=1200.0		# first velocity in scan
nout=1500		# ns in data

## Set interpolation type 
interpolation=akima	# choices are linear, spline, akima, mono

## set filter values
f=1,10,80,100		# bandwidth of data to pass
amps=0,1,1,0		# don't change

## number of contours in contour plot
nc=35		# this number should be at least 25
fc=.05		# This number should be between .05 to .15 for real data 
ccolor=blue,green,red
perc=99		# clip above perc percential in amplitude
#xcur=3		# allow xcur trace xcursion

######## You shouldn't have to change anything below this line ###########
#average velocity
vaverage=2500        # this may be adjusted

# binary files output
vrmst=vrmst_int.bin		# Intermediate VRMS(t) interpolated rms velocities


### Get header info
cdpcount=0		 #  counting variable
dxout=0.004		# don't change this

nout=`sugethw ns <$velpanel | sed 1q | sed 's/.*ns=//'`
dt=`sugethw dt <$velpanel | sed 1q | sed 's/.*dt=//'`
dxout=`bc -l <<END
	$dt / 1000000
END`

cdptotal=`bc -l <<END
	$cdplast - $cdpfirst
END`

dtsec=`bc -l <<END
        $dt / 1000000
END`

echo  "Skip Introduction? (y/n) " | tr -d "\012" >/dev/tty
read response
case $response in
n*) # continue velocity analysis


### give instructions
echo
echo
echo
echo
echo "            Instructions for Velocity Analysis."
echo
echo "  A contour semblance map will appear on the left of your screen."
echo "  A wiggle trace plot of the cdp panel being analysed will appear"
echo "  on the right as a aid in picking. Click on the semblance contour"
echo "  map to make that window active."
echo
echo "  Pick velocities by placing cursor on each peak in the"
echo "  semblance plot and typing 's'. Type 'q' when last peak is picked."
echo "  Note, this is 'blind' picking. You will not see any indication"
echo "  on the contour plot that a point has been picked."
echo
echo "  Note also, that it is best if a value of the velocity is picked "
echo "  at the beginning of the data (t=0.0 usually). The picks must "
echo "  be increasing in time. If you feel you have made an incorrect pick"
echo "  you will be given an opportunity to pick the velocities again. "
echo
pause
echo
echo "  Finally, a reasonable value at the latest time of the section "
echo "  should be picked. (Picking reasonable values for the top and bottom"
echo "  of the section ensures that interpolations of the velocities are"
echo "  reasonable. You don't want the wavespeed profile to start at zero "
echo "  velocity."
echo
echo "  For this demo dataset, there will be a maximum of 4 peaks to be"
echo "  picked, as this is the number of reflectors in the model. However,"
echo "  for the far-offset CDP gathers, it may be difficult to pick all "
echo "  4 peaks."
echo
echo "  A graph of the velocity function will appear, and a prompt to" 
echo "  hit the return key will be seen in this terminal window.  You"
echo "  will then see an nmo corrected version of the cdp gather you that"
echo "  you are performing velocity analysis on." 

echo
echo "  You will be prompted in the terminal window to hit return. Then "
echo "  you will be  will be asked if your picks are ok. This gives you "
echo "  a chance to re-pick the velocities if you do not like the velocity"
echo "  function you have obtained."

pause

;;
*y) #continue

echo
echo
echo "Beginning the velocity analysis"
echo
echo
echo

;;
esac

########################### start velocity analysis #####################



cdp=$cdpmin
while [ $cdp -le $cdpmax ]
do
	cdpcount=` expr $cdpcount + 1 `
	ok=false
	reusepanel=false

	
	# see if panel.$cdp exists
	if [ -f panel.$cdp ]
	then
		echo  "panel.$cdp exists. Reuse? (y/n) " | tr -d "\012" >/dev/tty
		read response
		case $response in
		n*) # continue velocity analysis
			reusepanel=false
		;;
		y*) # no need to get velocity panel
			reusepanel=true
		;;
		esac
	fi

	# see if par.$cdp and $vrmst.$cdp exist
	if [ -f par.$cdp ]
	then

		if [ -f $vrmst.$cdp ]
		then
			echo
			echo " file $vrmst.$cdp already exists"
			echo " indicating that cdp $cdp has been picked"
		fi
		echo
		echo " file par.$cdp already exists"
		echo " indicating that cdp $cdp has been picked"
		echo

		echo  "Redo velocity analysis on cdp $cdp? (y/n) " | tr -d "\012" >/dev/tty
		read response
		case $response in
		n*) # continue velocity analysis with next cdp
			ok=true
		;;
		y*) # continue with same value of cdp
			ok=false
		;;
		esac
	fi

	# begin velocity analysis
	while [ $ok = false ]
	do
		echo "Starting velocity analysis for cdp $cdp"

		if [ $reusepanel = false ]
		then
			suwind < $velpanel key=cdp min=$cdp max=$cdp \
					count=$fold > panel.$cdp 
			reusepanel=true
		fi

		suxwigb < panel.$cdp title="CDP gather for cdp=$cdp" \
				xbox=50 mpicks=mpicks.$cdp \
				perc=$perc  wbox=300 &
		sugain tpow=2 < panel.$cdp |
		sufilter f=$f amps=$amps |
		suvelan nv=$nv dv=$dv fv=$fv |
		suximage  f2=$fv d2=$dv xbox=450 wbox=600 \
		units="semblance" cmap=hsv'1' legend=1 \
		label1="Time (sec)" label2="Velocity (m/sec)" \
		title="Velocity Scan (semblance plot) for CMP $cdp" \
		mpicks=mpicks.$cdp

		sort <mpicks.$cdp  -n |
		mkparfile string1=tnmo string2=vnmo >par1.$cdp

		# view the picked velocity function 
		echo "Putting up velocity function for cdp $cdp"
		sed <par1.$cdp '
			s/tnmo/xin/
			s/vnmo/yin/
		' >unisam1.p
		unisam nout=$nout fxout=0.0 dxout=$dxout \
			par=unisam1.p method=$interpolation |
		xgraph n=$nout nplot=1 d1=$dxout f1=0.0 width=400 height=700 \
			label1="Time (sec)" label2="Velocity (m/sec)" \
			title="Velocity Function: CMP $cdp" \
			grid1=solid grid2=solid \
			linecolor=2 style=seismic &

		pause

		# view an NMO of the panel
		echo "Hit return after nmo panel comes up"
        sunmo < panel.$cdp par=par1.$cdp smute=1.2 |
        suxwigb title="NMO of cdp=$cdp" wbox=300  \
        perc=$perc  &

        sunmo < panel.$cdp par=par1.$cdp smute=1.2 | suspecfk dx=25.0 |
        suximage title="FK spectrum after NMO" wbox=600  \
        perc=$perc  &

        # Dip filtering

        sunmo < panel.$cdp par=par1.$cdp smute=1.2 | sudipfilt dx=25.0 \
        slopes=-0.005,0.0,0.001 amps=0,0.1,1.0 | sunmo \
        par=par1.$cdp smute=1.2 invert=1 > panel1.$cdp

        suxwigb < panel1.$cdp label1="Time (sec)" label2="Offset" key=offset \
        title="After dip filtering cdp=$cdp" wbox=600  \
        perc=$perc  &

		pause


		# check to see if the picks are ok
		echo  "Picks OK? (y/n) "  | tr -d "\012" >/dev/tty
		read response
		case $response in
		n*) ok=false ;;
		*) ok=true
			# capture resampled velocity
			unisam nout=$nout fxout=0.0 dxout=$dxout \
			par=unisam.p method=$interpolation > $vrmst.$cdp

			# clean up the screen
			zap ximage
			zap xgraph
			zap xwigb
			zap xcontour
		;;
		esac

	done </dev/tty

	echo
	echo
	echo  "Continue with velocity analysis? (y/n) "  | tr -d "\012" >/dev/tty
	read response
	case $response in
	n*)	# if quitting set cdp to a value large enough to
		# break out of loop 
		cdp=`expr $cdpmax + 1`
	;;
	y*)
		# else get the next cdp
	cdp=`bc -l <<END
		$cdp + $dcdp
END`
	;;
	esac

done

set +x


### Combine the individual picks into a composite sunmo par file
echo "Editing pick files ..."
>$vpicks
echo  "cdp=" | tr -d "\012" >>$vpicks
cdp=$cdpmin
echo  "$cdp"  | tr -d "\012" >>$vpicks
cdp=`bc -l <<END
	$cdp + $dcdp
END`
while [ $cdp -le $cdpmax ]
do
	echo  ",$cdp"  | tr -d "\012" >>$vpicks
	cdp=`bc -l <<END
		$cdp + $dcdp
END`
done
echo >>$vpicks

cdpcount=0
rm $vrmst
cdp=$cdpmin
while [ $cdp -le $cdpmax ]
do
	cat $vrmst.$cdp >> $vrmst
	cat par.$cdp >>$vpicks
	cdp=`bc -l <<END
		$cdp + $dcdp
END`
	cdpcount=` expr $cdpcount + 1 `
done

# build velocity files to be used for later migration
vrmstpar=vrmst.par


# build par files
echo "n1=$nout n2=$cdpcount f2=$cdpmin d2=$dcdp " > $vrmstpar



# final echos
echo "Intermediate V(t) RMS (stacking) velocity file: $vrmst is ready"


exit 0
