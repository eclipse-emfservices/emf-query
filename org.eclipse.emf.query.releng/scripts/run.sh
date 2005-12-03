#!/bin/sh
# $Id: run.sh,v 1.3 2005/12/03 10:16:19 nickb Exp $

# Runs the build.
#
# IMPORTANT: This script is supposed to be run from the "scripts" directory of a
#            checked out version of "org.eclipse.emft.$project.releng"
if [ $# -lt 16 ]; then
	echo "usage: run.sh"
	echo "-branch           <CVS branch of the files to be built>"
	echo "-proj             <REQUIRED: shortname of the project to be build, eg. ocl, validation, query>"
	echo "-projBranch       <CVS branch of the files to be built (eg., build_200409171617 instead of HEAD)>"
	echo "-projRelengBranch <CVS branch of org.eclipse.emft.$project.releng>"
	echo "-URL              <The URLs of the Eclipse driver, EMF driver, and any other zips that need to be unpacked into"
	echo "                   the eclipse install to resolve all dependencies. Enter one -URL [...] per required URL."
	echo "                   If not using explicit -eclipseURL and -emfURL flags, script will attempt to guess values.>"
	echo "-eclipseURL       <The URL of the Eclipse driver to be used during the build.  The name of the file "
	echo "                   defines the OS and the WS>"
	echo "-emfURL           <The URL of the EMF driver to be used during the build.>"
	echo "-oclURL           <The URL of the OCL driver to be used during the build.>"
	echo "-antTarget        <The Ant target of the build script - controls the packages that will be built"
	echo "-buildType        <The type of the build>"
	echo "-javaHome         <The JAVA_HOME directory>"
	echo "-buildDir         <The build driectory>"
	echo "-downloadsDir     <The directory where the Eclipse drivers (and other downloads) are located>"
	echo "-repoInfoFile     <The build configuration file>"
	echo "-buildTimestamp   <Optional: the build timestamp>"
	echo "-buildAlias       <Optional: the build alias - Ex. 2.0.0, to be used in the zip names>"
	echo "-tagBuild         <Optional: defines if the files are tagged - Values: true|false  - Default: true>"
	echo "example: run.sh -branch HEAD -eclipseURL http://download.eclipse.org/downloads/drops/S-3.0M5-200311211210/eclipse-SDK-3.0M5-win32.zip -repoInfoFile ../buildConfig.properties -emfURL http://download.eclipse.org/tools/emf/downloads/drops/2.0/I200404080727/emf-xsd-sdo-SDK-I200404080727.zip -javaHome /opt/java -target run -buildID 2.1.2 -buildType I -buildsDir ~/builds -eclipseDir ~/eclipseDrivers"
	echo " "
	echo "Note: to run tests only (no build) use -antTarget runTestsOnly"
	exit 1
fi

# Default value for the build timestamp
buildTimestamp=`date +%Y%m%d\%H%M`
buildID=$buildTimestamp

buildDir=$PWD/$buildType$buildTimestamp
tagBuild='true'

dependURL=""; # loaded from -URL

proj=""; # REQUIRED

echo "";
echo "[`date +%Y%m%d\ %k\:%M\:%S`] run.sh executing with the following options:"
# Create local variable based on the input
while [ "$#" -gt 0 ]; do
	echo "    $1 $2";
	case $1 in
		'-proj')
			proj=$2;
			shift 1
			;;
		'-branch')
			branch=$2;
			shift 1
			;;
		'-projBranch')
			projBranch=$2;
			shift 1
			;;
		'-projRelengBranch')
			projRelengBranch=$2;
			shift 1
			;;
		'-URL')
			if [ "x$dependURL" != "x" ]; then
			  dependURL="$dependURL "
			fi
			dependURL=$dependURL"$2";
			shift 1
			;;
		'-eclipseURL')
			eclipseURL=$2;
			shift 1
			;;
		'-emfURL')
			emfURL=$2;
			shift 1
			;;
		'-oclURL')
			oclURL=$2;
			shift 1
			;;
		'-javaHome')
			javaHome=$2;
			shift 1
			;;
		'-antTarget')
			antTarget=$2;
			shift 1
			;;
		'-buildType')
			buildType=$2;
			shift 1
			;;
		'-buildDir')
			buildDir=$2;
			shift 1
			;;
		'-downloadsDir')
			downloadsDir=$2;
			shift 1
			;;
		'-buildTimestamp')
			buildTimestamp=$2;
			shift 1
			;;
		'-buildAlias')
			buildAlias=$2;
			shift 1
			;;
		'-tagBuild')
			tagBuild=$2;
			shift 1
			;;
		'-repoInfoFile')
			repoInfoFile=$2;
			shift 1
			;;
	esac
	shift 1
done

if [ -z $repoInfoFile ]; then
	echo "repoInfoFile required"
	exit 1;
fi

