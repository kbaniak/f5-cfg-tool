package CExiosLib;

BEGIN { push (@INC, "./lib"); }

use JSON;
use HTTP::Request::Common;
use HTTP::Request;
use LWP::UserAgent;

#
# get system properties
sub get_propsy {
  my %p;
  my $r = query2object( $URL . 'sys/hardware');
  $p{'marketingName'} = $r->{'entries'}{'https://localhost/mgmt/tm/sys/hardware/platform'}{'nestedStats'}{'entries'}{'https://localhost/mgmt/tm/sys/hardware/platform/0'}{'nestedStats'}{'entries'}{'marketingName'}{'description'};
  $p{'baseMac'} = $r->{'entries'}{'https://localhost/mgmt/tm/sys/hardware/platform'}{'nestedStats'}{'entries'}{'https://localhost/mgmt/tm/sys/hardware/platform/0'}{'nestedStats'}{'entries'}{'baseMac'}{'description'};
  $p{'bigipChassisSerialNum'} = $r->{'entries'}{'https://localhost/mgmt/tm/sys/hardware/system-info'}{'nestedStats'}{'entries'}{'https://localhost/mgmt/tm/sys/hardware/system-info/0'}{'nestedStats'}{'entries'}{'bigipChassisSerialNum'}{'description'};
  $p{'platform'} = $r->{'entries'}{'https://localhost/mgmt/tm/sys/hardware/system-info'}{'nestedStats'}{'entries'}{'https://localhost/mgmt/tm/sys/hardware/system-info/0'}{'nestedStats'}{'entries'}{'platform'}{'description'};
  $r = query2object( $URL . 'cm/device-group');
  foreach my $e ( @{ $r->{'items'} }) {
    if ($e->{'type'} eq 'sync-failover') {
      $p{'failover cluster'} = $e->{'name'};
    }
  }
  $r = query2object( $URL . 'cm/device' );
  $p{'fovState'} = 'passive';
  foreach my $e ( @{ $r->{'items'}} ) {
    if ($e->{'managementIp'} eq $host) {
      if ($e->{'failoverState'} eq 'active'){
        $p{'fovState'} = 'active';
      }
    }
  }
  return %p;
}
#
# query 2 perl object
sub query2object {
  my $uri = shift;
  my $mode = shift || 'no';
  return decode_json( query2json( $uri, $mode ) );
}
#
# query 2 JSON
sub query2json {
  my $uri = shift;
  my $mode = shift || 'no';
  if ($mode eq 'yes') {
    $uri =~ s/localhost/$host/;
  }
  if ($opts{'P'}){
    if ($uri =~ /^https:\/\/([^\/:]+)\/(.+)$/) {
      $uri = "https://$1:$opts{'P'}/$2";
      print ". modif --> $uri\n";
    }
  }
  my $r = GET $uri;
  if ($opts{'T'}){
    $r = GET $uri, 'X-F5-Auth-Token' => $ctx{token};
  } else {
    $r->authorization_basic($ctx{user}, $ctx{pass});
  }
  my $ua = $ctx{ua};
  my $res = $ua->request( $r );
  my $cd = $res->code;
  my $resp = $res->content;

  my $js = JSON->new;
  $js->pretty;

  if ($cd ne 200) {
    if (($cd eq 404) && ($resp =~ /was not found/)){
      return $js->encode( { error => 'not found' } );
    } else {
      printf $tee "--- http get req error, code: $cd\n";
      printf $tee "--- response: $resp\n";
      exit;
    }
  }
  return $js->encode( $js->decode($res->content) );
}

1;

