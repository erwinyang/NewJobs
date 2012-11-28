#!/home/y/bin/perl
use Data::Dumper;
use HTML::Parser ();

$p = HTML::Parser->new( api_version => 3,
                        start_h => [\&start, "tagname, attr"],
                        text_h => [\&text, "dtext"],
                        marked_sections => 1,
                      );

my $find_name = 0;
my $find_num = 0;
$p->parse_file($ARGV[0]);


sub start
{
        my ($tagname, $attr) = @_;
        if($tagname eq "h2" and $attr->{class} eq "title") {
           $find_name = 1;
        }
        elsif($tagname eq "a" and $find_name == 1) {
			print "\n".$attr->{href};
			$find_name = 0;
        }
        elsif($tagname eq "span" and $attr->{class} eq "aka") {
			$find_num = 1;
		}
        elsif($tagname eq "span" and $attr->{class} eq "email") {
			$find_num = 1;
		}
}

sub text
{
        my $dtext = shift;
        if ($find_num eq 1) {
          $dtext =~ s/\s+//g;
            $dtext =~ s/\n//;
          if(length($dtext) > 0) {
            print STDOUT "\t$dtext";
           }
           $find_num = 0;
        }

=pod           
        if ($find_num eq 1) {                                                            
          $dtext =~ s/\s+//g;                                                             
            $dtext =~ s/\n//;                                                             
          if(length($dtext) > 0) {                                                        
            print "$dtext\t";                                                            
           }                                                                              
           $find_num = 0;                                                                
        }

        if($dtext =~ m/组　号/) {
          print "ok\t";
          $find_num = 1;
        }
=cut
        #if($dtext =~ m/粉丝/){
        #  print "$dtext\n";
        #}
}
