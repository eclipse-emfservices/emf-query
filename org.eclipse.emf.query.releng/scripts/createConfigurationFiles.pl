use warnings;
use strict;

package BUILDCFG;

$BUILDCFG::ECLIPSE_BUILD_ROOT_URL="http://download.eclipse.org/downloads/drops";
$BUILDCFG::EMF_BUILD_ROOT_URL="http://download.eclipse.org/tools/emf/downloads/drops/2.0";

# Creates the configuration file based on a template.  The tokens @eclipseURL@, 
# @eclipseFile@, @eclipseBuildURL@, @eclipseOS@ and @eclipseWS@ in the template 
# are replaced by the appropriate values.
# param: The file to be created
# param: The template file
# param: The platform
sub createConfigurationFile()
{
	my $file = shift;
	my $fileTemplate = shift;
	my $eclipseURL = shift;
	my $emfURL = shift;

	return unless (open(TEMPLATE, "<$fileTemplate"));
	my $template = join("", <TEMPLATE>);
	close(TEMPLATE);


	my $emfFile = $emfURL;
	$emfFile =~ s/^.*\///;
	
	my $emfbuildId = $emfURL;
	$emfbuildId =~ s/\/${emfFile}$//;
	$emfbuildId =~ s/^.*\///;	
	my $emfBuildURL = "$BUILDCFG::EMF_BUILD_ROOT_URL/$emfbuildId";
#	$emfURL = "$emfBuildURL/$emfFile";


	my $eclipseFile = $eclipseURL;
	$eclipseFile =~ s/^.*\///;
	
	my $eclipsebuildId = $eclipseURL;
	$eclipsebuildId =~ s/\/${eclipseFile}$//;
	$eclipsebuildId =~ s/^.*\///;	
	my $eclipseBuildURL = "$BUILDCFG::ECLIPSE_BUILD_ROOT_URL/$eclipsebuildId";
	$eclipseURL = "$eclipseBuildURL/$eclipseFile";

	my $eclipseOS = "win32";
	my $eclipseWS = "win32";
	my @nameFragments = split("-", $eclipseFile);
	if(@nameFragments."" >  1)
	{
		$nameFragments[@nameFragments.""-1] =~ s/\.(zip|tar\.gz)$//;
		$eclipseOS = $nameFragments[@nameFragments.""-2];
		$eclipseWS = $nameFragments[@nameFragments.""-1];
	}

	$template =~ s/\@eclipseWS\@/$eclipseWS/g;
	$template =~ s/\@eclipseOS\@/$eclipseOS/g;
	
	$template =~ s/\@eclipseFile\@/$eclipseFile/g;
	$template =~ s/\@eclipseURL\@/$eclipseURL/g;
	$template =~ s/\@eclipseBuildURL\@/$eclipseBuildURL/g;
	
	$template =~ s/\@emfFile\@/$emfFile/g;
	$template =~ s/\@emfURL\@/$emfURL/g;
	$template =~ s/\@emfBuildURL\@/$emfBuildURL/g;

	return unless (open(FILE, ">$file"));
	print FILE $template;
	close(FILE);
}

sub main()
{
	if(@ARGV."" != 4)
	{
		die("Usage: perl createConfigurationFile.pl <configuration file> <configuration file template> <eclipse URL> <EMF URL>\n");
	}

	my $file = $ARGV[0];
	my $fileTemplate = $ARGV[1];
	my $eclipseURL = $ARGV[2];
	my $emfURL = $ARGV[3];

	die("Invalid template file.\n") unless (-f $fileTemplate);
	
	&createConfigurationFile($file, $fileTemplate, $eclipseURL, $emfURL);
}

main();
