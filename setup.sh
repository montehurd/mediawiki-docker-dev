#!/usr/bin/env bash

# To install run this script using a command like the following (first change 'mm' to the desired install directory):
#   INSTALL_DIR=~/mm ./setup.sh

set -eu

dir=$PWD

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
git clone https://github.com/wikimedia/mediawiki.git mediawiki
git clone https://github.com/wikimedia/mediawiki-skins-Vector.git mediawiki/skins/Vector
git clone https://github.com/wikimedia/mediawiki-extensions-Elastica.git mediawiki/extensions/Elastica
git clone https://github.com/wikimedia/mediawiki-extensions-CirrusSearch.git mediawiki/extensions/CirrusSearch
git clone https://github.com/wikimedia/mediawiki-extensions-UniversalLanguageSelector.git mediawiki/extensions/UniversalLanguageSelector
git clone https://github.com/wikimedia/mediawiki-extensions-UploadWizard.git mediawiki/extensions/UploadWizard
git clone https://github.com/wikimedia/mediawiki-extensions-Wikibase.git mediawiki/extensions/Wikibase
git clone https://github.com/wikimedia/mediawiki-extensions-WikibaseCirrusSearch.git mediawiki/extensions/WikibaseCirrusSearch
git clone https://github.com/wikimedia/mediawiki-extensions-WikibaseMediaInfo.git mediawiki/extensions/WikibaseMediaInfo


cd mediawiki
docker run -it --rm --user $(id -u):$(id -g) -v ~/.composer:/tmp -v $(pwd):/app docker.io/composer install

touch LocalSettings.php
cat > LocalSettings.php <<EOL
<?php
require_once __DIR__ . '/.docker/LocalSettings.php';
wfLoadSkin( 'Vector' );
EOL


cd $dir


touch local.env
cat > local.env <<EOL
# Database
#
# Value: 'mariadb' or 'mysql'
DB=mariadb

# Web server
#
# Value: 'apache' or 'nginx'
WEBSERVER=apache

# PHP Runtime
#
# HHVM currently broken.
#
# Value: 'php' or 'hhvm'
PHPORHHVM=php

# PHP Runtime version
#
# See <https://github.com/webdevops/Dockerfile/tree/master/docker/php#readme>
# for valid values.
#
# For example:
# - 'latest' (alias to ubuntu-18.04)
# - 'ubuntu-18.04' (Ubuntu 18 Bionic LTS, provides PHP 7.2).
# - 'ubuntu-16.04' (Ubuntu 16 Xenial LTS, provides PHP 7.0).
# - '7.3' (based on Debian 9 Stretch)
# - '7.2' (based on Debian 9 Stretch)
# - '7.1' (based on Debian 9 Stretch)
RUNTIMEVERSION=latest

# Value for XDEBUG_REMOTE_HOST
#
# IP address of your local dev machine (from Docker) for xdebug breakpoint comms.
IDELOCALHOST=host.docker.internal

# MediaWiki install path
#
# Location of the MediaWiki repo on your machine
DOCKER_MW_PATH=$INSTALL_DIR/mediawiki

# External port (on host system) for webserver proxy
# Port to serve everything up through
DOCKER_MW_PORT=8080
EOL


./create


cd "$INSTALL_DIR"/mediawiki

cat > LocalSettings.php <<EOL
<?php
require_once __DIR__ . '/.docker/LocalSettings.php';
wfLoadSkin( 'Vector' );

wfLoadExtension( 'Elastica' );
wfLoadExtension( 'UploadWizard' );
wfLoadExtension( 'CirrusSearch' );
wfLoadExtension( 'UniversalLanguageSelector' );

\$wgDisableSearchUpdate = true;
\$wgCirrusSearchServers = [ "elasticsearch.svc" ];
EOL


