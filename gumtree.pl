#!/usr/bin/perl -w

# Hafiz Shafruddin Dec 2015
# gmhafiz@gmail.com 
# www.gmhafiz.com
#
# Search gumtree australia for specific keyword and send email 
# notification if found.

$keyword = $ARGV[0];
$url = "http://www.gumtree.com.au/s-$keyword/k0?fromSearchBox=true";
$email = 'gmhafiz@gmail.com';

sub main {

	my $source_file = ".source.html";
	my $search_this = "itemprop=\"name\"";

	open (MYFILE, ">$source_file");
	my $source_code = `wget -O- $url 2>/dev/null`;
	print MYFILE "$source_code";
	close(MYFILE);

	open F, "$source_file";
	
	$found = 0;

	while ($line = <F>) {
		# chomp $line;
		# $line =~ s/\n//g;
		
		if ($line =~ m/$search_this/ig) {
			print "Found $keyword. Sending email...\n";
			$found = 1;
			send_email();
			sleep 86400;  # wait 1 day
			main();
		}
	}
	
	if (!$found) {
		print "Not found $keyword from $url, retry in 1 hour\n";
		sleep 3600;
		close F;
		main();	
	}
	
	close F;
}

main();

sub send_email {
	my $message = "found $url";
	my $name = "New search result on gumtree found";
	system("echo $message|mutt -s $name -- $email")
}

