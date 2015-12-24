#!/usr/bin/perl -w

# Hafiz Shafruddin Dec 2015
# gmhafiz@gmail.com 
# www.gmhafiz.com
#
# Search gumtree australia for specific keyword and send email 
# notification if found.

use strict;
use DBI;

my $keyword = $ARGV[0];
my $base_url =  "http://www.gumtree.com.au";
my $url = "$base_url/s-$keyword/k0?fromSearchBox=true";
my $email = 'gmhafiz@gmail.com';
my $message = "";

my $dbh = DBI->connect(
	"dbi:SQLite:dbname=gumtree.db",
	"",
	"",
	{ RaiseError =>1}
) or die $DBI::errstr;

if (!-e "gumtree.db") {
	$dbh->do("DROP TABLE IF EXISTS Items");
	$dbh->do("CREATE TABLE Items(Id INT PRIMARY KEY, Name TEXT, Location TEXT, Url TEXT)");	
}

sub main {
	my $source_file = ".source.html";
	my $search_this = "itemprop=\"url\" ";

	open (MYFILE, ">$source_file");
	my $source_code = `wget -O- $url 2>/dev/null`;
	print MYFILE "$source_code";
	close(MYFILE);

	open F, "$source_file";
	
	my $found = 0;
	my $num = 1;

	while (my $line = <F>) {
		# chomp $line;
		# $line =~ s/\n//g;
			
		if ($line =~ m/$search_this/ig) {
			$found = 1;
			my @array_0  = split (/\"/, $line);  # capture url
			my @array_1  = split (/\//, $line);  # capture loc, name, id
			my $item_url = $array_0[3];
			my $location = $array_1[2];
			my $name 	 = $array_1[4];
			my $id       = $array_1[5];
			$id          =~ s/\">//;
			# print "line: $line\n";
			# print "$num\n"; 
			# print "Name: $name\nLocation: $location\nId: $id";
			# print "url: $base_url" . "$item_url\n";
			$message .= "Name: $name\nLocation: $location\nId: $id" . 
						"url: $base_url" . "$item_url\n\n";
			$num += 1;
			# send_email();
			
			# TODO: Query db and skip insert if $id is already present.
			$dbh->do("INSERT INTO Items VALUES($id, '$name', '$location', '$item_url')");
			
		}
	}
	
	if (!$found) {
		print "Not found $keyword from $url, retry in 1 hour\n";
	} else {
		$num -= 1;
		print "$num result(s) found\n\n";
		print "$message\n";
		send_email();
	}
	sleep 3600;
	close F;
	$dbh->disconnect;
	main();
}

main();

sub send_email {
	my $name = "New search result on gumtree found";
	system("echo '$message'|mutt -s '$name' -- $email")
}
