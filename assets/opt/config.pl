#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
binmode STDIN, ":utf8";
binmode STDOUT,":utf8";
binmode STDERR,":utf8";

my @dnsmasq;
my @tinyproxy;

foreach(fileRead('/opt/config')) {
	next if /^\s*#/;
	chomp;
	if (/^(.+?)(?:\s|\t)+(.+?)$/) {
		my $domain=$1;
		my $hostname=$2;
		my $ipaddr=`getent hosts $hostname | awk '{print \$1}'`; chomp $ipaddr;
		push @dnsmasq,"address=/$domain/$ipaddr";
		push @tinyproxy,"$domain";
	} elsif (/^(.+?)$/) {
		my $domain=$1;
		push @tinyproxy,"$domain";
	}
}
fileWrite('/etc/tinyproxy/filter',\@tinyproxy);
fileWrite('/etc/dnsmasq.d/domains.conf',\@dnsmasq);

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

