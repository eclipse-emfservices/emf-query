#!/bin/sh
# Copyright (c) 2012, 2014 IBM Corporation and others.
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   IBM - Initial API and implementation

# Script may take 5-6 command line parameters:
# Hudson job name: ${JOB_NAME}
# Hudson build id: ${BUILD_ID}
# Hudson workspace: ${WORKSPACE}
# $1: Build type: n(ightly), m(aintenance), s(table), r(elease)
# $2: An optional label to append to the version string when creating drop files, e.g. M5 or RC1
# 
set -e

if [ $# -eq 1 -o $# -eq 2 ]; then
	buildType=$1
	if [ -n "$4" ]; then
		dropFilesLabel=$4
	fi
else
	echo "Usage: $0 [i | s | r | m] [qualifier]"
	echo "Example: $0 i"
	echo "Example: $0 s M7"
	exit 1
	if [ $# -ne 0 ]; then
		exit 1
	fi
fi

if [ -z "$JOB_NAME" ]; then
	echo "Error there is no Hudson JOB_NAME defined"; 
	exit 0
fi

if [ -z "$BUILD_ID" ]; then
	echo "Error there is no Hudson BUILD_ID defined"; 
	exit 0
fi

if [ -z "$WORKSPACE" ]; then
	echo "Error there is no Hudson WORKSPACE defined"; 
	exit 0
fi

# Determine the local update site we want to publish from
localTarget=${WORKSPACE}/org.eclipse.emf.query.repository/target
localUpdateSite=${localTarget}/repository/
echo "Using local update-site: $localUpdateSite"

# Determine remote update site we want to promote to (integration and maintenance are published on interim site, stable builds on milestone site, release builds on releases site)
case $buildType in
	m|M) remoteSite=maintenance ;;
	i|I) remoteSite=interim ;;
	s|S) remoteSite=milestones ;;
	r|R) remoteSite=releases ;;
	*) exit 0 ;;
esac
echo "Publishing as $remoteSite ( $buildType ) build"
remoteUpdateSiteBase="modeling/emf/query/updates/$remoteSite"
remoteUpdateSite="/home/data/httpd/download.eclipse.org/$remoteUpdateSiteBase"
echo "Publishing to remote update-site: $remoteUpdateSite"

if [ -z "$dropFilesLabel" -a "$buildType" != i ]; then
	echo "Please provide a drop files label to append to the version (e.g. M5, RC1) if this is not an I build."
	exit 0
fi

# Prepare a temp directory
tmpDir="$localTarget/$JOB_NAME-publish-tmp"
rm -fr $tmpDir
mkdir -p $tmpDir
cd $tmpDir
echo "Working in `pwd`"

# Download and prepare Eclipse SDK, which is needed to process the update site
echo "Downloading eclipse to $PWD"
cp /home/data/httpd/download.eclipse.org/eclipse/downloads/drops4/R-4.3.2-201402211700/eclipse-SDK-4.3.2-linux-gtk-x86_64.tar.gz .
tar -xzf eclipse-SDK-4.3.2-linux-gtk-x86_64.tar.gz
cd eclipse
chmod 700 eclipse
cd ..
if [ ! -d "eclipse" ]; then
	echo "Failed to download an Eclipse SDK, being needed for provisioning."
	exit
fi
# Prepare Eclipse SDK to provide WTP releng tools (used to postprocess repository, i.e set p2.mirrorsURL property)
echo "Installing WTP Releng tools"
./eclipse/eclipse -nosplash --launcher.suppressErrors -clean -debug -application org.eclipse.equinox.p2.director -repository http://download.eclipse.org/webtools/releng/repository/ -installIUs org.eclipse.wtp.releng.tools.feature.feature.group
# Clean up
echo "Cleaning up"
rm eclipse-SDK-4.3.2-linux-gtk-x86_64.tar.gz

