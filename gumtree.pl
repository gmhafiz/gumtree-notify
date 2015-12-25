#!/usr/bin/perl -w

# Hafiz Shafruddin Dec 2015
# gmhafiz@gmail.com 
# www.gmhafiz.com
# github.com/gmhafiz
#
# Search gumtree australia for specific keyword and send email 
# notification if found.

# use strict;
use DBI;

# Enter preferred email here
my $email = 'gmhafiz@gmail.com';

my $keyword = $ARGV[0];
my $base_url =  "http://www.gumtree.com.au";
my $url = "$base_url/s-$keyword/k0?fromSearchBox=true";
my $content = "";
my $message = "";
my $new_ad = "";
my $db_name = ".gumtree.db";
my $new_ad_found = 0;

my $dbh = DBI->connect(
	"dbi:SQLite:dbname=.gumtree.db",
	"",
	"",
	{ RaiseError =>1}
) or die $DBI::errstr;

if (-e "$db_name") {
	# Db file exists
} else {
	# $dbh->do("DROP TABLE IF EXISTS Items");
	$dbh->do("CREATE TABLE Items(Id INT PRIMARY KEY, Name TEXT, 
									Location TEXT, Url TEXT)");	
}

sub main {
	my $source_file = ".source.html";
	my $search_this = "itemprop=\"url\" ";

	open (MYFILE, ">$source_file");
	my $source_code = `wget -O- $url 2>/dev/null`;
	print MYFILE "$source_code";
	close(MYFILE);
	# TODO: concatenate multiple pages of search results

	open F, "$source_file";
	
	my $found = 0;
	my $num = 0;

	while (my $line = <F>) {
		if ($line =~ m/$search_this/ig) {
			$found = 1;
			my @array_0  = split (/\"/, $line);  # capture url
			my @array_1  = split (/\//, $line);  # capture loc, name, id
			my $item_url = $array_0[3];
			my $location = $array_1[2];
			my $name 	 = $array_1[4];
			my $id       = $array_1[5];
			$id          =~ s/\">//;
			$id			 =~ s/\" data-ref=\"searchTopAd//;
			$message .= "Name: $name\nLocation: $location\nId: $id" . 
						"url: $base_url" . "$item_url\n\n";
			$num += 1;
			
			my $sth = $dbh->prepare("SELECT Id FROM Items");
			$sth->execute();
			
			my $existed = 0;
			while(my $db_row = $sth->fetchrow_arrayref()) {
				if ($id == @$db_row[0]) {  # Id is index 0
					$existed = 1;
				}
			}
			
			if (!$existed) {
				$new_ad_found = 1;
				$dbh->do("INSERT INTO Items VALUES($id, '$name', 
									'$location', '$item_url')");
				$new_ad .= "Name: $name\nLocation: $location\nId: $id" . 
						"url: $base_url" . "$item_url\n\n";
			}
			# TODO: delete removed advertisement from database
		}
	}
	
	if (!$found) {
		print "Not found $keyword from $url, retry in 1 hour\n";
	} else {
		if ($num == 0) {
			print "No result found\n";
		} elsif ($num == 1) {
			print "$num result found\n";	
		} else {
			print "$num results found\n";
		}
		if ($new_ad_found) {
			print "$message\n" . "sending email...\n";
			send_email();
			print "..done\n";	
		} else {
			print "But not new results.\n";
		}
		
		print "Waiting for another hour for another query...\n";
	}
	sleep 3600;
	close F;
	
	main();
}

main();

sub send_email {
	my $subject = "New search result on gumtree found";
	$content .= "New ad: \n$new_ad\n\n";
	$content .= "Total: \n$message\n\n";
	# system("echo '$new_ad' '$content'|mutt -s '$name' -- $email")
	system("echo '$new_ad' |mutt -s '$subject' -- $email");
	
	# Clear all values
	$new_ad  = "";
	$message = "";
	$content = "";
	$new_ad_found = 0;
}
