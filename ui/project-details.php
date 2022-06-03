

<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;

$project_id = 1;

$query = "SELECT * FROM `project`
            WHERE `project_id` = $project_id ";

$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $data[] = $row;
  }
}

echo '<pre>';print_r($data);echo '</pre>';



$query = "SELECT * FROM `field` ";

$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $data[] = $row;
  }
}

echo '<pre>';print_r($data);echo '</pre>';