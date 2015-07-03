# Azure Apache Migration Tool
## Introduction
The Azure Apache Migration Migration Tool is a tool that allows customers to move their existing sites hosted on Linux servers running Apache into the cloud on Azure websites. For more information check out [movemetothecloud.net](https://www.movemetothecloud.net/).

## Prerequisites
This requires perl LWP HTTPS support. On Ubuntu this can easily be installed by apt-get with:

```
sudo apt-get install liblwp-protocol-https-perl
```

By default we don't include this library because it takes OS specific dependencies.

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