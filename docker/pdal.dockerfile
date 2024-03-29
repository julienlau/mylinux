# docker build -t mypdal:2.3.0 -f pdal.dockerfile .

FROM pdal/ubuntubase:latest as build
MAINTAINER Andrew Bell <andrew@hobu.co>

RUN apt install make
RUN cd /opt/ && \
    wget https://ftp.gnu.org/gnu/time/time-1.9.tar.gz && \
    tar zxvf time-1.9.tar.gz && \
    cd time-1.9 && \
    ./configure && \
    make && \
    make install && \
    cp time /usr/bin/time

SHELL ["conda", "run", "-n", "pdal", "/bin/bash", "-c"]

RUN git clone http://github.com/PDAL/PDAL.git pdal && \
    mkdir -p pdal/build && \
    cd pdal/build  && \
    LDFLAGS="-Wl,-rpath-link,$CONDA_PREFIX/lib" cmake -G Ninja  \
        -DCMAKE_LIBRARY_PATH:FILEPATH="$CONDA_PREFIX/lib" \
        -DCMAKE_INCLUDE_PATH:FILEPATH="$CONDA_PREFIX/include" \
        -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
        -DBUILD_PLUGIN_CPD=OFF \
        -DBUILD_PLUGIN_PGPOINTCLOUD=ON \
        -DBUILD_PLUGIN_NITF=ON \
        -DBUILD_PLUGIN_ICEBRIDGE=ON \
        -DBUILD_PLUGIN_HDF=ON \
        -DBUILD_PLUGIN_TILEDB=ON \
        -DBUILD_PLUGIN_E57=ON \
        -DBUILD_PGPOINTCLOUD_TESTS=OFF \
        -DWITH_LAZPERF=ON \
        -DWITH_ZSTD=ON \
        -DWITH_LASZIP=ON \
        ..

RUN cd pdal/build  && \
    ninja

RUN cd pdal/build  && \
    ctest -V

RUN cd pdal/build  && \
    ninja install

RUN conda-pack -n pdal --dest-prefix=/opt/conda/envs/pdal -o  /tmp/env.tar && \
     mkdir /venv && cd /venv && tar xf /tmp/env.tar  && \
     rm /tmp/env.tar

FROM continuumio/miniconda3

ENV CONDAENV "/opt/conda/envs/pdal"
COPY --from=build /venv "/opt/conda/envs/pdal"

ENV PROJ_NETWORK=TRUE
ENV PATH $PATH:${CONDAENV}/bin
ENV DTED_APPLY_PIXEL_IS_POINT=TRUE
ENV GTIFF_POINT_GEO_IGNORE=TRUE
ENV GTIFF_REPORT_COMPD_CS=TRUE
ENV REPORT_COMPD_CS=TRUE
ENV OAMS_TRADITIONAL_GIS_ORDER=TRUE

SHELL ["conda", "run", "--no-capture-output", "-n", "pdal", "/bin/sh", "-c"]