cd $dir
docker-compose run "web" sh -c 'cd $MW_INSTALL_PATH/extensions/Elastica && composer install --no-dev'
docker-compose run "web" sh -c 'cd $MW_INSTALL_PATH/extensions/CirrusSearch && composer install --no-dev'
docker-compose run "web" sh -c 'php $MW_INSTALL_PATH/maintenance/update.php'
docker-compose run "web" sh -c 'php $MW_INSTALL_PATH/extensions/CirrusSearch/maintenance/updateSearchIndexConfig.php'


cd "$INSTALL_DIR"/mediawiki

cat > LocalSettings.php <<EOL
<?php
require_once __DIR__ . '/.docker/LocalSettings.php';
wfLoadSkin( 'Vector' );

wfLoadExtension( 'Elastica' );
wfLoadExtension( 'UploadWizard' );
wfLoadExtension( 'CirrusSearch' );
wfLoadExtension( 'UniversalLanguageSelector' );

\$wgCirrusSearchServers = [ "elasticsearch.svc" ];
EOL


cd $dir
docker-compose run "web" sh -c 'php $MW_INSTALL_PATH/extensions/CirrusSearch/maintenance/forceSearchIndex.php'


cd "$INSTALL_DIR"/mediawiki

cat > LocalSettings.php <<EOL
<?php
require_once __DIR__ . '/.docker/LocalSettings.php';
wfLoadSkin( 'Vector' );

wfLoadExtension( 'Elastica' );
wfLoadExtension( 'UploadWizard' );
wfLoadExtension( 'CirrusSearch' );
wfLoadExtension( 'UniversalLanguageSelector' );

\$wgCirrusSearchServers = [ "elasticsearch.svc" ];
\$wgSearchType = 'CirrusSearch';
EOL


touch composer.local.json
cat > composer.local.json <<EOL
{
  "extra": {
    "merge-plugin": {
       "include": [
         "extensions/Wikibase/composer.json"
       ]
    }
  }
}
EOL


cd $dir
docker-compose run "web" sh -c 'cd $MW_INSTALL_PATH && composer require wikimedia/composer-merge-plugin:1.4.1'
docker-compose run "web" sh -c 'php $MW_INSTALL_PATH/maintenance/update.php'


cd "$INSTALL_DIR"/mediawiki

cat > LocalSettings.php <<EOL
<?php
require_once __DIR__ . '/.docker/LocalSettings.php';
wfLoadSkin( 'Vector' );

wfLoadExtension( 'Elastica' );
wfLoadExtension( 'UploadWizard' );
wfLoadExtension( 'CirrusSearch' );
wfLoadExtension( 'UniversalLanguageSelector' );
wfLoadExtension( 'WikibaseCirrusSearch' );
wfLoadExtension( 'WikibaseMediaInfo' );

\$wgCirrusSearchServers = [ "elasticsearch.svc" ];
\$wgSearchType = 'CirrusSearch';

\$wgEnableWikibaseRepo = true;
\$wgEnableWikibaseClient = true;
require_once "\$IP/extensions/Wikibase/repo/Wikibase.php";
require_once "\$IP/extensions/Wikibase/repo/ExampleSettings.php";
require_once "\$IP/extensions/Wikibase/client/WikibaseClient.php";
require_once "\$IP/extensions/Wikibase/client/ExampleSettings.php";

\$wgMediaInfoEnableFilePageDepicts = true;
\$wgMediaInfoProperties = [
	'depicts' => 'P1',
];

\$wgUseImageMagick = true;
EOL


cd "$INSTALL_DIR"/mediawiki/extensions/Wikibase
git submodule update --init --recursive


cd $dir
docker-compose run "web" sh -c 'cd $MW_INSTALL_PATH/extensions/WikibaseCirrusSearch && composer install --no-dev'
docker-compose run "web" sh -c 'cd $MW_INSTALL_PATH && php maintenance/update.php'
docker-compose run "web" sh -c 'cd $MW_INSTALL_PATH/extensions/Wikibase && php lib/maintenance/populateSitesTable.php && php repo/maintenance/rebuildItemsPerSite.php && php client/maintenance/populateInterwiki.php'
