<?php
$ruleFile = $argv[1];
$rDatabase=$argv[2];
$rUsername=$argv[3];
$rPassword=$argv[4];
$rServer=$argv[5];
$rTargetUrl=$argv[6];
$configFile=$argv[7];

$fh = fopen($ruleFile, 'w') or die("can't open file");
#$lineMatch="(?^:\$db\s*=|\$user\s*=|\$password\s*=|\$host\s*=)";
$lineMatch = "\\\$db\s*=|\\\$user\s*=|\\\$password\s*=|\\\$host\s*=";
fwrite($fh, "$lineMatch\n");
fwrite($fh, "\n");
$settingsLine = "public \$db = '$rDatabase';\npublic \$user = '$rUsername';\npublic \$password = '$rPassword';\npublic \$host = '$rServer';\n";
fwrite($fh,"$settingsLine");

fclose($fh);
?>
