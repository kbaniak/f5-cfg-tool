# f5-cfg-tool
F5 RESTful provisioning tool

Developped in perl script language.

## Installation
First, clone the repository on your computer. Afterwards, follow the procedure:
```
git clone https://github.com/kbaniak/f5-cfg-tool
cd f5-cfg-tool
./f5-cfg -h
```

## Examples
### Inspect F5 device manifest and print list of iRules
```
./f5-cfg -t 1.1.1.1 -u admin -p admin -i -k
```
### Provision F5 device using procedure specified in a batch file
```
./f5-cfg -t 1.1.1.1 -u admin -p admin -b /path/batch_file.json
```

### Provision F5 device using procedure specified in a batch file, based on specific step set labeled rules
```
./f5-cfg -t 1.1.1.1 -u admin -p admin -b /path/batch_file.json -Z rules
```

## Perl Dependencies
This tool requires the following modules to be installed on your platform:
```
Switch
JSON
Data::Dumper
HTTP::Request
HTTP::Request::Common
Getopt::Std
LWP::UserAgent
Digest::SHA
IO::Tee
Text::Diff
SOAP::Lite
MIME::Base64
```

Fedora Linux system users may use dnf to install the dependencies:
```
dnf install perl-JSON perl-Switch perl-IO-Tee perl-SOAP-Lite perl-Getopt-Simple perl-Digest-SHA perl-TermReadKey perl-HTTP-Request-Params perl-Data-Dumper perl-Text-Diff perl-MIME-Base64
```
