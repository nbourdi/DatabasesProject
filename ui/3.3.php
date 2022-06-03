<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;





$conf->header('ΕΛΙΔΕΚ');
$conf->menu($active = basename(__FILE__, '.php'));

$query = "  SELECT `field_id`, `field_name` 
            FROM `field` ";

$result = $mysqli->query($query);
$field = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $field[$row['field_id']] = $row['field_name'];
  }
}
$query = "  SELECT p.title, p.start_date, p.end_date FROM project p
            INNER JOIN FieldProject f ON f.project_id = p.project_id
            WHERE f.field_id = 1 and p.end_date > curdate(); ";

$result = $mysqli->query($query);
$data_1 = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
   $data_1[] = $row;
  }
}

$query = "  SELECT DISTINCT concat(R.first_name,' ',R.last_name) AS full_name 
            FROM researcher R 
            INNER JOIN WorksOn w ON w.researcher_id = R.researcher_id
            INNER JOIN project p ON p.project_id = w.project_id
            WHERE p.project_id IN (
                SELECT p.project_id FROM project p
                INNER JOIN FieldProject f ON f.project_id = p.project_id
                WHERE f.field_id = 1 and p.end_date > curdate()); ";
$result = $mysqli->query($query);
$data_2 = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
   $data_2[] = $row;
  }
}
//echo '<pre>';print_r($data_1);echo '</pre>';
?>
    <div class="container mt-5">
        <h1>3.3</h1>
        <p>Δεδομένου ότι ένα συγκεκριμένο ερευνητικό πεδίο απέκτησε ιδιαίτερο ενδιαφέρον, ποια έργα χρηματοδοτούνται σε αυτό το πεδίο και ποιοι ερευνητές ασχολούνται με αυτό το πεδίο το τελευταίο έτος; (Προσοχή - ενεργά έργα).</p>
    </div>

<?php

    //----------------------------------- LIST ----------------------------------
    ?>
    <div class="container">
        <div class="row">
            <div class="col-3">
                <h4>Επιστημονικά πεδία</h4>
                <ul class="list-group"> <?php
                    foreach ($field as $key => $name) { ?>
                        <li class="list-group-item">
                            <?php echo $name; ?>
                        </li> <?php
                    } ?>
                </ul>
            </div>
            <div class="col-9">
                <div class="row">
                    <div class="col-6">
                        <table class='table table-striped'>
                            <thead>
                                <tr>
                                    <th>Τίτλος</th>
                                    <th>Έναρξη</th>
                                    <th>Λήξη</th>
                                </tr>
                            </thead> 
                            <tbody>   <?php
                                foreach ($data_1 as $key => $row) {
                                        listItem_1($key, $row);
                                }   ?>
                            </tbody>
                        </table>
                    </div>
                    <div class="col-6">
                        <table class='table table-striped'>
                            <thead>
                                <tr>
                                    <th>Όνομα</th>
                                </tr>
                            </thead> 
                            <tbody>   <?php
                                foreach ($data_2 as $key => $row) {
                                        listItem_2($key, $row);
                                }   ?>
                            </tbody>
                        </table>
                    </div>
            </div>
        </div>
            
    </div>    <?php

$conf->footer();

function listItem_1($key, $row) {
    global $icon; ?>
    <tr>
        <td><?php echo $row['title']; ?></td>
        <td><?php echo $row['start_date']; ?></td>
        <td><?php echo $row['end_date']; ?></td>
    </tr>  <?php
}

function listItem_2($key, $row) {
    global $icon; ?>
    <tr>
        <td><?php echo $row['full_name']; ?></td>
    </tr>  <?php
}