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

## Docker/podman installation and use
Compile podman image
```
podman build --format=docker -t f5-cfg .
```
Run a container, ensuring that a local directory is bound for persistent storage
```
podman run --rm -it -v local_directory:/home/rest/migration f5-cfg bash
```
When inside a container (using bash shell) one may invoke a f5-cfg tool, like on these example that is used to create UCS archive on an F5:
```
podman run -it --rm f5-cfg bash
[root@d045ed96d5dd migration]# f5-cfg -t 10.128.1.47 -B MAKE_UCS -Oucs_secret=test123
. runtime location: /home/rest/f5-cfg-tool, rundir: /home/rest/migration

(C) 2020, Krystian Baniak <krystian.baniak@exios.pl>,  F5 restful configuration tool, version: 1.2.8
-- creating new empty cache file.
+ host 10.128.1.47 mapped to: [ 10.128.1.47 ]
+ final batch workdir: /home/rest/migration/
+ final batch basedir: /home/rest/migration/
+ final batch ruledir: /home/rest/migration/
+-- [step: MAKE_UCS] make system archive
  . creating encrypted ucs archive
  . ucs saved into: migrate-auto-10.128.1.47-020620-171800
++ downloading resource: migrate-auto-10.128.1.47-020620-171800.ucs 
++ total bytes transferred: 7538951
```
Now the file will be stored in the local directory:
```
[root@e5728b9f8c42 migration]# ls
migrate-auto-10.128.1.47-020620-171800.ucs
[root@e5728b9f8c42 migration]# 
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

## Directories

The f5-cfg uses the following rules to interpret directories and dependent files/resources location:

* standard invocation mode
  - working-directory: this is a standard working directory for f5-cfg, a place where all downloads will be stored
    working direcory may be given as `-w option` or otherwise it will be automatically set to a running directory

* batch mode
  In a batch mode we control directories using options sesion in JSON file describing batch actions. 
  All options may be relative to a current running directory. In such a case they shall be prefixed with `./`.
  Those options include:
  - working-directory {mandatory} - this is a working directory for downloads
  - base_location {mandatory} - this is a location to search for uploaded resources
  - rules_location {mandatory} - this is a location containing iRules for a batch
  - search_path {optional} - this is a list of directories relative to base_location, where resources will be searched for

## Batch files

Batch files are used to specify automated tasks to be executed during F5 configuration or maintenance.
The batch file is json formatted.

```
{
  "system":      "*",
  "system-ip":   "*",
  "sw-version":  "*",
  "description": "description",
  "version":     "1",
  "author":      "Jon Doe",
  "steps" :   [ "SAVE" ],
  "stepset": {
    "check":  [ "COMPARE_RULES", "VERIFY_SET:mop_optimize" ],
    "rules":  [ "LOAD_RULES" ],
    "dbvars": [ "COMPARE_DBSET" ],
    "gomop":  [ "RSET:mop_optimize", "MSET:mop_optimize", "SAVE", "SYNC" ]
  },
  "rules": [
    "rule1": { "priority": 1 },
    "rule2": {},
    "rule3": {}
  ],
  "ruleset": {
    "mop_optimize": [
      "rule1": { "priority": 1 },
      "rule2": {}
    ]
  },
  "mergeset": {
    "mop_optimize": [ "/shared/tmp/file_tmsh_1.txt" ]
  },
  "dbvars": {
    "tm.tcpsegmentationoffload": "disable",
    "connection.syncookies.threshold": "100000000",
    "pvasyncookies.virtual.maxsyncache": "4093",
    "tm.maxrejectrate": "1000",
    "tmm.sessiondb.table_cmd_timeout_override": "true",
    "tm.tcpprogressive.autobuffertuning": "disable",
    "tm.minipfragsize": "556",
    "kernel.pti": "disable",
    "statemirror.clustermirroring": "between"
  },
  "options": {
    "rules_location":    "./iRules",
    "working-directory": "./",
    "base_location":     "./FE/",
    "search_path":       [ ],
    "irule_diff":        true
  }
}
```

Batch file contains sections that govern how it is processed:

- header, that specifies what system we touch and restrictions (regex) to which IP address and ltm software version we may apply this batch
- steps, default step for a batch file
- stepsets, a list of step sets that are selected using -Z option for f5-cfg
- number of sections with definitions of actions or resources. Examples:
  - mergeset: named list of files to tmsh merge
  - ruleset: named list of iRules to load
  - rules: list of irules to load or verify their existcence with a diff command
  - dbvars: list of db variables to verify
- options: list of settings and batch options. For instance specifying location of resources or search folders 

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
   RSET:name           : merge specific iRule set defined in ruleset setion of a batch file
   SAVE                : save configuration on a F5 unit
   SYNC                : synchronize a F5 cluster
   UNBIND_VS           : unbind iRules from virtual servers: [ Hash(unbindvs) ]
   UPLOAD              : upload resources on the box: [ Array(upload) ]
   UPSET:name          : upload set of files denoted by a name
   VERIFY              : verify that all operations are going to be successful
   VERIFY_SET:name     : run verification procedure on a verifyset. Verify set must inlude a list of objects
                  			 that specify tpe and set of items to check

 list of batch options to be used in options section in json definition:
   base_location       : indicates directory where to llok for resource files
   irule_diff          : true/false - use diff to show discrepancies in irules for the COMPARE_RULES command
   remove_created_ucs  : remove ucs or scf after download
   rules_location      : location of iRules for given batch
   search_path         : array containing search relative subdirectories to look for resources used in a batch 
   signing_key         : irule signing key
   store_location      : used by a download command
   ucs-file-name       : name of the ucs file to save
   verify_merge_sets   : verify merge sets before commiting changes
   working-directory   : working directory, ie: to save files. if ./ is used then it is relative to a run directory


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
