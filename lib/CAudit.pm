package CAudit;

#
# (C) 2020 Krystian Baniak
# krystian.baniak@exios.pl
# Resource library for F5 iControl SOAP functions
#

use Switch;
use Data::Dumper;
#use SOAP::Lite +trace => 'all';
use SOAP::Lite;
use MIME::Base64;

BEGIN { push (@INC, "./lib"); }
use iControlTypeCast;

sub parseZoneBatch
{
  my ( $object ) = @_;
  my $verdict = {
    result => 1,
    errstr => ''
  };

  return $verdict;
}

#
# CAudit class 
sub new
{
  my $class = shift;
  my $self = {
    _host  => shift,
    _user  => shift,
    _pass  => shift,
    _port  => shift,
  };
  bless $self, $class;
  return $self;
}

#
# create soap handle for given iControl scope
# by default it is a SystemInfo scope
sub createHandle
{
  my ($self, $scope) = @_;
  my $icrScope = $scope || 'System/SystemInfo';
  my $icHandle = SOAP::Lite
    -> uri('urn:iControl:' . $icrScope)
    -> readable(1)
    -> proxy("https://$self->{'_host'}:$self->{'_port'}/iControl/iControlPortal.cgi");

  $icHandle->transport->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0x00 );
  $icHandle->transport->http_request->header(
    'Authorization' => 'Basic ' . MIME::Base64::encode("$self->{'_user'}:$self->{'_pass'}", '')
  );
  return $icHandle;
}

#
# verify soapResponse
sub verifySoapResponse
{
	my ($self, $soapResponse) = @_;
	if ( $soapResponse->fault )
	{
		return "soap call failed with: " . $soapResponse->faultcode . ", " . $soapResponse->faultstring;
  } else {
    return $soapResponse->result ? $soapResponse->result : 'done';
  }
}

#
# get BIG-IP version
sub getVersion
{
  my ($self) = @_;
  my $icHandle = $self->createHandle();
  my $soapResponse = $icHandle->get_version();
  
  return $soapResponse->result;
}

#
# Get DNS ZoneRunner zones for given view
sub getZones
{
  my ($self, $view) = @_;
  my $icHandle = $self->createHandle('Management/Zone');
  my $soapResponse = $icHandle->get_zone_name
  (
    SOAP::Data->name( 'view_names' => [ $view ] )
  );
  return $self->verifySoapResponse( $soapResponse );
}

#
# Get DNS Zone information
sub getZoneInfo
{
  my ($self, $view, $zone) = @_;
  my $icHandle = $self->createHandle('Management/Zone');
  my $soapResponse = $icHandle->get_zone_v2
  (
    SOAP::Data->name( 'view_zones' => [ { 'zone_name' => $zone, 'view_name' => $view }] )
  );
  return $self->verifySoapResponse( $soapResponse );
}

#
# install new resource record for given zone and view
sub processZoneRecord
{
  my ($self, $action, $view, $zone, $rtype, $object) = @_;
  my $icHandle = $self->createHandle('Management/ResourceRecord');
  my @records = @{ $object };
  my $soapResponse;

  unless ( grep( /^$action$/, ( 'create', 'delete' ) ) ) {
    return "unsupported action";
  }
  
  unless ( grep( /^$rtype$/, ( 'A', 'AAAA', 'CNAME', 'NAPTR', 'SRV', 'MX' ) ) ) {
    return "unsupported resource record type";
  }

  foreach my $rs (@records) {
    unless (exists $rs->{'ttl'}) {
      $rs->{'ttl'} = 0;
    }
    if ($rtype eq 'NAPTR' and $rs->{'regexp'} eq '') {
      $rs->{'regexp'} = '""'; 
    }
  }
  
  my $rt = lc ($rtype);
  my $method =  $action eq 'create' ? 'add' : 'delete';
  $method .= '_' . $rt;
  
  my @args = (
    SOAP::Data->name( 'view_zones' => [ { 'zone_name' => $zone, 'view_name' => $view } ] ),
    SOAP::Data->name( "${rt}_records"  => [ \@records ] ),
  );

  if ($rt eq 'a' || $rt eq 'aaaa') {
    push @args, SOAP::Data->name( 'sync_ptrs' => [ 0 ])
  }
  
  $soapResponse = $icHandle->$method(@args);
  return $self->verifySoapResponse( $soapResponse );
}

#
# Get Zone resource records
sub getZoneRecords
{
  my ($self, $view, $zone) = @_;
  my $icHandle = $self->createHandle('Management/ResourceRecord');
  my $soapResponse = $icHandle->get_rrs
  (
    SOAP::Data->name( 'view_zones' => [ { 'zone_name' => $zone, 'view_name' => $view }] )
  );
  return $self->verifySoapResponse( $soapResponse );
}

#
# create an ucs archive
sub createUcs
{
  my ($self, $name, $passw) = @_;
  my $icHandle = $self->createHandle('System/ConfigSync');
  my $soapResponse;
  
  if ($passw and $passw ne "") {
    $soapResponse = $icHandle->save_encrypted_configuration
    (
      SOAP::Data->name( 'filename' => $name ),
      SOAP::Data->name( 'save_flag' => 'SAVE_FULL' ),
      SOAP::Data->name( 'passphrase' => $passw )
    );
  } else {
    $soapResponse = $icHandle->save_configuration
    (
      SOAP::Data->name( 'filename'  => $name ),
      SOAP::Data->name( 'save_flag' => 'SAVE_FULL' )
    );
  }
  
  return $self->verifySoapResponse( $soapResponse );
}

