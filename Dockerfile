FROM mcr.microsoft.com/mssql/server:2022-latest
ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir /var/opt/mssql/ReplData

USER root
RUN /opt/mssql/bin/mssql-conf set hadr.hadrenabled 1
RUN /opt/mssql/bin/mssql-conf set sqlagent.enabled true
USER mssql

EXPOSE 1433

ENTRYPOINT /opt/mssql/bin/sqlservr