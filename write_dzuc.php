<?php
$ruleFile = $argv[1];
$rDatabase=$argv[2];
$rUsername=$argv[3];
$rPassword=$argv[4];
$rServer=$argv[5];
$rTargetUrl=$argv[6];
$configFile=$argv[7];
$filename=&basename($configFile);

$fh = fopen($ruleFile, 'w') or die("can't open file");

if(strpos($filename,'global.php') !== false)
{
$lineMatch = "^\\\$_config.*'dbhost'.*=.*';|^\\\$_config.*'dbuser'.*=.*';|^\\\$_config.*'dbpw'.*=.*';|^\\\$_config.*'dbname'.*=.*';";
fwrite($fh, "$lineMatch\n");
fwrite($fh, "\n");
$settingsLine = "\$_config['db']['1']['dbname'] = '$rDatabase';\n\$_config['db']['1']['dbuser'] = '$rUsername';\n\$_config['db']['1']['dbpw'] = '$rPassword';\n\$_config['db']['1']['dbhost'] = '$rServer';\n";
fwrite($fh,"$settingsLine");
}
else if(strpos($filename,'ucenter.php')!==false)
{
$lineMatch = "^define\('UC_DBHOST'.*|^define\('UC_DBUSER'.*|^define\('UC_DBPW'.*|^define\('UC_DBNAME'.*|define\('UC_API'.*|define\('UC_DBTABLEPRE'.*";
fwrite($fh, "$lineMatch\n");
fwrite($fh, "\n");
$settingsLine ="define('UC_DBHOST', '$rServer');\ndefine('UC_DBUSER', '$rUsername');\ndefine('UC_DBPW', '$rPassword');\ndefine('UC_DBNAME', '$rDatabase');\ndefine('UC_API','$rTargetUrl/uc_server');\ndefine('UC_DBTABLEPRE','`$rDatabase`.pre_ucenter_');\n"; 
fwrite($fh,"$settingsLine");
}
else if(strpos($filename,'config.inc.php')!==false)
{
$lineMatch = "^define\('UC_DBHOST'.*|^define\('UC_DBUSER'.*|^define\('UC_DBPW'.*|^define\('UC_DBNAME'.*";
fwrite($fh, "$lineMatch\n");
fwrite($fh, "\n");
$settingsLine ="define('UC_DBHOST', '$rServer');\ndefine('UC_DBUSER', '$rUsername');\ndefine('UC_DBPW', '$rPassword');\ndefine('UC_DBNAME', '$rDatabase');\n";
fwrite($fh,"$settingsLine");
}

fclose($fh);
?>
