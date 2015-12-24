#!/usr/bin/perl -w

# Hafiz Shafruddin Dec 2015
# gmhafiz@gmail.com 
# www.gmhafiz.com
#
# Search gumtree australia for specific keyword and send email 
# notification if found.

$keyword = $ARGV[0];
$base_url =  "http://www.gumtree.com.au";
$url = "$base_url/s-$keyword/k0?fromSearchBox=true";
$email = 'gmhafiz@gmail.com';

sub main {
	my $source_file = ".source.html";
	my $search_this = "itemprop=\"url\" ";

	open (MYFILE, ">$source_file");
	my $source_code = `wget -O- $url 2>/dev/null`;
	print MYFILE "$source_code";
	close(MYFILE);

	open F, "$source_file";
	
	$found = 0;
	$num = 1;

	while ($line = <F>) {
		# chomp $line;
		# $line =~ s/\n//g;
			
		if ($line =~ m/$search_this/ig) {
			$found = 1;
			# href="/s-ad/windsor/laptops/asus-zenbook-ux305/1098449750">
			@array_0  = split (/\"/, $line);  # capture url
			@array_1  = split (/\//, $line);  # capture loc, name, id
			$item_url = $array_0[3];
			$location = $array_1[2];
			$name 	  = $array_1[4];
			$id       = $array_1[5];
			$id       =~ s/\">//;
			# print "line: $line\n";
			# print "$num\n"; 
			# print "Name: $name\nLocation: $location\nId: $id";
			# print "url: $base_url" . "$item_url\n";
			$message .= "Name: $name\nLocation: $location\nId: $id" . "url: $base_url" . "$item_url\n\n";
			$num += 1;
			# send_email();
		}
	}
	
	if (!$found) {
		print "Not found $keyword from $url, retry in 1 hour\n";
		sleep 3600;
		close F;
		main();	
	} else {
		$num -= 1;
		print "$num result(s) found\n\n";
		print "$message\n";
		sleep 86400;  # wait 1 day
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
