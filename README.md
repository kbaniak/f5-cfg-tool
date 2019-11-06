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

## Usage Details
```
options:
 --------------------------------------------------------------------------------------------

   -h           : this help message
   -d           : debug mode
   -q query     : single query mode, will not produce output file
   -u user      : user, default is admin
   -p password  : password, default is admin
   -t host      : f5 mgmt interface's IP address to query
   -o file      : output file name, default is test.xlsx
   -a           : create full system config archive
   -A           : create only archives, skip generating xlsx file
   -i           : identify f5 box
   -k           : verify iRule version and allocation
   -K           : verify listeners and their allocation
   -c name      : create iRule or other resource from a file given in -I option
   -C name      : update iRule or other resource from a file given in -I option
   -I           : input resource
   -P           : port to connect to
   -r           : retain temporal objects (used with -a and -A)
   -s           : save config
   -S           : sync cluster
   -w           : working directory
   -l name      : affect -a and -A by unifying the name of the resource
   -b name      : batch mode that uses json file as input
   -Z step      : select step set from a step set list

   -x cmd       : execute advanced script action
   -R name      : run special report name [ availability depends on version ]
   -T           : use token based authn
   -Q           : quiet mode - supress logs to a file
   -O opts      : list of options param=value,param=value, use %20 to escape a white space
                  example:  base=gen8.2/test,label=ala%20ma%20kota

 --------------------------------------------------------------------------------------------

 list of known options:
   base                : the directory holding iRules to compare with
   bigiq               : use BIG-IQ/iWorkflow mode
   ctype               : (rule|ifile|dgroup|monitor) - specify type of a resource for -c, -C options
   diff                : (true|false) - use diff mode in comparing iRules against a release base
   format              : (json) use format for a -q option to modify a query result output
   mrf_sip             : dump mrf sip configuration to excel file
   onelog              : use single log to append log messages to
   report_mode         : modify report output to batch friendly
   report_name         : modify report output by addinf parameter to a report function
   respOnly            : when executing command -x, print only the command result
   supress_log         : supress log audit to a file


 list of known batch commands
   ABORT               : abort at a given step
   COMMAND             : execute shell comamnd: [ Array(command) ]
   COMPARE_DBSET       : compare db vars on target system with definitions <dbvars> from a batch file
   COMPARE_RULES       : compare rules on target system with rules from a configured set
   CONFIRM             : confirm next step with a question: [ Array(confirm-msg) ]
   CSET:name           : command set reference, name indicated named command set to be invoked
   DELAY:seconds       : wait seconds before continuing
   DELETIONS           : delete objects from the f5: [ Hash(delete) of [type,priority] ]
   DOWNLOAD            : download file from remote system
   LOADTMSH            : load config file and merge it: [ Array(tmsh-merge) ]
   LOAD_DG             : load data groups type external: [ Hash(datagroup) of { source } ]
   LOAD_IFILES         : load iFiles: [ Hash(ifile) of { source } ]
   LOAD_MONITORS       : load external [ Hash(monitors) of { source } ]
   LOAD_RULES          : load iRules from baseline directory: [ Hash(rules) of { priority } ]
   MAKE_SCF            : create single configuration file backup (inlcuding a tar file)
   MAKE_UCS            : create and download ucs archive
   MSET:name           : merge set reference, name indicates named mereg set to be invoked
   REBIND_VS           : attach iRule to virtual servers: [ Hash(virtuals) of { site, rules } or [] ]
   RECERT              : create iRule certificates
   RENAME              : rename configuration objects: [ Hash(rename) ]
   SAVE                : save configuration on a F5 unit
   SYNC                : synchronize a F5 cluster
   UNBIND_VS           : unbind iRules from virtual servers: [ Hash(unbindvs) ]
   UPLOAD              : upload resources on the box: [ Array(upload) ]
   UPSET:name          : upload set of files denoted by a name
   VERIFY              : verify that all operations are going to be successful

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