# Generate drop files
echo "Converting update site to runnable form"
./eclipse/eclipse -nosplash -consoleLog -application org.eclipse.equinox.p2.repository.repo2runnable -source file:$localUpdateSite -destination file:drops/eclipse
qualifiedVersion=$(find $localUpdateSite/features/ -maxdepth 1 | grep "org.eclipse.emf.query_" | sed 's/.jar$//')
echo "qualifiedVersion is $qualifiedVersion"
qualifiedVersion=${qualifiedVersion#*_}
echo "qualifiedVersion is $qualifiedVersion"
qualifier=${qualifiedVersion##*.}
echo "qualifier is $qualifier"
qualifier=${qualifier#v}
echo "qualifier is $qualifier"
version=${qualifiedVersion%.*}
echo "version is $version"
dropDir="$(echo $buildType | tr '[:lower:]' '[:upper:]')$qualifier"
echo "dropDir is $dropDir"
localDropDir=drops/$version/$dropDir
echo "Creating drop files in local directory $tmpDir/$localDropDir"
mkdir -p $localDropDir

# Prepare local update site (merging is performed later, if required)
stagedUpdateSite="updates/$remoteSite/$dropDir"
mkdir -p $stagedUpdateSite
cp -R $localUpdateSite/* $stagedUpdateSite
echo "Copied $localUpdateSite to local directory $stagedUpdateSite."

# Append drop file suffix if one is specified				
if [ -n "$dropFilesLabel" ]; then
	version=$version$dropFilesLabel
	echo "version is now $version"
elif [ "$buildType" != r -a "$buildType" != R ]; then
	version="$(echo $buildType | tr '[:lower:]' '[:upper:]')$qualifier"
	echo "version is now $version"
else
	echo "version is now $version"
fi
				
cp eclipse/epl-v10.html drops/eclipse
cp eclipse/notice.html drops/eclipse
cd drops

# emf query SDK
zip -r ../$localDropDir/emf-query-SDK-$version.zip \
	eclipse/epl-v10.html eclipse/notice.html \
	eclipse/features/org.eclipse.emf.query_* \
	eclipse/features/org.eclipse.emf.query.doc_* \
	eclipse/features/org.eclipse.emf.query.ocl_* \
	eclipse/features/org.eclipse.emf.query.ocl.source_* \
	eclipse/features/org.eclipse.emf.query.sdk_* \
	eclipse/features/org.eclipse.emf.query.source_* \
	eclipse/plugins/org.eclipse.emf.query_* \
	eclipse/plugins/org.eclipse.emf.query.doc_* \
	eclipse/plugins/org.eclipse.emf.query.ocl_* \
	eclipse/plugins/org.eclipse.emf.query.ocl.source_* \
	eclipse/plugins/org.eclipse.emf.query.source_*
md5sum ../$localDropDir/emf-query-SDK-$version.zip > ../$localDropDir/emf-query-SDK-$version.zip.md5
echo "Created emf-query-SDK-$version.zip"
			
# emf-query runtime
zip -r ../$localDropDir/emf-query-runtime-$version.zip \
	eclipse/epl-v10.html eclipse/notice.html \
	eclipse/features/org.eclipse.emf.query_* \
	eclipse/features/org.eclipse.emf.query.ocl_* \
	eclipse/plugins/org.eclipse.emf.query_* \
	eclipse/plugins/org.eclipse.emf.query.ocl_*
md5sum ../$localDropDir/emf-query-runtime-$version.zip > ../$localDropDir/emf-query-runtime-$version.zip.md5
echo "Created emf-query-runtime-$version.zip"
			
# emf-query examples
zip -r ../$localDropDir/emf-query-examples-$version.zip \
	eclipse/epl-v10.html eclipse/notice.html \
	eclipse/features/org.eclipse.emf.query.examples_* \
	eclipse/features/org.eclipse.emf.query.examples.source_* \
	eclipse/plugins/org.eclipse.emf.query.examples_* \
	eclipse/plugins/org.eclipse.emf.query.examples.ocl_* \
	eclipse/plugins/org.eclipse.emf.query.examples.ocl.source_* \
	eclipse/plugins/org.eclipse.emf.query.examples.source_* \
	eclipse/plugins/org.eclipse.emf.query.examples.statements_* \
	eclipse/plugins/org.eclipse.emf.query.examples.statements.source_*
md5sum ../$localDropDir/emf-query-examples-$version.zip > ../$localDropDir/emf-query-examples-$version.zip.md5
echo "Created emf-query-examples-$version.zip"
			
# emf-query automated-tests
zip -r ../$localDropDir/emf-query-automated-tests-$version.zip \
	eclipse/epl-v10.html eclipse/notice.html \
	eclipse/features/org.eclipse.emf.query.tests_* \
	eclipse/plugins/org.eclipse.emf.query.tests_* \
	eclipse/plugins/org.eclipse.emf.query.ocl.tests_*
md5sum ../$localDropDir/emf-query-automated-tests-$version.zip > ../$localDropDir/emf-query-automated-tests-$version.zip.md5
echo "Created emf-query-automated-tests-$version.zip"
	
cd $tmpDir
		
cd $stagedUpdateSite
zip -r ../../../$localDropDir/emf-query-Update-$version.zip features plugins binary artifacts.jar content.jar
md5sum ../../../$localDropDir/emf-query-Update-$version.zip > ../../../$localDropDir/emf-query-Update-$version.zip.md5
echo "Created emf-query-Update-Site-$version.zip"

cd $tmpDir

#generating build.cfg file to be referenced from downloads web page
echo "hudson.job.name=${JOB_NAME}" > $localDropDir/build.cfg
echo "hudson.job.id=${BUILD_NUMBER} (${jobDir##*/})" >> $localDropDir/build.cfg
echo "hudson.job.url=${BUILD_URL}" >> $localDropDir/build.cfg

remoteDropDir=/home/data/httpd/download.eclipse.org/modeling/emf/query/downloads/drops/$dropDir
mkdir -p $remoteDropDir
cp -R $localDropDir/* $remoteDropDir/

#echo "Merging existing site into local one."
#./eclipse/eclipse -nosplash --launcher.suppressErrors -clean -debug -application org.eclipse.equinox.p2.metadata.repository.mirrorApplication -source file:$remoteUpdateSite -destination file:$stagedUpdateSite
#./eclipse/eclipse -nosplash --launcher.suppressErrors -clean -debug -application org.eclipse.equinox.p2.artifact.repository.mirrorApplication -source file:$remoteUpdateSite -destination file:$stagedUpdateSite
#echo "Merged $remoteUpdateSite into local directory $stagedUpdateSite."

# Ensure p2.mirrorURLs property is used in update site
echo "Setting p2.mirrorsURL to http://www.eclipse.org/downloads/download.php?format=xml&file=/$remoteUpdateSiteBase"
./eclipse/eclipse -nosplash --launcher.suppressErrors -clean -debug -application org.eclipse.wtp.releng.tools.addRepoProperties -vmargs -DartifactRepoDirectory=$PWD/$stagedUpdateSite -Dp2MirrorsURL="http://www.eclipse.org/downloads/download.php?format=xml&file=/$remoteUpdateSiteBase"

# Create p2.index file
if [ ! -e "$stagedUpdateSite/p2.index" ]; then
	echo "Creating p2.index file"
	echo "version = 1" > $stagedUpdateSite/p2.index
	echo "metadata.repository.factory.order = content.xml,\!" >> $stagedUpdateSite/p2.index
	echo "artifact.repository.factory.order = artifacts.xml,\!" >> $stagedUpdateSite/p2.index
fi

# Backup then clean remote update site
if [ -d "$remoteUpdateSite" ]; then
	echo "Creating backup of remote update site $remoteUpdateSite to $tmpDir/BACKUP."
	if [ -d $tmpDir/BACKUP ]; then
		rm -fr $tmpDir/BACKUP
	fi
	mkdir $tmpDir/BACKUP
	cp -R $remoteUpdateSite $tmpDir/BACKUP
	rm -fr $remoteUpdateSite
fi

echo "Publishing local $stagedUpdateSite directory to remote update site $remoteUpdateSite/$dropDir"
mkdir -p $remoteUpdateSite
cp -R $stagedUpdateSite $remoteUpdateSite

# Create the composite update site
cat > p2.composite.repository.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project name="p2 composite repository">
<target name="default">
<p2.composite.repository>
<repository compressed="true" location="${remoteUpdateSite}" name="${JOB_NAME}"/>
<add>
<repository location="${dropDir}"/>
</add>
</p2.composite.repository>
</target>
</project>
EOF

echo "Update the composite update site"
./eclipse/eclipse -nosplash --launcher.suppressErrors -clean -debug -application org.eclipse.ant.core.antRunner -buildfile p2.composite.repository.xml default

# Clean up
echo "Cleaning up"
#rm -fr eclipse
#rm -fr update-site
