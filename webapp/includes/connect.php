<?php 
// $con=mysqli_connect('localhost','root','','ecommerce_1');
$host = 'DB_HOST_VALUE';
// $user = getenv('DB_USER');
$pass = 'DB_PASSWORD_VALUE';
// $db_name = getenv('DB_NAME');

$con = new mysqli($host,'ecappadmin', $pass,'ecommerce_1');
if(!$con){
    die(mysqli_error($con));
}
?>