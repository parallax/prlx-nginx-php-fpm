#!/usr/bin/php

<?php

$CUSTOMCONFIG = file_get_contents('/etc/nginx/custom.conf');
$ORIGINALCONFIG = file_get_contents('/etc/nginx/sites-enabled/site.conf');
$ORIGINALCONFIG = str_replace('####CUSTOM####', $CUSTOMCONFIG, $ORIGINALCONFIG);
file_put_contents('/etc/nginx/sites-enabled/site.conf', $ORIGINALCONFIG);

?>