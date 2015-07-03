<?php
$settingsPath = $argv[1];
$configFile = $argv[2];
require($settingsPath);
$fh = fopen($configFile, 'w') or die("can't open file");

$config = new JConfig(); 
$setting = $config->db;
fwrite($fh, "DB_NAME=$setting\n");

$setting = $config->user;
fwrite($fh, "DB_USER=$setting\n");

$setting = $config->password;
fwrite($fh, "DB_PASSWORD=$setting\n");

$setting = $config->host;
fwrite($fh, "DB_HOST=$setting\n");

$files = get_included_files();
fwrite($fh, "INCLUDED_FILES=");
foreach ($files as $file) 
{ 
    if ($file != __FILE__)
    {
        fwrite($fh, "${file};");
    }
}

fclose($fh);
?>