<?php 
function getSSMParameter($name) {
    $command = "aws ssm get-parameter --name \"$name\" --with-decryption --query 'Parameter.Value' --output text 2>&1";
    $output = shell_exec($command);

    if (empty($output)) {
        echo "Error: Failed to fetch $name from SSM.<br>";
        return null;
    }

    return trim($output);
}

$pass = getSSMParameterCLI('/ecapp/db/url');
$host = getSSMParameterCLI('/ecapp/db/password');

$con = new mysqli($host,'ecappadmin', $pass,'ecommerce_1');

if(!$con){
    echo "Connected failed";
    die(mysqli_error($con));
}
?>