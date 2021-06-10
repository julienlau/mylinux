#!/bin/bash
. /etc/profile

skip=0
force=0

gdalver=1.11.5

if [[ $# -ge 1 ]] ; then
    gdalver=$1
fi

dest=/opt/gdal-$gdalver
#prefix=/usr/local
prefix=$dest
if [[ $# -ge 2 ]] ; then
    prefix=$2
fi

echo "gdal version $gdalver"
echo "gdal install prefix $prefix"

# pre-requisite : apt install -y gcc libhdf4-alt-dev vim openjdk-8-jdk-headless swig ant
echo "Check prerequisites"
listPrereq="gcc swig ant"
missing=0
for elem in $listPrereq; do
    if [[ -z $(which $elem 2>/dev/null) ]]; then
        echo "ERROR ! Missing pre-requisite : $elem"
        missing=$(($missing+1))
    fi
done
echo "Check prerequisites lib"
listPrereq="libmfhdf"
for elem in $listPrereq; do
    if [[ -z $(ldconfig -p | grep $elem 2>/dev/null) ]]; then
        echo "ERROR ! Missing pre-requisite : $elem"
        missing=$(($missing+1))
    fi
done
if [[ $missing -ne 0 ]] ; then echo "ERROR ! apt install -y gcc libhdf4-alt-dev vim openjdk-8-jdk-headless swig ant" ; exit 1 ; fi
$JAVA_HOME 
if [[ -z $JAVA_HOME ]] ; then echo "ERROR ! JAVA_HOME not set" ; exit 1 ; fi

if [[ -e $dest ]]; then
    if [[ $force = "1" ]]; then
        \rm -rf $dest
    elif [[ $skip = "1" ]]; then
        echo "directory already exists $dest"
    else
        echo "directory already exists $dest"
        exit 0
    fi
fi

echo "installing gdal version $gdalver into $dest"
archname=gdal-$gdalver.tar.gz

\cd /tmp
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
if [[ ! -e /tmp/$archname ]] ; then
    wget http://download.osgeo.org/gdal/$gdalver/$archname
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
fi

cd /opt
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
tar zxvf /tmp/$archname
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
cd $dest
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
if [[ ! -d bulid ]] ; then
    mkdir -p build
fi
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
./configure --prefix=$dest/build --with-threads \
            --with-ogr \
            --with-geos \
            --without-libtool \
            --with-libz=internal \
            --with-libtiff=internal \
            --with-geotiff=internal \
            --without-pg \
            --without-grass \
            --without-libgrass \
            --without-cfitsio \
            --without-pcraster \
            --without-netcdf \
            --without-ogdi \
            --without-fme \
            --without-jasper \
            --without-ecw \
            --without-kakadu \
            --without-mrsid \
            --without-jp2mrsid \
            --without-bsb \
            --without-mysql \
            --without-ingres \
            --without-xerces \
            --without-expat \
            --without-odbc \
            --without-curl \
            --without-sqlite3 \
            --without-dwgdirect \
            --without-panorama \
            --without-idb \
            --without-sde \
            --without-perl \
            --without-php \
            --without-ruby \
            --without-ogpython \
            --with-hide-internal-symbols \
            --with-java=${JAVA_HOME}
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? configure" ; exit 1 ; fi
sed -i "1s:^:JAVA_HOME = ${JAVA_HOME}\n:" swig/java/java.opt
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? edit JAVA_HOME" ; exit 1 ; fi
make
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? make" ; exit 1 ; fi
make install
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? make install" ; exit 1 ; fi
cd swig/java
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
make install
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? make for java swig" ; exit 1 ; fi
make install
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? make install for java swig" ; exit 1 ; fi
chmod -R go+rX $dest
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? chmod" ; exit 1 ; fi

\rm -f /tmp/$archname
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi

echo "Done"
