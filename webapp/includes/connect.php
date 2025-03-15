<?php 
// $con=mysqli_connect('localhost','root','','ecommerce_1');
$host = getenv('DB_HOST');
// $user = getenv('DB_USER');
$pass = getenv('DB_PASS');
// $db_name = getenv('DB_NAME');

$con = new mysqli($host,'ecappadmin', $pass,'ecommerce_1');
if(!$con){
    die(mysqli_error($con));
}


?>