
# apply rate limiting to disk IO of a container
docker run --rm -it --device-write-iops /dev/sda:50 --device-write-bps /dev/sda:10mb --name io_rate_limit ubuntu:xenial bash

docker run -d --name prometheus \
    --network=host \
    -v /home/jlu/src/mylinux/system/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
