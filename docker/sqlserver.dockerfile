# docker build --progress=plain -t pepitedata/sqlserver:2019 -f sqlserver.dockerfile .
FROM mcr.microsoft.com/mssql/server:2019-latest

# Switch to root to install fulltext - apt-get won't work unless you switch users!
USER root

# Install dependencies - these are required to make changes to apt-get below
RUN dpkg --configure -a && \
    apt-get install -fy --no-install-recommends && \
    apt-get autoclean && \
    apt-get autoremove --purge -y && \
    apt-get update -y --fix-missing --no-install-recommends && \
    apt-get install -y --no-install-recommends --allow-downgrades gnupg gnupg2 gnupg1 curl apt-transport-https && \
    curl https://packages.microsoft.com/keys/microsoft.asc -o /var/opt/mssql/ms-key.cer && \
    apt-key add /var/opt/mssql/ms-key.cer && \
    curl https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list -o /etc/apt/sources.list.d/mssql-server-2019.list && \
    apt-get update -y && \
    apt-get install -y mssql-server-fts && \
    apt autoclean -y && \
    rm -rf /var/lib/apt/lists

# Run SQL Server process
ENTRYPOINT [ "/opt/mssql/bin/sqlservr", "--accept-eula" ]