#
# create scf archive
sub createScf
{
  my ($self, $name, $passw) = @_;
  my $icHandle = $self->createHandle('System/ConfigSync');
  my $soapResponse = $icHandle->save_single_configuration_file
  (
    SOAP::Data->name( 'filename' => $name ),
    SOAP::Data->name( 'save_flag' => 'SAVE_FULL' ),
    SOAP::Data->name( 'passphrase' => $passw ),
    SOAP::Data->name( 'tarfile' => '' )
  );
  return $self->verifySoapResponse( $soapResponse );
}

#
# delete file from a remote system
sub deleteResource
{
  my ($self, $name, $type) = @_;
  my $icHandle = $self->createHandle('System/ConfigSync');
  my $soapResponse; 

  print "++ removing resource: $name\n";
  
  if ($type eq 'ucs') {
    $soapResponse = $icHandle->delete_configuration ( SOAP::Data->name( 'filename'  => $name ) );
  } elsif ($type eq 'scf') {
    $soapResponse = $icHandle->delete_single_configuration_file ( SOAP::Data->name( 'filename'  => $name ) );
  } else {
    $soapResponse = $icHandle->delete_file ( SOAP::Data->name( 'filename'  => $name ) );
  }

  if ( $soap_response->fault ) {
    print "-- error: " . $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
    return 0;
  }

  return $self->verifySoapResponse( $soapResponse );
}

#
# download a file from a remote system
sub downloadResource
{
  my ($self, $opts, $type, $configName, $fname) = (@_);
  my $icHandle = $self->createHandle('System/ConfigSync');
  my $soapResponse;
  
  my $localFile = $fname;
  if (defined($opts)) {
    if (defined($opts->{"base_location"})) {
      if (substr($fname,0,2) eq './') {
        $localFile = $opts->{"base_location"} . $fname;
      }
    }
  }

  open (FH, ">$localFile") or die("Can't open $localFile for output: $!");
  binmode(FH);

  my $file_offset = 0;
  my $chunk_size  = 65536/2;
  my $chain_type  = "FILE_UNDEFINED";
  my $bContinue   = 1;

  print "++ downloading resource: $configName \n";

  while ( $bContinue ) {

    if ($type eq "ucs") {
      $soap_response = $icHandle->download_configuration
      (
        SOAP::Data->name( config_name   => $configName  ),
        SOAP::Data->name( chunk_size  => $chunk_size  ),
        SOAP::Data->name( file_offset => $file_offset )
      );
    }

    if ($type eq "file") {
      $soap_response = $icHandle->download_file
      (
        SOAP::Data->name( file_name   => $configName  ),
        SOAP::Data->name( chunk_size  => $chunk_size  ),
        SOAP::Data->name( file_offset => $file_offset )
      );
    }

    if ( $soap_response->fault ) {
      print "-- error: " . $soap_response->faultcode . " " . $soap_response->faultstring . "\n";
      return 0;
    } else {
      my $FileTransferContext = $soap_response->result;
      my $data  = $FileTransferContext->{"file_data"};
      my $chain_type = $FileTransferContext->{"chain_type"};
      my @params = $soap_response->paramsout;
      $file_offset = $params[0];

      # Append Data to File
      print FH $data;

      if ( ("FILE_LAST" eq $chain_type) or ("FILE_FIRST_AND_LAST" eq $chain_type) ) {
        $bContinue = 0;
      }
    }
  }
  print "++ total bytes transferred: $file_offset\n";
  close(FH);
  return 1;
}

#
# upload a file to a remote system
sub uploadFile
{
  my ($self, $opts, $fname, $fileName) = (@_);
  my $icHandle = $self->createHandle('System/ConfigSync');
  my $soapResponse;

  my $bContinue  = 1;
  my $chain_type = "FILE_FIRST";
  my $chunk_size = 1e3 * 1024;
  my $total_bytes = 0;

  my $localFile = $fname;
  if (defined($opts)) {
    if (defined($opts->{"base_location"})) {
      $localFile = $opts->{"base_location"} . $fname;
      if (! -e $localFile) {
        if (defined($opts->{"search_path"})) {
          #
          # TODO: cycle through search locations, so far only first item from the list
          foreach my $subpath (@{ $opts->{'search_path'} }) {
            $localFile = $opts->{"base_location"} . $subpath . "/" . $fname;
            if (-e $localFile) {
              last;
            }
          }
        }
      }
    }
  }
  
  open(FH, "< $localFile") or die("Can't open $localFile for input: $!");
  binmode(FH);

  while ($bContinue) {
    $file_data = "";
    $bytes_read = read(FH, $file_data, $chunk_size);

    if ( $chunk_size != $bytes_read ) {
      if ( $total_bytes == 0 ) {
        $chain_type = "FILE_FIRST_AND_LAST";
      } else {
        $chain_type = "FILE_LAST";
      }
      $bContinue = 0;
    }
    $total_bytes += $bytes_read;

    $FileTransferContext = {
      file_data => SOAP::Data->type(base64 => $file_data),
      chain_type => $chain_type
    };

    $soap_response = $icHandle->upload_file(
      SOAP::Data->name(file_name => $fileName),
      SOAP::Data->name(file_context => $FileTransferContext)
    );

    if ( $soap_response->fault ) {
      print "-- error: " . $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
      return 0;
    }
    $chain_type = "FILE_MIDDLE";
  }
  print "++ uploaded $total_bytes bytes\n";
  close(FH);
  return 1;
}

1;

