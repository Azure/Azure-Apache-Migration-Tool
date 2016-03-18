# 1-Click LAMP Migrate Tool

## What is it?
 The 1-Click LAMP Migrate Tool is a web application migrate assistant allows you migrate your existing web applications hosed on LAMP (Linux+Apache+MySQL+Php) environment to Microsoft Azure Web Apps Service easily.

## Documentation

The Web Apps feature in Azure App Service lets developers rapidly build, deploy, and manage powerful websites and web apps. Build standards-based web apps and APIs using .NET, Node.js, PHP, Python, and Java. Deliver both web and mobile apps for employees or customers using a single back end. Securely deliver APIs that enable additional apps and devices. More information about [Web Apps](https://azure.microsoft.com/en-us/services/app-service/web/).

LAMP is an open source Web development platform that uses Linux as the operating system, Apache as the Web server, MySQL as the relational database management system and PHP as the object-oriented scripting language.

1-Click LAMP Migrate Tool support move popular LAMP scenario into Azure Web Apps.

Supported Web Servers: Apache running on Linux (Ubuntu, CentOS 7, OpenSUSE etc.)

Supported PHP Frameworks: Wordpress, Drupal, Joomla (We plan to support more frameworks in future based on your feedback)

Supported Database: MySQL (or MariaDB). DB can be local or remote machine.

Using this tool, we will connect to you Linux server via SSH, and check your Apache and MySQL configuration and analyze your PHP site. Then we allow you to use exisiting PublishSettings or create a new Azure Web Apps + MySQL service on Azure with new PublishSettings. Finally, we will use the PublishSettings to migrate you website from LAMP to Microsoft Azure Web Apps automatically.

## Prerequisites

A valid Azure global account is required to login in the tool for creating resource group and Web Apps with MySQL services. Azure China (Mooncack) is not supported at the current stage. It is still on working.

SSH service is required to be enabled in the Linux side and a Superuser is required to run the migration script. The implementation is based on a limited preview perl script provided by production team. The script can be downloaded from [movemetothecloud.net](http://www.movemetothecloud.net/Azure-Apache-Migration-Tool.tar.gz). Some perl libraries, such as perl LWP HTTPS, are required in Linux side to run the script. Most should be included with your distro. In case it is not, you may need to download and install them manually. By default we don't include this library because it takes OS specific dependencies.

### Ubuntu
perl LWP HTTPS can be installed with apt-get:

```
sudo apt-get install liblwp-protocol-https-perl
```

### CentOS 7
perl LWP HTTPS can be installed with yum:

```
sudo yum install perl-LWP-Protocol-https
```

You may also need to install some additional libraries:
```
sudo yum install perl-Digest-MD5
sudo yum install perl-Compress-Raw-Zlib
```

### OpenSUSE
perl LWP HTTPS can be installed with zypper:
```
sudo zypper install perl-LWP-Protocol-https
```

## Acknowlgement

We introduced two open source projects in current implementation  including:

1. [SSH.NET Library](https://sshnet.codeplex.com/).

Thanks to these great projects.

##Contacts

lampmig@microsoft.com
