This is a fork of [MediaWiki-Docker-Dev](https://github.com/addshore/mediawiki-docker-dev) with a script which simplifies setup of a "Dockerized" Mediawiki Structured Data on Commons development environment. ( manual setup instructions are [pretty complicated](https://gist.github.com/montehurd/d227af99fdb753d739d40b98644f16c2) )

## Prerequisite
Install Docker:

On MacOS you can use [homebrew](https://brew.sh) to install Docker using the command `brew install docker`.

Other platform installation packages can be found here:
https://docs.docker.com/install/

## Installation Instructions

To install, clone this repo, then from the console, in the directory of the downloaded repo, run the setup script using a command like the following (first changing 'mm' to the desired install directory - this is the folder where Mediawiki and various extensions will be cloned):
```
INSTALL_DIR=~/mm ./setup.sh
```
Installation will take a few minutes.

## Test the installation

To see if it worked, in a browser load:

http://default.web.mw.localhost:8080/mediawiki/index.php?title=Special:Version

If you scroll down you should see `WikibaseMediaInfo` under `Installed extensions`.

If the link in the step above doesn't work, you may need to manually edit `/etc/hosts` (i.e. `sudo atom /etc/hosts`) adding the following lines:
<pre>
127.0.0.1 default.web.mw.localhost # mediawiki-docker-dev
127.0.0.1 proxy.mw.localhost # mediawiki-docker-dev
127.0.0.1 phpmyadmin.mw.localhost # mediawiki-docker-dev
127.0.0.1 graphite.mw.localhost # mediawiki-docker-dev
</pre>

## Add some structured data

Steps to add some structured data and associate it with an image.

In browser load `Special:SpecialPages`:

http://default.web.mw.localhost:8080/mediawiki/index.php?title=Special:SpecialPages

There should be `Wikibase` section near the bottom now.

Click `Create a new Item` link:

http://default.web.mw.localhost:8080/mediawiki/index.php?title=Special:NewItem

Create a `San Francisco` item (set `Label` to `San Francisco`). Should see `Q1` to right of `San Francisco` after you save it.

In browser load `Special:SpecialPages` again:

http://default.web.mw.localhost:8080/mediawiki/index.php?title=Special:SpecialPages

Click `Create a new Property` link:

http://default.web.mw.localhost:8080/mediawiki/index.php?title=Special:NewProperty

set `Label` to `depicts`

set `Description` to something like `what is shown in image`

set `Data type` to `Item`

Should see `P1` to right of `depicts` after you save it - this is the `P1` referred to in `mediawiki/LocalSettings.php` where it says:
<pre>
$wgMediaInfoProperties = [
	'depicts' => 'P1',
];
</pre>

### Associate data from previous step with image

Load main page:

http://default.web.mw.localhost:8080/mediawiki/index.php?title=Main_Page

Log in:

http://default.web.mw.localhost:8080/mediawiki/index.php?title=Special:UserLogin&returnto=Main+Page
<pre>
Admin
dockerpass
</pre>

Upload any image file:

http://default.web.mw.localhost:8080/mediawiki/index.php?title=Special:Upload

After upload there should be a `Structured data` tab to right of `File Information` below the image.

Tap the `Structured data` tab, then tap `Edit`, then begin typing `San Francisco` and you should see the `Q1` item we created earlier.

## Example configuration of Xdebug (with PHPStorm)

To configuring `PHPStorm` to work with `Xdebug`, you'll need to add a `server` under `Preferences > Languages & Frameworks > PHP > Servers`. Choose settings similar to those in the image below:

![Screen Shot 2019-07-02 at 4 07 53 PM](https://user-images.githubusercontent.com/3143487/60554129-cc648000-9d25-11e9-9d53-5c48076bc299.png)

Then create a `Run / Debug configuration`. Tap `Run > Edit Configurations...`, then tap `+`, then select `PHP Remote Debug` and choose the `server` created in the first image and enter an IDE key of `PHPSTORM`:

![Screen Shot 2019-07-02 at 4 05 54 PM](https://user-images.githubusercontent.com/3143487/61083677-df5d0b80-a41b-11e9-998f-56ab0a2574bf.png)

Next tap this icon:

![Screen Shot 2019-07-02 at 5 10 00 PM](https://user-images.githubusercontent.com/3143487/60554417-08e4ab80-9d27-11e9-9fe0-302e5c52b2f4.png)

Note: on non-MacOS hosts you will probably need to change the `IDELOCALHOST` value in `/mediawiki-docker-dev-sdc/local.env` to your machine's local IP address. After changing it you'll need to restart the Docker bits by running `./destroy` then `./create` in `/mediawiki-docker-dev-sdc`.
