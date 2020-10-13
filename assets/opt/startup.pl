#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use YAML;
use Data::Dumper;

my $config=YAML::LoadFile('/config.yaml');

sub fWrite {
	my ($fn,$arrayref)=@_;
	say "[Write] $fn";
	open(my $fh,'>',$fn) || die "$fn - $!";
	foreach(@{$arrayref}) {
		print $fh "$_\n";
	}
}

sub fRead {
	my ($fn)=@_;
	open(my $fh,'<',$fn) || die "$fn - $!";
	local $|;
	say "[Read] $fn";
	return <$fh>;
}

sub do_system {
    my @args=@_;
    system(@args);
    if ($? == -1) {
        die "---- failed to execute: $!\n";
    } elsif ($? & 127) {
        die sprintf("---- child died with signal %d, %s coredump\n",($? & 127),($? & 128) ? 'with' : 'without');
    } else {
        my $ce=$? >> 8;
        if($ce != 0) {
            die sprintf("---- child exited with value %d\n", $ce) if $ce != 0;
        }
    }
}

sub self_signed_certs {

	if(-e '/opt/certs/server.key') {
		say 'server.key already exists.';
		return;
	}
	if(-e '/opt/certs/server.crt') {
		say 'server.crt already exists.';
		return;
	}

	my %dn=(
		C  => 'JP',
		ST => 'Kyoto',
		L  => 'Kyoto',
		O  => 'SnakeOli Ltd.',
		OU => 'IT Department',
		CN => 'localhost'
	);

	my @domains;
	foreach(@{$config->{domains}}) {
		if($_->{certs} && (lc($_->{certs}) eq 'true')) {
			push @domains,$_->{domain};
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

	my $id=1;
	foreach(@domains) {
		push @openssl,"DNS.$id = $_";
		$id++;
	}
	fWrite('/tmp/openssl.conf',\@openssl);
	fWrite('/tmp/dn.txt',["/C=$dn{C}/ST=$dn{ST}/L=$dn{L}/O=$dn{O}/OU=$dn{OU}/CN=$dn{CN}"]);

	open(my $fh,'| /bin/sh -xe') || die $!;
print $fh <<'EOS';
if [ ! -e '/opt/certs/dhparam.pem' ]; then
	curl https://2ton.com.au/getprimes/random/dhparam/4096 > /opt/certs/dhparam.pem
fi

openssl genrsa 4096 > /opt/certs/server.key
openssl req -new -x509 -sha256 -nodes -days 3650 \
	-subj "$(cat /tmp/dn.txt)" -config /tmp/openssl.conf \
	-key /opt/certs/server.key \
	-out /opt/certs/server.crt
EOS
}


sub generate_configs {
	my @dnsmasq=();
	my @tinyproxy=();

	foreach my $dom (@{$config->{domains}}) {
		if(!$dom->{addr}) {
			my @addr;
			foreach(split(/\n/,`getent ahosts $dom->{host}`)) {
				if(/^(.+?)\s|\t/) {
					push @addr,$1;
				}
			}
			$dom->{addr}=\@addr;
		}
		foreach(@{$dom->{addr}}) {
			push @dnsmasq,"address=/$dom->{domain}/$_";
		}
		push @tinyproxy,$dom->{domain}
	}
	fWrite('/etc/tinyproxy/filter', \@tinyproxy);
	fWrite('/etc/dnsmasq.d/domains.conf', \@dnsmasq);
}

sub tinyproxy {

	my $cfg=<<'EOS';
User tinyproxy
Group tinyproxy
Port 8888
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
LogFile "/var/log/tinyproxy/tinyproxy.log"
LogLevel Info
PidFile "/var/run/tinyproxy/tinyproxy.pid"
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
Allow 0.0.0.0/0
ViaProxyName "tinyproxy"
DisableViaHeader Yes

ConnectPort 443
ConnectPort 563
FilterURLs On
EOS

	if($config->{default_deny} && (lc($config->{default_deny}) eq 'true')) {
		$cfg.="FilterDefaultDeny Yes\n";
		$cfg.='Filter "/etc/tinyproxy/filter"\n';
	} else {
		$cfg.="FilterDefaultDeny No\n";
	}

	fWrite('/etc/tinyproxy/tinyproxy.conf',[$cfg]);

}

self_signed_certs();
generate_configs();
tinyproxy();

do_system('cp','/etc/resolv.conf','/etc/resolv.dnsmasq.conf');
do_system('sh','-c','echo "nameserver 127.0.0.1" > /etc/resolv.conf');

exec(@ARGV) if($#ARGV != -1);
exec('/usr/bin/supervisord','-c','/etc/supervisord.conf','-n');

