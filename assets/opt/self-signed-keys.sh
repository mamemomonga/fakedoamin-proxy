#!/bin/sh
set -eu

KEY_DIR="/tmp/self-signed-keys"

perl << 'END_OF_PERL'
#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use utf8;

binmode STDIN, ":utf8";
binmode STDOUT,":utf8";
binmode STDERR,":utf8";

my %dn=(
	C  => 'JP',
	ST => 'Kyoto',
	L  => 'Kyoto',
	O  => 'SnakeOli Ltd.',
	OU => 'IT Department',
	CN => 'localhost'
);

my @domains;

foreach(fileRead('/opt/config')) {
	next if /^\s*#/;
	chomp;
	if (/^(.+?)(?:\s|\t)+(.+?)$/) {
		my $domain=$1;
		push @domains,"$domain";
	}
}

my @openssl;
push @openssl,<<"EOS";
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
x509_extensions     = v3_req

[ req_distinguished_name ]
countryName                 = Country Name (2 letter code)
countryName_default         = $dn{C}
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = $dn{ST}
localityName                = Locality Name (eg, city)
localityName_default        = $dn{L}
organizationName            = Organization Name (eg, company)
organizationName_default    = $dn{OU}
commonName                  = Common Name (e.g. server FQDN or YOUR name)
commonName_max              = 64
commonName_default          = $dn{CN}

[ v3_req ]
subjectAltName = \@alt_names
keyUsage = digitalSignature, keyEncipherment

[ CA_default ]
copy_extensions = copy

[ alt_names ]
EOS
{
	my $counter=1;
	foreach(@domains) {
		push @openssl,"DNS.$counter = $_";
		$counter++;
	}
}

fileWrite('/tmp/openssl.conf',\@openssl);
fileWrite('/tmp/dn.txt',["/C=$dn{C}/ST=$dn{ST}/L=$dn{L}/O=$dn{O}/OU=$dn{OU}/CN=$dn{CN}"]);

sub fileWrite {
	my ($fn,$arrayref)=@_;
	open(my $fh,'>:utf8',$fn) || die "$fn - $!";
	foreach(@{$arrayref}) {
		print $fh "$_\n";
	}
}

sub fileRead {
	my ($fn)=@_;
	open(my $fh,'<:utf8',$fn) || die "$fn - $!";
	return <$fh>;
}
END_OF_PERL

mkdir -p $KEY_DIR
openssl dhparam -out $KEY_DIR/dhparam.pem 2048
openssl genrsa 4096 > $KEY_DIR/server.key
openssl req -new -x509 -sha256 -nodes -days 3650 \
	-subj "$(cat /tmp/dn.txt)" -config /tmp/openssl.conf \
	-key $KEY_DIR/server.key \
	-out $KEY_DIR/server.crt
tar c -C $KEY_DIR .
rm -rf $KEY_DIR

