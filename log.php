<?php

date_default_timezone_set('America/New_York');

if(isset($_GET['n'])){
	$file = file('logfile.txt'); //Read in the logfile
	$num = intval($_GET['n']);
	$output = array();

	foreach(range(0,$num-1) as $i){
		$output[$i] = $file[$i];
	}

	http_response_code(200);
	echo json_encode($output);
}elseif(isset($_POST["log"])){
	// prepend string
	$str = '<span style=\'color: green;\'>' . date('n/j/Y, g:i:s A') . '</span><span> - ' . htmlspecialchars($_POST["log"]) . '</span><br />';
	$str .= file_get_contents('logfile.txt') . "\n";

	if(file_put_contents('logfile.txt', $str)){
		http_response_code(200);
		echo "Success";
	}else{
		http_response_code(500);
		echo "Error writing to file";
	}

}else{
	http_response_code(401);
	echo "Invalid operation\n";
	var_dump($_REQUEST);
}
 
?>