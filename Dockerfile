FROM fedora-minimal:latest
MAINTAINER "Exios Consulting"
LABEL version="1.5.1"

RUN microdnf -y --nodocs install bash perl git && \
    microdnf -y --nodocs install perl-Excel-Writer-XLSX perl-JSON perl-Switch perl-IO-Tee perl-SOAP-Lite perl-Getopt-Simple perl-Digest-SHA perl-TermReadKey perl-HTTP-Request-Params perl-Data-Dumper perl-Text-Diff perl-MIME-Base64 && \
    microdnf clean all && \
    rpm -e --nodeps gcc gcc-c++ 

RUN echo 'export PATH=$PATH:/home/rest/f5-cfg-tool/' >> /root/.bashrc && \
    mkdir /home/rest && \
    mkdir /home/rest/migration

WORKDIR /home/rest
RUN git clone https://github.com/kbaniak/f5-cfg-tool
WORKDIR /home/rest/migration

CMD [ "bash" ]

