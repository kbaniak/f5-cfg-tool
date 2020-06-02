package CAudit;

#
# (C) 2016 Krystian Baniak
#
#

use SOAP::Lite;
use MIME::Base64;

BEGIN { push (@INC, "./lib"); }
use iControlTypeCast;

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

sub getVersion
{
  my ($self) = @_;

  my $icHandle = SOAP::Lite
    -> uri('urn:iControl:System/SystemInfo')
    -> readable(1)
    -> proxy("https://$self->{'_host'}:$self->{'_port'}/iControl/iControlPortal.cgi");

  $icHandle->transport->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0x00 );
  $icHandle->transport->http_request->header(
    'Authorization' => 'Basic ' . MIME::Base64::encode("$self->{'_user'}:$self->{'_pass'}", '')
  );

  my $soapResponse = $icHandle->get_version();
  return $soapResponse->result;
}

sub createUcs
{
  my ($self, $name, $passw) = @_;

  my $icHandle = SOAP::Lite
    -> uri('urn:iControl:System/ConfigSync')
    -> readable(1)
    -> proxy("https://$self->{'_host'}:$self->{'_port'}/iControl/iControlPortal.cgi");

  $icHandle->transport->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0x00 );
  $icHandle->transport->http_request->header(
    'Authorization' => 'Basic ' . MIME::Base64::encode("$self->{'_user'}:$self->{'_pass'}", '')
  );

  if ($passw and $passw ne "") {
    my $soapResponse = $icHandle->save_encrypted_configuration
    (
      SOAP::Data->name( 'filename'  => $name ),
      SOAP::Data->name( 'passphrase' => $passw )
    );
    return $soapResponse->result;
  } else {
    my $soapResponse = $icHandle->save_configuration
    (
      SOAP::Data->name( 'filename'  => $name ),
      SOAP::Data->name( 'save_flag' => 'SAVE_FULL' )
    );
    return $soapResponse->result;
  }
}

sub deleteResource
{
  my ($self, $name, $type) = @_;

  my $icHandle = SOAP::Lite
    -> uri('urn:iControl:System/ConfigSync')
    -> readable(1)
    -> proxy("https://$self->{'_host'}:$self->{'_port'}/iControl/iControlPortal.cgi");

  $icHandle->transport->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0x00 );
  $icHandle->transport->http_request->header(
    'Authorization' => 'Basic ' . MIME::Base64::encode("$self->{'_user'}:$self->{'_pass'}", '')
  );

  my $soapResponse; 
  
  if ($type eq 'ucs') {
    $soapResponse = $icHandle->delete_configuration ( SOAP::Data->name( 'filename'  => $name ) );
  } else {
    $soapResponse = $icHandle->delete_file ( SOAP::Data->name( 'filename'  => $name ) );
  }

  return $soapResponse->result;

}

sub downloadResource
{
  my ($self, $type, $configName, $localFile) = (@_);

  my $icHandle = SOAP::Lite
    -> uri('urn:iControl:System/ConfigSync')
    -> readable(1)
    -> proxy("https://$self->{'_host'}:$self->{'_port'}/iControl/iControlPortal.cgi");

  $icHandle->transport->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0x00 );
  $icHandle->transport->http_request->header(
    'Authorization' => 'Basic ' . MIME::Base64::encode("$self->{'_user'}:$self->{'_pass'}", '')
  );

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

sub uploadFile
{
  my ($self, $opts, $fname, $fileName) = (@_);

  my $bContinue  = 1;
  my $chain_type = "FILE_FIRST";
  my $preferred_chunk_size = 65536/2;
  my $chunk_size = 65536/2;
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
  print "+ final local resource path is: $localFile\n";

  my $icHandle = SOAP::Lite
    -> uri('urn:iControl:System/ConfigSync')
    -> readable(1)
    -> proxy("https://$self->{'_host'}:$self->{'_port'}/iControl/iControlPortal.cgi");

  $icHandle->transport->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0x00 );
  $icHandle->transport->http_request->header(
    'Authorization' => 'Basic ' . MIME::Base64::encode("$self->{'_user'}:$self->{'_pass'}", '')
  );

  open(FH, "< $localFile") or die("Can't open $localFile for input: $!");
  binmode(FH);

  while ($bContinue) {
    $file_data = "";
    $bytes_read = read(FH, $file_data, $chunk_size);

    if ( $preferred_chunk_size != $bytes_read ) {
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

