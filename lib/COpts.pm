package COpts;

#
# (C) 2016 Krystian Baniak
#
#
use strict;
use URI::Escape;

my $ODEFS = {
 "onelog"           => { usage => "use single log to append log messages to" },
 "supress_log"      => { usage => "supress log audit to a file" },
 "bigiq"            => { usage => "use BIG-IQ/iWorkflow mode" },
 "format"           => { usage => "(json) use format for a -q option to modify a query result output" },
 "base"             => { usage => "the directory holding iRules to compare with" },
 "diff"             => { usage => "(true|false) - use diff mode in comparing iRules against a release base" },
 "ctype"            => {
                         usage => "(rule|ifile|dgroup|monitor) - specify type of a resource for -c, -C options",
                         regex => '^(rule|ifile|dgroup|monitor)$'
                       },
 "report_mode"      => { usage => "modify report output to batch friendly" },
 "report_name"      => { usage => "modify report output by addinf parameter to a report function" },
 "mrf_sip"          => { usage => "dump mrf sip configuration to excel file" },
 "respOnly"         => { usage => "when executing command -x, print only the command result" },
 "save_query_result"=> { usage => "save iCR query results in a cache" },
 "ucs_secret"       => { usage => "passphrase used to encrypt ucs archive for MAKE_UCS batch command" },
 "scf_secret"       => { usage => "passphrase used to encrypt scf archive for MAKE_SCF batch command" }
};

my $BDEFS = {
  "MAKE_UCS"       => { usage => "create and download ucs archive" },
  "MAKE_SCF"       => { usage => "create single configuration file backup (inlcuding a tar file)" },
  "LOAD_RULES"     => { usage => "load iRules from baseline directory: [ Hash(rules) of { priority } ]" },
  "UNBIND_VS"      => { usage => "unbind iRules from virtual servers: [ Hash(unbindvs) ]" },
  "REBIND_VS"      => { usage => "attach iRule to virtual servers: [ Hash(virtuals) of { site, rules } or [] ]" },
  "DELETIONS"      => { usage => "delete objects from the f5: [ Hash(delete) of [type,priority] ]" },
  "RECERT"         => { usage => "create iRule certificates" },
  "RENAME"         => { usage => "rename configuration objects: [ Hash(rename) ]" },
  "ABORT"          => { usage => "abort at a given step" },
  "VERIFY"         => { usage => "verify that all operations are going to be successful" },
  "CONFIRM"        => { usage => "confirm next step with a question: [ Array(confirm-msg) ]" },
  "SAVE"           => { usage => "save configuration on a F5 unit" },
  "SYNC"           => { usage => "synchronize a F5 cluster" },
  "LOADTMSH"       => { usage => "load config file and merge it: [ Array(tmsh-merge) ]" },
  "UPLOAD"         => { usage => "upload resources on the box: [ Array(upload) ]" },
  "COMMAND"        => { usage => "execute shell comamnd: [ Array(command) ]" },
  "LOAD_IFILES"    => { usage => "load iFiles: [ Hash(ifile) of { source } ]" },
  "LOAD_MONITORS"  => { usage => "load external [ Hash(monitors) of { source } ]" },
  "LOAD_DG"        => { usage => "load data groups type external: [ Hash(datagroup) of { source } ]" },
  "LOAD_DEFAULT"   => { usage => "load sys config default" },
  "DOWNLOAD"       => { usage => "download file from remote system" },
  "CSET:name"      => { usage => "command set reference, name indicated named command set to be invoked" },
  "MSET:name"      => { usage => "merge set reference, name indicates named mereg set to be invoked" },
  "RSET:name"      => { usage => "merge specific iRule set defined in ruleset setion of a batch file" },
  "DELAY:seconds"  => { usage => "wait seconds before continuing" },
  "UPSET:name"     => { usage => "upload set of files denoted by a name" },
  "COMPARE_DBSET"  => { usage => "compare db vars on target system with definitions <dbvars> from a batch file" },
  "COMPARE_RULES"  => { usage => "compare rules on target system with rules from a configured set" },
  "VERIFY_SET:name" => { usage => "run verification procedure on a verifyset. Verify set must inlude a list of objects\n\t\t\tthat specify tpe and set of items to check" },
  "USE_HOST"       => { usage => "switch target to a host name or ip address" },
  "RESET_HOST"     => { usage => "reset host to original batch defined name or ip address" },
  "COMPARE_RSETS"  => { usage => "compare irule sets (partitions) with local files" },
  "LOAD_ILX"       => { usage => "load ILX worskpaces" },
  "LOAD_ILX_PLUGINS" => { usage => "load ILX plugins" },
  "REBOOT"         => { usage => "reboots current host (all blades)" },
  "RESTART"        => { usage => "runs clsh bigstart restart on current host" },
  "WAIT_FOR:event" => { usage => "waits for event to happen: cluster node become event = { online, standby, active }" },
  "MCPD_FORCELOAD" => { usage => "marks mcpd forceload flag for the next reboot" },
};

