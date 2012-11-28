#!/usr/bin/perl -w

use strict;
use warnings;

use LWP::UserAgent;
use Getopt::Long;
use URI::Escape;
use Encode;
use DB_File;
use Data::Dumper;
use HTTP::Request;
use HTTP::Async;
use Storable qw(nstore retrieve);
use JSON;
use DBI;
use YAML::Syck;
binmode(STDOUT, ':encoding(utf8)');
my $PARALLEL = 1;
my $INTERVAL= 30*60;


my %headers = (
    "Host"              => "github.com",
    "User-Agent"        => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:8.0.1) Gecko/20100101 Firefox/8.0.1",
    "Accept"            => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Charset"   => "GBK,utf-8;q=0.7,*;q=0.3",
    "Accept-Encoding"   => "gzip, deflate,sdch",
    "Accept-Language"    => "zh-CN,zh;q=0.8",
    "Connection"        => "keep-alive",
);

my %cookie_map;

$SIG{INT}  = $SIG{HUP}  = $SIG{TERM} =
    sub {print STDOUT "gracefully exited\n";exit;};

my $async = HTTP::Async->new;
my $json = new JSON;
$json->allow_blessed([1]);
$json->convert_blessed([1]);
$json->utf8([1]);
my $cookie = '_gauges_unique_month=1; _gauges_unique_year=1; _gauges_unique=1; tracker=https%3A%2F%2Fgithub.com%2Fsearch%3Fq%3Dlocation%253Achina%26repo%3D%26p%3D1%26type%3DUsers%26l%3D; _gauges_unique_day=1; _gauges_unique_hour=1; _gh_sess=BAh7BzoQX2NzcmZfdG9rZW4iMXlLY0pVZTRvVTlPaXE0VXRGRi9laUNmLzZKd3lzL1VHY3FZWWRXeVJHWEU9Og9zZXNzaW9uX2lkIiUxYTNhZjA0MzA5NmYxZTA2YWNlODY2YjU0MjFhODdlZQ%3D%3D--5f6831b565b276968adeec8430802708a90baad6; __utma=1.2111847934.1352688945.1353318489.1353380512.5; __utmb=1.9.10.1353380512; __utmc=1; __utmz=1.1353159401.3.2.utmcsr=bing|utmccn=(organic)|utmcmd=organic|utmctr=github%20china%20users';

my $file="list";
open FILE, "<$file" or die "ERROR:can't open $file";
my $line_id = 0;
my @keywords;
while(<FILE>)
{
    chomp;
    $line_id += 1;
    my $w = $_;
    push @keywords,$w;
}

my $i = 0;
while($i <= scalar(@keywords))
{
    my @fields = split / (/,$keywords[$i];
    my $name = $fields[0];
	my $j = 1;
	my $pages = 2;
	while($j <= $pages) {
    if($async->total_count < $PARALLEL){
        my $link = "https://github.com/search?l=$name&p=$j&q=location%3Achina&repo=&type=Users";
       
        add_request($link,  $name);
        $j += 1;
        next;
    }
    if($async->total_count == 0){
        print STDOUT "idle.\n";
        sleep 3;
        next;
    }
    my ($resp,$id) = $async->wait_for_next_response();
    my $age_id = delete $cookie_map{$id};
    if($resp->code == 302 ){
        my $loc = $resp->header('Location');
        if ($loc =~ /^\/([\w\/]*)$/){
            add_request($i);
        }
        elsif ($loc =~ /login\.zhihu\.com/) {
            print STDOUT "Need login\n";
        }
        else{
            print STDOUT "ERROR on URL:",$resp->request->uri->as_string,
                ", redirected to ",$resp->header('Location'),"\n";
            sleep 1000;
            last;
        }
        next;
    }
    else {
        print "<input class=hujian id=$age_id>\n";
        print $resp->decoded_content."\n";
		my $content = $resp->decoded_content;
	    my $bpos = index($content,'<div class="title">Users (');
		my $epos = index($content,')</div>',$bpos);
		$pages = substr($content,$bpos+26,$epos-$bpos-26);

    }
}
$i += 1;
}



#--------------------------
sub add_request
{
    my $url = shift;
    my $offset = shift;
    die "ERROR: failed to retrieve weibo cookies\n" if (!defined($cookie));
    $url = "$url$offset";
    print STDERR "add request: $url\n";
    my $request = HTTP::Request->new(GET => $url);
   
    #[params => $params, method => "next", _xsrf => "9a5c037616c74ac6bff59b7848f1de1b"]);
    foreach my $key (keys %headers){
        $request->header($key => $headers{$key});
    }
    $request->header(Cookie => $cookie);
    my $id = $async->add_with_opts($request,{max_redirects => 2,timeout => 20});
    $cookie_map{$id} = $offset;
}

sub get_appengine_host
{
    #my $gapp_idx = int(rand(5))+1;
    #return "tb-fetch.appspot.com";
    return "localhost:8080";
}
