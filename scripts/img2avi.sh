#!/bin/bash

nfps=4
imgtype=jpg
isresize="0"

if [[ $# -lt 3 ]] ; then
  echo "Please give at least 3 input "
  echo "  number of fps ?"
  echo "  BASENAME *.jpg ?"
  echo "  type of image files (jpg, bmp, png, tga) ?" 
  echo "  optional : resolution in case of a rescaling ('1280x1138') ?" 
  exit 1
else
  nfps=$1
  imgbasename=$2
  imgtype=$3
  if [[ $# -ge 4 ]] ; then
      isresize=$4
  fi
fi

if [[ $(which mencoder | grep -c 'no mencoder in') -gt 0 ]]; then
    if [[ "$(echo $HOSTNAME | grep 'cae')" != "" ]] ; then
        echo "ERROR ! please do the cmd and relaunch:"
        echo 'eval $(gmplayer --setenvironment)'
        exit 9
    elif [[ "$(echo $HOSTNAME | grep 'lindyn')" != "" ]] ; then
        export PATH=$PATH:/home/OPENSOURCE/MPLAYER/1.0rc2/Linux/RHEL4_2.6/x86_64/64b/bin/
    fi
fi

ismontage=1
if [[ $(which montage | grep -c 'no montage in') -gt 0 ]]; then
    ismontage=0
fi

# list=$(\ls ${imgbasename}*.${imgtype})
# echo "Converting ${imgtype} to png"
# for f in $list ; do
#     convert $f ${f%%$imgtype}png
# done
# imgtype=png

## in order to assemble to images side by side: convert a.png -flop b.png +append b.png
if [[ ! -z $(\ls logo*.jpg) ]] ; then
    list=$(\ls ${imgbasename}*.${imgtype})
    echo "Assembling images with logo "
    convert logo*.jpg +append -resize 384x50 assembled_logo.jpg
    for f in $list ; do
        filewithlogo=$(dirname $f)/with_logo_$(basename $f)
        if [[ ! -f $filewithlogo ]] ; then
            if [[ 1 -eq 2 && $ismontage -eq 1 ]] ; then
                montage -mode concatenate -tile 1x assembled_logo.jpg $f $filewithlogo
                if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? montage " ; exit 1 ; fi
            else
                convert $f assembled_logo.jpg -append $filewithlogo
                if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? convert " ; exit 1 ; fi
            fi
        fi
    done
    imgbasename=$(dirname $imgbasename)/with_logo_$(basename $imgbasename)
    #mogrify -antialias -resize 1280x1240 with_logo_$imgbasename
fi

# add title:
# convert image.gif -background black label:'ztitle ...' -gravity Center -append anno_label.jpg

# in order to add a pointer:
# composite -geometry +31+105 pointer.gif image.gif image_with_pointer.jpg

if [[ $isresize != "0" ]] ; then
    echo "Resizing images using resolution $isresize"
    list=$(\ls ${imgbasename}*.${imgtype})
    for f in $list ; do
        #mogrify -antialias -resize $isresize $f
        #mogrify -antialias -resize $isresize $f
        #mogrify -scale 50% $f
        convert -resize $isresize $f
    done
fi

###########################
# bitrate((Taille fichier * 1024 * 1024 / ( Duree du film * 60)) * 8 - (bitrate audio * 1024)) / 1024 = 889.29
# optimal_bitrate = 50 * 25 * width * height / 256
bitrate=$((1280*1138/256*50*10))
bitrate=3000000

\rm -f output.avi

#mencoder mf://${imgbasename}*.${imgtype} -mf fps=$nfps:type=$imgtype -ovc copy -o output.avi
# mencoder mf://${imgbasename}*.${imgtype} -mf fps=$nfps:type=$imgtype -ovc divx4 -o output.avi
# mencoder mf://${imgbasename}*.${imgtype} -mf fps=$nfps:type=$imgtype -ovc lavc -o output.avi


#For the msmpeg4v2 codec:

#opt=":vbitrate=$bitrate:mbd=2:keyint=25:vqblur=1.0:cmp=2:subcmp=2:dia=2:mv0:last_pred=3:aspect=4/3"
opt=":vbitrate=$bitrate:mbd=2:keyint=25:vqblur=1.0:cmp=2:subcmp=2:dia=2:mv0:last_pred=3"
# mencoder -ovc lavc -lavcopts vcodec=msmpeg4v2:vpass=1$opt -mf type=$imgtype:fps=$nfps -nosound -o /dev/null mf://${imgbasename}*.${imgtype}
# mencoder -ovc lavc -lavcopts vcodec=msmpeg4v2:vpass=2$opt -mf type=$imgtype:fps=$nfps -nosound -o output.avi mf://${imgbasename}*.${imgtype}

# mencoder -ovc lavc -lavcopts vcodec=msmpeg4v2:vpass=1$opt -mf type=$imgtype:fps=$nfps -vf scale=1280:700 -nosound -o /dev/null mf://${imgbasename}*.${imgtype}
# mencoder -ovc lavc -lavcopts vcodec=msmpeg4v2:vpass=2$opt -mf type=$imgtype:fps=$nfps -vf scale=1280:700 -nosound -o output.avi mf://${imgbasename}*.${imgtype}

#For the mpeg4 codec:
#opt=":vbitrate=$bitrate:mbd=2:keyint=132:v4mv:vqmin=3:lumi_mask=0.07:dark_mask=0.2:mpeg_quant:scplx_mask=0.1:tcplx_mask=0.1:naq"
opt=":vbitrate=$bitrate:mbd=2:keyint=132:v4mv:vqmin=3:lumi_mask=0.07:dark_mask=0.2:mpeg_quant:scplx_mask=0.1:tcplx_mask=0.1"
mencoder -ovc lavc -lavcopts vcodec=mpeg4:vpass=1$opt -mf type=$imgtype:fps=$nfps -nosound -o /dev/null mf://${imgbasename}*.${imgtype}
mencoder -ovc lavc -lavcopts vcodec=mpeg4:vpass=2$opt -mf type=$imgtype:fps=$nfps -nosound -o output.avi mf://${imgbasename}*.${imgtype}

#for f in *ppm ; do convert -quality 100 $f `imgbasename $f ppm`jpg; done 

#With mencoder, we can use the vbitrate option to set the degree of lossy compression. Note that the default mpeg4 option will add a "DivX" logo to the movie when playin in windows media player, so we prefer to use one of the other mpeg4 encoders, such as msmpeg4 or msmpeg4v2. The commmand line I've used is:

#mencoder mf://${imgbasename}*.${imgtype} -mf fps=$nfps -o output.avi -ovc lavc -lavcopts vcodec=msmpeg4v2:vbitrate=800 

#We can also use ffmpeg directly to encode the images files into a movie. If we start with files name 001.jpg, 002.jpg, ..., we can use:

#ffmpeg -r 10 -b 1800 -i %03d.jpg output.mp4

#This works very well, and is nice because ffmpeg is included in debian! My only complaint is that with ffmpeg is that you have to be careful that all the files are named sequentially. For example, for a long time, I was missing 015.jpg, which caused it to encode only 15 frames. To get it to work, I had to rename the files so that there were no gaps in the file numbers. The .mp4 files encoded this way will play fine with quicktime under windows, which I peronally prefer over media player, and which will never show the stupid DiVX logo, since it's doesn't use the braindead avi container. (see rant above...) 
###############################
#http://web.njit.edu/all_topics/Prog_Lang_Docs/html/mplayer/encoding.html

#Creating a DivX4 file from all the JPEG files in the current dir:
#mencoder mf://${imgbasename}*.${imgtype} -mf w=800:h=600:fps=$nfps -ovc divx4 -o output.avi

#Creating a DivX4 file from some JPEG files in the current dir:
#mencoder -mf w=800:h=600:fps=$nfps -ovc divx4 -o output.avi mf://${imgbasename}*.${imgtype}

#Creating a Motion JPEG (MJPEG) file from all the JPEG files in the current dir:
#mencoder mf://${imgbasename}*.${imgtype} -mf w=800:h=600:fps=$nfps -ovc copy -o output.avi

#Creating an uncompressed file from all the PNG files in the current dir:
#mencoder mf://${imgbasename}*.${imgtype} -mf w=800:h=600:fps=$nfps:type=$imgtype -ovc rawrgb -o output.avi 

#Note: Width must be integer multiple of 4, it is a limitation of the RAW RGB AVI format.

#Creating a Motion PNG (MPNG) file from all the PNG files in the current dir:
#mencoder mf://${imgbasename}*.${imgtype} -mf w=800:h=600:fps=$nfps:type=$imgtype -ovc copy -o output.avi

#Creating a Motion TGA (MTGA) file from all the TGA files in the current dir:
#mencoder mf://${imgbasename}*.${imgtype} -mf w=800:h=600:fps=$nfps:type=$imgtype -ovc copy -o output.avi

############################