my $BOPTS = {
  "working-directory"   => "working directory, ie: to save files. if ./ is used then it is relative to a run directory",
  "ucs-file-name"       => "name of the ucs file to save",
  "base_location"       => "indicates directory where to look for resource files",
  "rules_location"      => "location of iRules for given batch",
  "verify_merge_sets"   => "verify merge sets before commiting changes",
  "remove_created_ucs"  => "remove ucs after download",
  "remove_created_scf"  => "remove scf after download",
  "signing_key"         => "irule signing key",
  "store_location"      => "used by a download command",
  "search_path"         => "array containing search relative subdirectories to look for resources used in a batch ",
  "irule_diff"          => "true/false - use diff to show discrepancies in irules for the COMPARE_RULES command",
  "ucs-secret"          => "passphrase used to encrypt ucs archive for MAKE_UCS batch command",
  "scf-secret"          => "passphrase used to encrypt scf archive for MAKE_SCF batch command",
  "scf-via-rest"        => "use iContolREST for scf creation (use on faster systems)"
};

sub new
{
  my $class = shift;
  my $self = {
    _options  => {},
    _debug => shift || 0,
    _error => 0
  };
  bless $self, $class;
  return $self;
}

# parse command line
sub parse
{
  my ($self, $opts) = @_;

  foreach my $k ( split( ',', uri_unescape($opts)) )
  {
    my ($p,$v) = split '=', $k;
    if ($self->{'_debug'}) {
      printf("COpts::parse: option: $p --> $v \n");
    }
    if (defined $ODEFS->{$p}) {
      if (defined $ODEFS->{ $p }{regex}){
        if ($v =~ /$ODEFS->{ $p }{'regex'}/) {
          $self->{'_options'}{$p} = $v;
        } else {
          printf("COpts: unsupported option's value for: $p\n");
          $self->{'error'} = 1;
        }
      } else {
        $self->{'_options'}{$p} = $v;
      }
    } else {
      printf("COpts: unsupported option: $p \n");
      $self->{'error'} = 1;
    }
  }

  return $self;
}

#getter
sub get
{
  my ($self,$key) = @_;
  return (defined $self->{'_options'}{$key}) ? $self->{'_options'}{$key} : '';
}

sub batch_describe
{
  my ($self) = @_;
  my $r = "";
  foreach my $i ( sort keys %{ $BDEFS } ) {
    $r .= sprintf("   %-20s: %s\n", $i, $BDEFS->{$i}{'usage'});
  }
  $r .= sprintf("\n list of batch options to be used in options section in json definition:\n");
  foreach my $i ( sort keys %{ $BOPTS } ) {
    $r .= sprintf("   %-20s: %s\n", $i, $BOPTS->{$i});
  }
  return $r;
}

sub describe
{
  my ($self) = @_;
  my $r = "";
  foreach my $i ( sort keys %{ $ODEFS } ) {
    $r .= sprintf("   %-20s: %s\n", $i, $ODEFS->{$i}{'usage'});
  }
  return $r;
}

sub isFailed
{
  my ($self) = @_;
  return $self->{'error'};
}

1;

