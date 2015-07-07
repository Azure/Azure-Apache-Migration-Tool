# Azure Apache Migration Tool
## Introduction
The Azure Apache Migration Migration Tool is a tool that allows customers to move their existing sites hosted on Linux servers running Apache into the cloud on Azure websites. For more information check out [movemetothecloud.net](https://www.movemetothecloud.net/).

## Prerequisites
This requires some perl libraries. Most should be included with your distro, the most notable missing piece is perl LWP HTTPS support. By default we don't include this library because it takes OS specific dependencies.

### Ubuntu
perl LWP HTTPS can be installed with apt-get:

```
sudo apt-get install liblwp-protocol-https-perl
```

### CentOS 7
perl LWP HTTPS can be installed with yum:

```
yum install perl-LWP-Protocol-https
```

You may also need to install some additional libraries:
```
yum install perl-Digest-MD5
yum install perl-Compress-Raw-Zlib
```

## Running the tool
To run the tool, execute:

```
perl migrate_tool_main.pl
```

And follow the prompts.

## How does it work?
The tool parses the main Apache configuration file, detects all sites and their root directories.
We then allow you to create the sites and databases using our website.
Once the sites and databases are created, we read in the publishing settings, and move the site and databases into the cloud.

## What are the supported frameworks?
Currently we support the following PHP frameworks:
- Wordpress
- Drupal
- Joomla

We plan to add more support for other frameworks in the future.