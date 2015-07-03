<?php
$wpPath = $argv[1];
$configFile = $argv[2];
require($wpPath);
$fh = fopen($configFile, 'w') or die("can't open file");

$wpSetting = DB_NAME;
fwrite($fh, "DB_NAME=$wpSetting\n");

$wpSetting = DB_USER;
fwrite($fh, "DB_USER=$wpSetting\n");

$wpSetting = DB_PASSWORD;
fwrite($fh, "DB_PASSWORD=$wpSetting\n");

$wpSetting = DB_HOST;
fwrite($fh, "DB_HOST=$wpSetting\n");

$wpSetting = WP_SITEURL;
fwrite($fh, "WP_SITEURL=$wpSetting\n");

fclose($fh);
?>