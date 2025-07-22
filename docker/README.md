
# apply rate limiting to disk IO of a container
docker run --rm -it --device-write-iops /dev/sda:50 --device-write-bps /dev/sda:10mb --name io_rate_limit ubuntu:xenial bash

docker run -d --restart=always --name prometheus \
    --network=host \
    -v /home/jlu/src/mylinux/system/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus --web.listen-address=0.0.0.0:8080

docker run -d --name jpp-postgres -p 5432:5432 -v /home/data/postgresql16:/var/lib/postgresql/data -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD="secret" -e PGDATA=/var/lib/postgresql/data/pgdata -e POSTGRES_HOST_AUTH_METHOD="--auth-host=scram-sha-256 --auth-local=scram-sha-256" postgres:16.9 -c max_connections=100 -c shared_buffers=8GB -c effective_cache_size=24GB -c maintenance_work_mem=2GB -c checkpoint_completion_target=0.9 -c wal_buffers=16MB -c default_statistics_target=100 -c random_page_cost=1.1 -c effective_io_concurrency=200 -c work_mem=104857kB -c min_wal_size=1GB -c max_wal_size=4GB -c max_worker_processes=20 -c max_parallel_workers_per_gather=4 -c max_parallel_workers=20 -c max_parallel_maintenance_workers=4
