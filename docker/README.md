docker run -d --name prometheus \
    --network=host \
    -v /home/jlu/src/mylinux/system/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus