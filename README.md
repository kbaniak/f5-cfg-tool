# f5-cfg-tool
RESTful provisioning and automation tool for F5 Networks BIG-IP product.

Uses iControl SOAP and iControlREST API on F5 devices to facilitate operations and support of F5 devices:
- manage and audit configuration elements (with full support for administrative partitions),
- automate configuration tasks using a batch mode. This tool accepts json formatted batch files that specify actions to perform on a remote F5 system(s),
- run reports that collect information from selected configuration entities and present it in a tabular form,
- REST API troubleshooting and debug.
- **new** manage ZoneRunner dns zones from command line and in a batch mode.
- **new** returns json encoded responses (options: -Q -J) to allow integration with automation pipelines

The primary application of this tool is to automate frequently used maintenance tasks, perform config audits and ensure maitenence window time is kept to minimum by eliminating human error factor.

Supported features and software versions:
- F5 software versions >= 11.x
- iRule auditing and diff of the iRule code changes
- iRule static variable checking and auditing
- DB variable verification
- rundimentary Declarative onboarding support
- dmping portions of configuration in json format and verifiaction of changes using diff mode 
- adding, removing and merging configuration elements
- iRule/iFile/data group uploading/dumping
- UCS/SCF backup and automated config management
- batch mode accepting json formatted batch steps language, supporting multi target batches (like cluster provisioning)
- reports providing info on iRules, virtuals and allocation of iRules to virtuals, ...
- saving and synchronizing configuration
- inline comand line batch mode
- uploading files on F5 device, executing scripts and downloading files from F5 system
- merging configuration sets using tmsh merge functionality
- managing ILX workspaces (since version 1.4.0) and plugins

Developped in perl script language, may be used as standalone script or in a docker/podman container - see instalation notes below.

## Usage

Just run `f5-cfg -h` to see all available options.

One of the basic needs is to fast recon on the F5 device and provide summary of what we are dealing with. We may use `-i -k` options together with other mandatory switches:
- `-f` : asks for password
- `-u admin` : specify user account to connect with
- `-t IP_address` : target is the management interface's IP address of the F5 device 

The result of this command is the report of iRules their digests as well as allocations of iRules to virtual servers.

```
f5-cfg -t 10.10.10.10 -u admin -f -i -k
. runtime location: /Images/Shared/f5-rest-tools, rundir: /home/krystian

(C) 2020, Krystian Baniak <krystian.baniak@exios.pl>,  F5 restful configuration tool, version: 1.4.9
> enter f5 device password please : 
+ host 172.16.24.29 mapped to: [ 172.16.24.29 ]
system properties: 
                                   baseMac: 00:0c:29:68:14:96
                     bigipChassisSerialNum: 564dd107-0f67-11be-804044681496
                                  fovState: active
                             marketingName: BIG-IP Virtual Edition
                                  platform: Z100
                             active volume: HD1.1
                                soft build: 0.0.9
                              soft version: 15.1.2
+ analysing iRules and their alloactions ...

                                       name |            partition | hash                                    
----------------------------------------------------------------------------------------------------------------------------------------------------------------
                          test_sip_sreening |               Common | b72fa4e5723e3b4cbe4dac1215d44edea2161e54
----------------------------------------------------------------------------------------------------------------------------------------------------------------

                                       name |    partition |              application service | list of numbered iRules                 
----------------------------------------------------------------------------------------------------------------------------------------------------------------
                              VS_DNS_UDP_GN |       Common |                                - |                                         
                                VS_SIP_TEST |       Common |                                - | [ 1]  /Common/test_sip_sreening               
----------------------------------------------------------------------------------------------------------------------------------------------------------------

+ unused iRules:
----------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------
```

## Installation
First, clone the repository on your computer. Afterwards, follow the procedure:

```{bash}
git clone https://github.com/kbaniak/f5-cfg-tool
cd f5-cfg-tool
./f5-cfg -h
```

## Docker/podman installation and use
Compile a podman image

```
podman build --format=docker -t f5-cfg .
```

Run a container:

```
podman run --rm -it f5-cfg bash
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

### Notes for Fedora (32) podman selinux 

When one wants to bind a local folder to a migration directory of the container/pod we have to relabel the source directory.

Let's assume we have ./test directory.
```
[krystian:0:~]$ mkdir test
[krystian:0:~]$ chcon -Rt svirt_sandbox_file_t test/
[krystian:0:~]$ podman run -it --rm --mount type=bind,src=./test,dst=/home/rest/migration f5-cfg bash
[root@8ed070ca7b2d migration]# touch aa
[root@8ed070ca7b2d migration]# exit
[krystian:0:~]$ tree test/
test/
└── aa

0 directories, 1 file
```

## Examples and use cases

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
   -f           : password will be read from the stdin after a prompt
   -t host      : f5 mgmt interface's IP address to query
   -A           : create archive containing iRules and iCall scripts
   -l name      : label used to create archive file name (affects -A option)
   -i           : identify f5 box
   -k           : verify iRule versions and allocation to virtual servers
   -K           : verify listeners and their allocation to virtual servers
   -M seconds   : timeout for iCR and iCR REST queries
   -c name      : create iRule or other resource from a file given in -I option
   -C name      : update iRule or other resource from a file given in -I option
   -D name      : dump given iRule to a working directory
   -I           : input resource
   -J           : modifies batch mode to return silently json response
   -P           : port to connect to
   -r           : retain temporal objects (used with -A option)
   -s           : save config
   -S           : sync cluster
   -w           : working directory
   -l name      : affect -a and -A by unifying the name of the resource
   -b name      : batch mode that uses json file as input
   -B steps     : semicolon delimited list of steps, mutually exclusive with -b option
   -Z step      : select step set from a step set list, used only with a -b option
   -x cmd       : execute advanced script action
   -R name      : run special report name [ availability depends on version ]
   -T           : use token based authentication
   -Q           : quiet mode - supress logs to a file
   -O opts      : list of options param=value,param=value, use %20 to escape a white space
                  example: base=gen8.2/test,label=ala%20ma%20kota
   -v string    : batch mode variables (see opts for syntax)

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
   save_query_result   : save iCR query results in a cache
   scf_secret          : passphrase used to encrypt scf archive for MAKE_SCF batch command
   supress_log         : supress log audit to a file
   ucs_secret          : passphrase used to encrypt ucs archive for MAKE_UCS batch command

 list of known batch commands
   ABORT               : abort at a given step
   ADD_ZONE_A:zone:view:name:ip:ttl: add ZoneRunner A resource record
   COMMAND             : execute shell comamnd: [ Array(command) ]
   COMPARE_DBSET       : compare db vars on target system with definitions <dbvars> from a batch file
   COMPARE_RSETS       : compare irule sets (partitions) with local files
   COMPARE_RULES       : compare rules on target system with rules from a configured set
   CONFIRM             : confirm next step with a question: [ Array(confirm-msg) ]
   CSET:name           : command set reference, name indicated named command set to be invoked
   DELAY:seconds       : wait seconds before continuing
   DELETIONS           : delete objects from the f5: [ Hash(delete) of [type,priority] ]
   DEL_ZONE_A:zone:view:name:ip:ttl: delete ZoneRunner A resource record
   DOWNLOAD            : download file from remote system
   DSET:name           : download list of files from a downloadset dictionary from a batch file, keyed by a name
   GET_ZONES           : list ZoneRunner zones
   GET_ZONE_INFO:view  : get ZoneRunner zone information
   GET_ZONE_RRS:zone:view: get ZoneRunner resource records information
   LOADTMSH            : load config file and merge it: [ Array(tmsh-merge) ]
   LOAD_DEFAULT        : load sys config default
   LOAD_DG             : load data groups type external: [ Hash(datagroup) of { source } ]
   LOAD_IFILES         : load iFiles: [ Hash(ifile) of { source } ]
   LOAD_ILX            : load ILX worskpaces
   LOAD_ILX_PLUGINS    : load ILX plugins
   LOAD_MONITORS       : load external [ Hash(monitors) of { source } ]
   LOAD_RULES          : load iRules from baseline directory: [ Hash(rules) of { priority } ]
   MAKE_SCF            : create single configuration file backup (inlcuding a tar file)
   MAKE_UCS            : create and download ucs archive
   MCPD_FORCELOAD      : marks mcpd forceload flag for the next reboot
   MSET:name           : merge set reference, name indicates named mereg set to be invoked
   REBIND_VS           : attach iRule to virtual servers: [ Hash(virtuals) of { site, rules } or [] ]
   REBOOT              : reboots current host (all blades)
   RECERT              : create iRule certificates
   RENAME              : rename configuration objects: [ Hash(rename) ]
   RESET_HOST          : reset host to original batch defined name or ip address
   RESTART             : runs clsh bigstart restart on current host
   RSET:name           : merge specific iRule set defined in ruleset setion of a batch file
   SAVE                : save configuration on a F5 unit
   SYNC                : synchronize a F5 cluster
   UNBIND_VS           : unbind iRules from virtual servers: [ Hash(unbindvs) ]
   UPLOAD              : upload resources on the box: [ Array(upload) ]
   UPSET:name          : upload set of files denoted by a name
   USE_HOST            : switch target to a host name or ip address
   VERIFY              : verify that all operations are going to be successful
   VERIFY_SET:name     : run verification procedure on a verifyset. Verify set must inlude a list of objects
 	                       that specify tpe and set of items to check
   WAIT_FOR:event      : waits for event to happen: cluster node become event = { online, standby, active }
   ZRSET:name          : process records from a named zonerunner list

 list of batch options to be used in options section in json definition:
   base_location       : indicates directory where to look for resource files
   irule_diff          : true/false - use diff to show discrepancies in irules for the COMPARE_RULES command
   remove_created_scf  : remove scf after download
   remove_created_ucs  : remove ucs after download
   rules_location      : location of iRules for given batch
   scf-secret          : passphrase used to encrypt scf archive for MAKE_SCF batch command
   scf-via-rest        : use iContolREST for scf creation (use on faster systems)
   search_path         : array containing search relative subdirectories to look for resources used in a batch 
   signing_key         : irule signing key
   store_location      : used by a download command
   ucs-file-name       : name of the ucs file to save
   ucs-secret          : passphrase used to encrypt ucs archive for MAKE_UCS batch command
   verify_merge_sets   : verify merge sets before commiting changes
   working-directory   : working directory, ie: to save files. if ./ is used then it is relative to a run directory

```

## Perl instalation dependencies
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
