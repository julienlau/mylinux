FROM debian:buster AS build
RUN echo "deb http://ftp.debian.org/debian stable main contrib non-free" >> /etc/apt/sources.list

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV TERM vt100
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Toulouse
ENV NCPU=6

RUN apt-get update -y \
    && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --fix-missing --no-install-recommends \
        bzip2 \
        unzip \
        ca-certificates \
        git \
        wget \
        curl \
        iputils-ping \
        zlib1g-dev \
        gcc \
        g++ \
        cmake \
        ninja-build \
        libcurl4-openssl-dev \
        libtbb2=2020.3-1 \
        libtbb-dev=2020.3-1 \
    && apt-get clean

ENV PATH /opt/conda/bin:$PATH

CMD [ "/bin/bash" ]

# Leave these args here to better use the Docker build cache
ENV CONDA_VERSION=py38_4.9.2
ENV CONDA_MD5=122c8c9beb51e124ab32a0fa6426c656
ENV CONDA_ENV=pdal
ENV CONDA_PATH=/opt/conda/envs/${CONDA_ENV}
# TODO : use conda-lock

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -O miniconda.sh && \
    echo "${CONDA_MD5}  miniconda.sh" > miniconda.md5 && \
    if ! md5sum --status -c miniconda.md5; then exit 1; fi && \
    mkdir -p /opt && \
    sh miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh miniconda.md5 && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

RUN \
    conda update -n base -c defaults conda && \
    conda create -n pdal -y && \
    conda install --yes -c conda-forge conda-pack

RUN conda install --yes --name pdal -c conda-forge nomkl pdal==2.4.0 gdal==3.4.2 python-pdal==3.1.2

RUN conda install --yes --name pdal -c conda-forge nomkl tbb==2020.3 zlib==1.2.11
SHELL ["conda", "run", "--no-capture-output", "-n", "pdal", "/bin/bash", "-c"]

# install LAStools
ENV LASTOOLS_VERSION=2.0.1
WORKDIR /opt
# fast fail if no internet connection
RUN timeout -s 2 2 ping -c 1 google.com
RUN wget https://github.com/LAStools/LAStools/archive/refs/tags/v${LASTOOLS_VERSION}.tar.gz && \
    tar -xzf v$LASTOOLS_VERSION.tar.gz && mkdir LAStools-$LASTOOLS_VERSION/build
RUN cd /opt/LAStools-$LASTOOLS_VERSION/build  && \
    cmake -G Ninja -DCMAKE_INSTALL_PREFIX:PATH=/usr/local -DCMAKE_BUILD_TYPE=Release .. && \
    ninja -j ${NCPU}
RUN cd /opt/LAStools-$LASTOOLS_VERSION/bin && \
    find . -type f -executable -exec cp {} /usr/local/bin/. \; && \
    cd /opt/LAStools-$LASTOOLS_VERSION/bin64 && \
    find . -type f -executable -exec cp {} /usr/local/bin/. \; && \
    rm -f v$LASTOOLS_VERSION.tar.gz && \
    rm -rf /opt/LAStools-$LASTOOLS_VERSION

# install PotreeConverter 1
ENV POTREE_CONVERTER_1_VERSION=1.6
WORKDIR /opt
RUN git clone https://github.com/m-schuetz/LAStools.git lastools && \
    cd lastools && \
    git checkout 965e5e8ccf9708cbceab082aea7ce6f15fd2bec5 && \
    mkdir LASzip/build && \
    cd LASzip/build && \
    cmake -G Ninja -DCMAKE_INSTALL_PREFIX:PATH=/usr/local -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_LIBRARY_PATH=${CONDA_PATH}/lib \
    -DCMAKE_INCLUDE_PATH=${CONDA_PATH}/include \
    .. && \
    ninja -j ${NCPU} all &&\
    ninja install &&\
    mkdir /usr/local/include/LASzip && \
    cp -r /opt/lastools/LASzip/dll/laszip_api.c /usr/local/include/LASzip/. && \
    cp -r /opt/lastools/LASzip/dll/laszip_api.h /usr/local/include/LASzip/. && \
    rm -rf /opt/LAStools