guessURL() # find a substring in a URL to determine if that URL is for a given project
{
	guessedURL="";
	match=$1; shift 1;
	while [ "$#" -gt 0 ]; do
	  url=$1; shift 1;
	  #echo -n "Look for $match in $url ... "
	  left=${url##*$match*}
	  if [ "x$left" = "x" ]; then # found substring, so resulting string is null
	    guessedURL=$url
	    #echo -n "found!"
	  fi
	  #echo ""
	done
}

if [ "x$eclipseURL" = "x" ]; then
	guessedURL="";guessURL "eclipse-SDK" $dependURL;eclipseURL="$guessedURL";
    #echo "Using eclipseURL = $eclipseURL"
fi

if [ "x$emfURL" = "x" ]; then
    guessedURL="";guessURL "emf-*-SDK" $dependURL;emfURL="$guessedURL";
	#echo "Using emfURL = $emfURL"
fi

if [ "x$oclURL" = "x" ]; then
    guessedURL="";guessURL "emft-ocl-SDK" $dependURL;oclURL="$guessedURL";
	#echo "Using oclURL = $oclURL"
fi

if [ "x$eclipseURL" = "x" ]; then
	echo "Error: no -eclipseURL specified! Script will now exit."
	exit 99;
elif [ "x$emfURL" = "x" ]; then
	echo "Error: no -emfURL specified! Script will now exit."
	exit 99;
elif [ "x$oclURL" = "x" ]; then
	echo "Error: no -oclURL specified! Script will now exit."
	exit 99;
fi 

# Getting Eclipse file name (should include the OS and WS information)
eclipseFile=`echo $eclipseURL | sed -e 's/^.*\///'`
emfFile=`echo $emfURL | sed -e 's/^.*\///'`

# org.eclipse.emft.$proj.releng directory
relengBuilderDir=`pwd | sed -e 's/\(.*\)\/.*/\1/'`

# org.eclipse.releng.basebuilder directory
relengBaseBuilderDir=`echo $relengBuilderDir | sed -e 's/\(.*\)\/.*/\1/'`
relengBaseBuilderDir=$relengBaseBuilderDir/org.eclipse.releng.basebuilder

echo "relengBuilderDir: $relengBuilderDir"
echo "relengBaseBuilderDir: $relengBaseBuilderDir"

# Getting the build tag
buildTag=build_$buildTimestamp
try=`echo $buildDir | sed 's/eclipse$//'`
if [ $buildDir == `echo $buildDir | sed 's/eclipse$//'` ]; then
	buildDir="$buildDir/eclipse"
fi

if [ $tagBuild == 'false' ]; then
	buildTag=$branch
fi

echo "buildID: $buildID"
echo "buildTag: $buildTag"
echo "buildDir: $buildDir"

$relengBuilderDir/scripts/executeCommand.sh "mkdir -p $buildDir"
$relengBuilderDir/scripts/executeCommand.sh "mkdir -p $downloadsDir"

# Creates the mapping files and adjusting CVS
command="$relengBuilderDir/scripts/adjustCVS.sh"
command=$command" -repoInfoFile $repoInfoFile"
command=$command" -baseDir $relengBuilderDir"
command=$command" -proj $proj"
command=$command" -branch $branch"

if [ x$emfBranch != x ]; then
	command=$command" -projBranch $projBranch"; # override default $branch
fi

if [ x$projRelengBranch != x ]; then
	command=$command" -projRelengBranch $projRelengBranch"; # override default $branch
fi

command=$command" -buildTag $buildTag"
command=$command" -tagBuild $tagBuild"
command=$command" -eclipseURL $eclipseURL"
command=$command" -emfURL $emfURL"
command=$command" -oclURL $oclURL"

$relengBuilderDir/scripts/executeCommand.sh "$command"

export JAVA_HOME=$javaHome

if [ $tagBuild == 'false' ]; then
	mkdir -p $buildDir/maps/org.eclipse.emft.$proj/
	cp $relengBuilderDir/maps/* $buildDir/maps/org.eclipse.emft.$proj/
fi

if [ x$buildAlias != x ]; then
	buildAlias="-buildAlias $buildAlias"
fi

# Invoking the Eclipse build
command="$relengBuilderDir/scripts/build.sh"
command=$command" -mapVersionTag $buildTag"
command=$command" -vm $javaHome/bin/java"
#command=$command" -bc $javaHome/jre/lib/rt.jar"
#command=$command" -bc $javaHome" # removed as this is now defined in the ant script instead
command=$command" -antScript $relengBuilderDir/buildAll.xml"
command=$command" -target $antTarget"
command=$command" -buildID $buildID"
command=$command" -buildTimestamp $buildTimestamp"
command=$command" -relengBaseBuilderDir $relengBaseBuilderDir"
command=$command" -downloadsDir $downloadsDir"
command=$command" -buildDir $buildDir"
command=$command" -baseDir $relengBuilderDir"
command=$command" $buildAlias"
command=$command" $buildType"
$relengBuilderDir/scripts/executeCommand.sh "$command"
