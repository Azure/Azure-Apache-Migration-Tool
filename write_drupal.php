<?php
$ruleFile = $argv[1];
$rDatabase=$argv[2];
$rUsername=$argv[3];
$rPassword=$argv[4];
$rServer=$argv[5];
$rTargetUrl=$argv[6];
$configFile=$argv[7];

$fh = fopen($ruleFile, 'w') or die("can't open file");

$lineMatch = "^\\\$databases.*'default'.*'default'|^\\\$databases.*=.*array";
fwrite($fh, "$lineMatch\n");
fwrite($fh, "\n");
$settingsLine = "\$databases['default']['default']=array('driver'=>'mysql','database' =>'$rDatabase','username'=>'$rUsername','password'=>'$rPassword','host'=>'$rServer','port' => '','prefix' => '');\n";
fwrite($fh,"$settingsLine");

fclose($fh);
?>
