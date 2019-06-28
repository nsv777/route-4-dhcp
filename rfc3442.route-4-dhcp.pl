#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use diagnostics;
use v5.10.0;

my ($net, $gw, $aggregate) = ("", "", "");
my $re_ip = "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)";

foreach (@ARGV) {
    unless ($net ne '') { $net = $_; next; }
    unless ($gw ne '') {
        $gw = $_;

        my ($network, $subnetmask) = split("/", $net);

        if (($subnetmask>=0 && $subnetmask<=32) && $network =~ /^$re_ip$/ && $gw =~/^$re_ip$/ ) {

            my (@destination) = split( /\./, $network );
            my $destination = "";

            my (@router) = split( /\./, $gw );
            my $router = "";

            my $networklen = to_hex($subnetmask);

            my $significantoctets = 0;
            $significantoctets = 1 if $subnetmask>=1 && $subnetmask<=8;
            $significantoctets = 2 if $subnetmask>=9 && $subnetmask<=16;
            $significantoctets = 3 if $subnetmask>=17 && $subnetmask<=24;
            $significantoctets = 4 if $subnetmask>=25 && $subnetmask<=32;

            if ($significantoctets>0) {
                foreach my $index (1..$significantoctets) {
                    $destination .= to_hex($destination[$index-1]);
                }
            } else {
                $destination .= "";
            }

            foreach my $r (@router) {
                $router .= to_hex($r);
            }

            $aggregate .= sprintf("%s%s%s", $networklen, $destination, $router);

            printf(
                "opt121_r_%s_via_%s : 0x%s%s%s\n",
                $net, $gw, $networklen, $destination, $router
            );
            printf(
                "opt249_r_%s_via_%s : 0x%s%s%s\n",
                $net, $gw, $networklen, $destination, $router
            );
            # printf(
            #     "/ip dhcp-server option add code=121 name=opt121_r_%s_via_%s value=0x%s%s%s\n",
            #     $net, $gw, $networklen, $destination, $router
            # );
            # printf(
            #     "/ip dhcp-server option add code=249 name=opt249_r_%s_via_%s value=0x%s%s%s\n",
            #     $net, $gw, $networklen, $destination, $router
            # )

        } else {
            print STDERR sprintf("Mask %d, network %s or gateway %s error\n");
        }

    }
    $net = "";
    $gw = "";
}

if ($aggregate ne '') {
    printf("aggregate_opt121 : 0x%s\n", $aggregate);
    printf("aggregate_opt249 : 0x%s\n", $aggregate);
    printf("/ip dhcp-server option add code=121 name=aggr_opt121 value=0x%s\n", $aggregate);
    printf("/ip dhcp-server option add code=249 name=aggr_opt249 value=0x%s\n", $aggregate);
    say("/ip dhcp-server option sets add name=set_121_249 options=aggr_opt121,aggr_opt249");
}


sub to_hex {
    my $n = shift;
    return "00" unless defined $n;
    $n = sprintf("%x", $n);
    ($n) = "0$n" =~ m/.*(..)$/;
    return $n;
}
