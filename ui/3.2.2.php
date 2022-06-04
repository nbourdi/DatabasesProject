<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;



$conf->header('ΕΛΙΔΕΚ - Αξιολογήσεις');
$conf->menu($active = basename(__FILE__, '.php'));

$query = " SELECT DISTINCT `project_id`, `title`, `abbreviation`, `eval_name`,  DATE_FORMAT(`eval_date`, '%d/%m/%Y') `eval_date`, `rating`
            FROM `eval_view`  ";
$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
      $key = $row['project_id'];
      unset($row['project_id']);
    $data[$key] = $row;
  }
  //echo '<pre>';print_r($data);echo '</pre>';//exit;
}

?>
    <div class="container mt-5">
        <h1>3.2.2</h1>
        <p>Όψη της επιλογής μας: Αξιολόγησεις των έργων.</p>
    </div>
<?php


    //----------------------------------- LIST ----------------------------------
    ?>
    <div class="container">
        <div class="text-end mb-2">
            Βρέθηκαν <span class="count-list"><?php echo count($data); ?></span> εγγραφές
        </div>
        <table class='table table-striped'>
            <thead>
            <tr>
                <th>Τίτλος Έργου</th>
                <th>Οργανισμός</th>
                <th>Βαθμός</th>
                <th>Ημ/νία Αξιολόγησης</th>
                <th>Αξιολογητής</th>
            </tr>
            </thead>    <?php
            
            foreach ($data as $key => $row) {
                    listItem($key, $row);
            }   ?>
            </tbody>
        </table>
    </div>    <?php



$conf->footer();


function listItem($key, $row) {
    global $icon;
    //$budget = json_decode($row['budget']);
    //echo '<pre>';print_r($budget);echo '</pre>';
    ?>
    <tr>
        <td><?php echo $row['title']; ?></td>
        <td><?php echo $row['abbreviation']; ?></td>
        <td><?php echo $row['rating']; ?></td>
        <td><?php echo $row['eval_date']; ?></td>
        <td><?php echo $row['eval_name']; ?></td>
        <td>
        </td>
    </tr>  <?php
}