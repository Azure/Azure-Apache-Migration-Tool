<?php
$drupalPath = $argv[1];
$configFile = $argv[2];
require($drupalPath);
$fh = fopen($configFile, 'w') or die("can't open file");

$wpSetting = $databases["default"]["default"]["database"];
fwrite($fh, "DB_NAME=$wpSetting\n");

$wpSetting = $databases["default"]["default"]["username"];
fwrite($fh, "DB_USER=$wpSetting\n");

$wpSetting = $databases["default"]["default"]["password"];
fwrite($fh, "DB_PASSWORD=$wpSetting\n");

$wpSetting = $databases["default"]["default"]["host"];
fwrite($fh, "DB_HOST=$wpSetting\n");

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