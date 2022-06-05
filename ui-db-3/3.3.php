<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;


//echo '<pre>'; print_r($_POST);echo'</pre>';
if(isset($_POST['filters'], $_POST['field_id']) && $_POST['filters'] == 'field' && is_numeric($_POST['field_id']))  {
    $field = $mysqli->real_escape_string($_POST['field_id']);
    doubleTable(dataQuery1($field),dataQuery2($field));
    exit;
}

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
                <form id="choose-field-filters" action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST" >
                    <div class="btn-group-vertical btn-group-toggle ml-4" data-toggle="buttons"> <?php
                        foreach ($field as $key => $name) {
                            $checked = array_key_first($field)==$key;  ?>
                            <label class="<?php echo 'btn radio-btn'.($checked?' active':''); ?>" for="<?php echo 'field_'.$key; ?>">
                                <input <?php echo $checked?'checked':''; ?> type="radio" name="<?php echo 'field_'.$key; ?>" id="<?php echo 'field_'.$key; ?>" value="<?php echo $key; ?>">
                                <?php echo $name; ?>
                            </label> <?php
                        } ?>
                    </div>
                </form>
            </div>
            <div class="col-9 filters-content">
                <?php doubleTable(dataQuery1(),dataQuery2()); ?>
            </div>
        </div>
            
    </div>    <?php

$conf->footer();

function doubleTable($data_1,$data_2) { ?>
    <div class="row">
        <div class="col-7">
            <table class='table table-striped'>
                <thead>
                    <tr>
                        <th>Τίτλος</th>
                        <th>Έναρξη</th>
                        <th>Λήξη</th>
                    </tr>
                </thead> 
                <tbody>   <?php
                    foreach ($data_1 as $key => $row) { ?>
                        <tr>
                            <td><?php echo $row['title']; ?></td>
                            <td><?php echo $row['start_date']; ?></td>
                            <td><?php echo $row['end_date']; ?></td>
                        </tr>  <?php
                    }   ?>
                </tbody>
            </table>
        </div>
        <div class="col-5">
            <table class='table table-striped'>
                <thead>
                    <tr>
                        <th>Όνομα</th>
                    </tr>
                </thead> 
                <tbody>   <?php
                    foreach ($data_2 as $key => $row) { ?>
                        <tr>
                            <td><?php echo $row['full_name']; ?></td>
                        </tr>  <?php
                    }   ?>
                </tbody>
            </table>
        </div>
    </div> <?php
}

function dataQuery1($field = 1) {
    global $mysqli;
    $query = "  SELECT p.title, DATE_FORMAT(p.start_date, '%d/%m/%Y') `start_date`, DATE_FORMAT(p.end_date, '%d/%m/%Y') `end_date` FROM project p
    INNER JOIN FieldProject f ON f.project_id = p.project_id
    WHERE f.field_id = $field and p.end_date > curdate(); ";

    $result = $mysqli->query($query);
    $data = [];
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
    }
    return $data;
}

function dataQuery2($field = 1) {
    global $mysqli;
    $query = "  SELECT DISTINCT concat(R.first_name,' ',R.last_name) AS full_name 
        FROM researcher R 
        INNER JOIN WorksOn w ON w.researcher_id = R.researcher_id
        INNER JOIN project p ON p.project_id = w.project_id
        WHERE p.project_id IN (
            SELECT p.project_id FROM project p
            INNER JOIN FieldProject f ON f.project_id = p.project_id
            WHERE f.field_id = $field and p.end_date > curdate()); ";
    $result = $mysqli->query($query);
    $data = [];
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
    }
    return $data;
}