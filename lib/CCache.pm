package CCache;

#
# (C) 2016 Krystian Baniak
#
#
use strict;
use JSON;
use MIME::Base64;
use IO::File;
use Term::ReadKey;

sub new
{
  my $class = shift;
  my $self = {
    _dbase  => shift,
    _cfg    => {},
  };
  bless $self, $class;
  return $self;
}

sub open
{
  my ($self) = @_;

  open my $fh, "<", $self->{'_dbase'} or warn "--- Error opening database file: $self->{'_dbase'} !\n";
  if ($fh) {
    read $fh, my $buffer, -s $fh;
    close $fh;
    # process file
    $self->{'_cfg'} = decode_json( $buffer );
  }
}

sub getUserCredentials
{
  my $pwd = 'admin';
  ReadMode( "noecho");
  print "> enter f5 device password please : ";
  chomp ($pwd = <>);
  ReadMode("original") ;
  print "\n";
  return $pwd;
}

sub save
{
  my ($self) = @_;
  my $j = JSON->new;
  $j->pretty();
  $self->{'_cfg'}{'saved'} = localtime;

  CORE::open my $fh, ">", $self->{'_dbase'} or die "--- Error opening database file: $self->{'_dbase'} !\n";
  print $fh $j->encode( $self->{'_cfg'} );
  close $fh;

}

sub get
{
  my ($self, $key) = @_;
  my $rt = undef;
  if (defined $self->{'_cfg'}{$key}) {
    $rt = $self->{'_cfg'}{$key};
  }
  return $rt;
}


sub update
{
  my ($self, $key, $val) = @_;
  $self->{'_cfg'}{$key} = $val;
  $self->save();
}

sub setup_authcache
{
  my ($self, $r) = @_;
  foreach my $e ( sort keys %{ $r } ) {
    $self->{'_cfg'}{'auth'}{$e} = {};
  }
}

sub check_auth
{
  my ($self, $host) = @_;
  my @ret;
  $ret[0] = "x";
  $ret[1] = "x";
  if (defined $self->{'_cfg'}{'auth'}{$host}){
    $ret[0] = $self->{'_cfg'}{'auth'}{$host}{'user'};
    $ret[1] = MIME::Base64::decode( $self->{'_cfg'}{'auth'}{$host}{'token'} );
  }
  return @ret;
}

1;
