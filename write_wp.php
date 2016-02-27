<?php
$ruleFile = $argv[1];
$rDatabase=$argv[2];
$rUsername=$argv[3];
$rPassword=$argv[4];
$rServer=$argv[5];
$rTargetUrl=$argv[6];
$configFile=$argv[7];

$fh = fopen($ruleFile, 'w') or die("can't open file");

$lineMatch = "define.*'DB_NAME'|define.*'DB_USER'|define.*'DB_PASSWORD'|define.*'DB_HOST'|define\s*\(\s*'WP_CONTENT_DIR'";
fwrite($fh, "$lineMatch\n");
$lineNotMatch = "qr/define\s*\(\s*'WP_CONTENT_DIR',\s*ABSPATH\s*.\s*'wp-content'\s*\)/";
fwrite($fh, "$lineNotMatch\n");
$settingsLine = "define('DB_NAME', '$rDatabase');\ndefine('DB_USER', '$rUsername');\ndefine('DB_PASSWORD', '$rPassword');\ndefine('DB_HOST', '$rServer');\ndefine('WP_HOME','${rTargetUrl}'); \ndefine('WP_SITEURL','${rTargetUrl}');\ndefine('WP_CONTENT_DIR', ABSPATH.'wp-content');\n";
fwrite($fh,"$settingsLine");

fclose($fh);
?>
