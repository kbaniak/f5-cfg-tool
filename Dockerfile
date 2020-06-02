FROM fedora:latest
MAINTAINER "Exios Consulting"
LABEL version="1.2.8"

RUN mkdir /home/rest
RUN mkdir /home/rest/migration

RUN dnf -y install mc bash perl git
RUN dnf -y install perl-Excel-Writer-XLSX perl-JSON perl-Switch perl-IO-Tee perl-SOAP-Lite perl-Getopt-Simple perl-Digest-SHA perl-TermReadKey perl-HTTP-Request-Params perl-Data-Dumper perl-Text-Diff perl-MIME-Base64
RUN dnf -y clean packages

RUN echo 'export PATH=$PATH:/home/rest/f5-cfg-tool/' >> /root/.bashrc

WORKDIR /home/rest
RUN git clone https://github.com/kbaniak/f5-cfg-tool
WORKDIR /home/rest/migration

CMD [ "bash" ]