WORKDIR /opt
RUN wget --quiet https://github.com/potree/PotreeConverter/archive/$POTREE_CONVERTER_1_VERSION.tar.gz && \
    tar -xzf $POTREE_CONVERTER_1_VERSION.tar.gz && \
    mkdir PotreeConverter-$POTREE_CONVERTER_1_VERSION/build && \
    cd PotreeConverter-$POTREE_CONVERTER_1_VERSION/build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DLASZIP_INCLUDE_DIRS=/usr/local/include/LASzip \
    -DLASZIP_LIBRARY=/usr/local/lib/liblaszip.so \
    -DCMAKE_LIBRARY_PATH=${CONDA_PATH}/lib \
    -DCMAKE_INCLUDE_PATH=${CONDA_PATH}/include \
    .. && \
    ninja -j ${NCPU} all &&\
    ninja install &&\
    mkdir /usr/local/bin/PotreeConverter-$POTREE_CONVERTER_1_VERSION && \
    mv PotreeConverter/PotreeConverter /usr/local/bin/PotreeConverter-$POTREE_CONVERTER_1_VERSION && \
    cp -r ../PotreeConverter/resources /usr/local/bin/PotreeConverter-$POTREE_CONVERTER_1_VERSION/. && \
    cd /usr/local/bin && \
    ln -s /usr/local/bin/PotreeConverter-$POTREE_CONVERTER_1_VERSION/PotreeConverter PotreeConverter-1 && \
    rm -f /opt/$POTREE_CONVERTER_1_VERSION.tar.gz && \
    rm -rf /opt/$POTREE_CONVERTER_1_VERSION

# install PotreeConverter 2
ENV POTREE_CONVERTER_2_VERSION=2.1
WORKDIR /opt
RUN wget --quiet https://github.com/potree/PotreeConverter/archive/$POTREE_CONVERTER_2_VERSION.tar.gz && \
    tar -xzf $POTREE_CONVERTER_2_VERSION.tar.gz && \
    mkdir PotreeConverter-$POTREE_CONVERTER_2_VERSION/build && \
    cd PotreeConverter-$POTREE_CONVERTER_2_VERSION/build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_LIBRARY_PATH=${CONDA_PATH}/lib \
    -DCMAKE_INCLUDE_PATH=${CONDA_PATH}/include \
    .. && \
    ninja -j ${NCPU} all &&\
    mkdir /usr/local/bin/PotreeConverter-$POTREE_CONVERTER_2_VERSION && \
    cd /usr/local/bin && \
    mv /opt/PotreeConverter-$POTREE_CONVERTER_2_VERSION/build/PotreeConverter PotreeConverter-$POTREE_CONVERTER_2_VERSION/  && \
    ln -s /usr/local/bin/PotreeConverter-$POTREE_CONVERTER_2_VERSION/PotreeConverter PotreeConverter-2 && \
    rm -f /opt/$POTREE_CONVERTER_2_VERSION.tar.gz && \
    rm -rf /opt/$POTREE_CONVERTER_2_VERSION

RUN cd /usr/local && \
    tar cf usrlocal.tar bin include lib share

RUN conda-pack -n pdal --dest-prefix=/opt/conda/envs/pdal -o /tmp/env.tar && \
     mkdir /venv && cd /venv && tar xf /tmp/env.tar  && \
     rm /tmp/env.tar

FROM debian:buster-slim
RUN echo "deb http://ftp.debian.org/debian stable main contrib non-free" >> /etc/apt/sources.list

ENV TERM vt100
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Toulouse

RUN apt-get update -y \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt upgrade -y \
    && apt-get install -y --fix-missing --no-install-recommends python3-pip \
    && apt autoremove --purge -y \
    && apt clean -y

WORKDIR /usr/local
COPY --from=build /usr/local/usrlocal.tar .
RUN tar xf usrlocal.tar && rm /usr/local/usrlocal.tar

ENV CONDA_PATH="/opt/conda/envs/pdal"
COPY --from=build /venv "/opt/conda/envs/pdal"

ENV DTED_APPLY_PIXEL_IS_POINT=TRUE
ENV GTIFF_POINT_GEO_IGNORE=TRUE
ENV GTIFF_REPORT_COMPD_CS=TRUE
ENV REPORT_COMPD_CS=TRUE
ENV OAMS_TRADITIONAL_GIS_ORDER=TRUE
ENV PDAL_DRIVER_PATH=${CONDA_PATH}/lib
ENV GDAL_DATA=${CONDA_PATH}/share/gdal
ENV _CONDA_SET_PDAL_PYTHON_DRIVER_PATH=${CONDA_PATH}/lib
ENV PDAL_DRIVER_PATH=${CONDA_PATH}/lib:${CONDA_PATH}/lib/python3.10/site-packages/lib:${CONDA_PATH}/lib/python3.10/site-packages/lib64:${CONDA_PATH}/lib/python3.10/site-packages/pdal
ENV PROJ_LIB=${CONDA_PATH}/share/proj:/usr/local/share/proj
ENV PROJ_NETWORK=ON
ENV CPL_ZIP_ENCODING=UTF-8
ENV PATH=${CONDA_PATH}/bin:${CONDA_PATH}/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=${CONDA_PATH}/lib:/usr/local/lib
ENV CONDA_EXE=${CONDA_PATH}/bin/conda
ENV CONDA_PREFIX=${CONDA_PATH}
ENV CONDA_PYTHON_EXE=${CONDA_PATH}/bin/python

