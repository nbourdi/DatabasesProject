<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;





$conf->header('ΕΛΙΔΕΚ');
$conf->menu($active = basename(__FILE__, '.php'));

$query = " SELECT * FROM (
            SELECT e.executive_id AS id, concat(e.first_name,' ',e.last_name) AS full_name, o.name, p.amount
            FROM executive e  
            NATURAL JOIN project p 
            NATURAL JOIN organization o
            WHERE o.type = 'co'
            ORDER BY p.amount DESC
            LIMIT 5
            ) `t` 
            GROUP BY `full_name`
            ORDER BY amount DESC; ";

$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $key = $row['id'];
    unset($row['id']);
    $data[$key] = $row;
  }
}

?>
    <div class="container mt-5">
        <h1>3.7</h1>
        <p> Τα top-5 στελέχη που δουλεύουν για το ΕΛ.ΙΔ.Ε.Κ. και έχουν δώσει το μεγαλύτερο ποσό 
                χρηματοδοτήσεων σε μια εταιρεία.</p>
    </div>

<?php

    //----------------------------------- LIST ----------------------------------
    ?>
    <div class="container">
        <table class='table table-striped'>
            <thead>
            <tr>
                <th>Όνομα</th>
                <th>Εταιρεία</th>
                <th>Ποσό Χρηματοδότησης</th>
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
        <td><?php echo $row['full_name']; ?></td>
        <td><?php echo $row['name']; ?></td>
        <td><?php echo $row['amount']; ?></td>
    </tr>  <?php
}