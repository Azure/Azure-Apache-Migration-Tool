<?php
$wpPath = $argv[1];
$configFile = $argv[2];
require($wpPath);

$fh = fopen($configFile, 'w') or die("can't open file");

if(strpos($wpPath,'global.php')!== false)
{
$wpSetting = $_config['db']['1']['dbname'];
fwrite($fh, "DB_NAME=$wpSetting\n");

$wpSetting = $_config['db']['1']['dbuser'];
fwrite($fh, "DB_USER=$wpSetting\n");

$wpSetting =$_config['db']['1']['dbpw'] ;
fwrite($fh, "DB_PASSWORD=$wpSetting\n");

$wpSetting = $_config['db']['1']['dbhost'];
fwrite($fh, "DB_HOST=$wpSetting\n");
}
else if(strpos($wpPath,'ucenter.php')!==false)
{
$wpSetting = UC_DBNAME;
fwrite($fh, "DB_NAME=$wpSetting\n");

$wpSetting = UC_DBUSER; 
fwrite($fh, "DB_USER=$wpSetting\n");

$wpSetting = UC_DBPW;
fwrite($fh, "DB_PASSWORD=$wpSetting\n");

$wpSetting = UC_DBHOST;
fwrite($fh, "DB_HOST=$wpSetting\n");
}
else if(strpos($wpPath,'config.inc.php')!==false)
{
$wpSetting = UC_DBNAME;
fwrite($fh, "DB_NAME=$wpSetting\n");

$wpSetting = UC_DBUSER;
fwrite($fh, "DB_USER=$wpSetting\n");

$wpSetting = UC_DBPW;
fwrite($fh, "DB_PASSWORD=$wpSetting\n");

$wpSetting = UC_DBHOST;
fwrite($fh, "DB_HOST=$wpSetting\n");
}
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
