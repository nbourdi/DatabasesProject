<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;





$conf->header('ΕΛΙΔΕΚ');
$conf->menu($active = basename(__FILE__, '.php'));

$query = " SELECT f1.field_name as field_1, f2.field_name as field_2, count 
            FROM 
                (SELECT fp1.field_id as field1 , fp2.field_id as field2, COUNT(*) AS count, fp1.project_id as proj
                FROM fieldproject fp1
                INNER JOIN fieldproject fp2 ON
                    fp1.project_id  = fp2.project_id AND fp1.field_id <> fp2.field_id
                group by fp1.field_id, fp2.field_id ) `t`
            INNER JOIN field f1 ON field1 = f1.field_id 
            INNER JOIN field f2 ON field2 = f2.field_id
            GROUP BY proj
            ORDER BY count DESC
            LIMIT 3;";

$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
   $data[] = $row;
  }
}

?>
    <div class="container mt-5">
        <h1>3.5</h1>
        <p>  Πολλά έργα/επιχορηγήσεις είναι διεπιστημονικά (δηλαδή καλύπτουν περισσότερα από ένα 
            πεδία/ τομείς). Ανάμεσα σε ζεύγη πεδίων (π.χ. επιστήμη των υπολογιστών και μαθηματικά) 
            που είναι κοινά στα έργα, βρείτε τα 3 κορυφαία (top-3) ζεύγη που εμφανίστηκαν σε έργα 
            (ενεργά και μή ενεργά).
        </p>
    </div>

<?php

    //----------------------------------- LIST ----------------------------------
    ?>
    <div class="container">
        <table class='table table-striped'>
            <thead>
            <tr>
                <th>Πεδίο 1</th>
                <th>Πεδίο 2</th>
                <th>Πλήθος κοινών έργων</th>
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
    global $icon; ?>
    <tr>
        <td><?php echo $row['field_1']; ?></td>
        <td><?php echo $row['field_2']; ?></td>
        <td><?php echo $row['count']; ?></td>
    </tr>  <?php
}