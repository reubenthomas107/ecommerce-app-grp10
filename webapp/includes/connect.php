<?php

$host = 'DB_HOST_VALUE';
$user = 'ecappadmin';
$pass = 'DB_PASSWORD_VALUE';
$db   = 'ecommerce_1';

$ssl_cert = "/etc/mysql/ssl/rds-combined-ca-bundle.pem";

$con = new mysqli($host,$user,$pass,$db);
$con->ssl_set(NULL,NULL,$ssl_cert,NULL,NULL);
$con->real_connect($host, $user, $pass, $db, 3306, NULL, MYSQLI_CLIENT_SSL);

//Test SSL connectivity using the following code:
// $result = $con->query("SHOW STATUS LIKE 'Ssl_cipher';");
// $row = $result->fetch_assoc();

// if (!empty($row['Value'])) {
//     echo "Connected securely using SSL cipher: " . $row['Value'];
// } else {
//     echo "SSL is not being used.";
// }

if(!$con){
    die(mysqli_error($con));
}
?>
