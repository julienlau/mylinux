#!/usr/bin/perl

# Example of usage :
# tshark -r merge.pcap -x -2 -R "(http.request.uri or http.response.code) and (ip.src == 127.0.0.1 or ip.dst == 127.0.0.1)" >  http-dump.hex
# cat http-dump.hex | sharkParsePayloadHex.pl | tr -cd '\11\12\15\40-\176' > http-dump.txt

while ($line=<STDIN>) {

    chomp($line);
    @parts1=split("  ", $line);
    @parts2=split(" ", $parts1[1]);
    foreach $hvalue (@parts2) {
        if ($hvalue=~/^[0-9A-Za-z]{2}$/) {
            # print chr(hex $hvalue);
            $str = hex $hvalue;
            $str =~ s/[:print:]//g;
            print chr($str);
        }
    }
}
