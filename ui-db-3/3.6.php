<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;





$conf->header('ΕΛΙΔΕΚ');
$conf->menu($active = basename(__FILE__, '.php'));

$query = " SELECT r.researcher_id, r.first_name, r.last_name, COUNT(*) as count , DATE_FORMAT(FROM_DAYS(DATEDIFF(now(), r.birth_date)), '%Y')+0  AS age 
            FROM researcher r 
            INNER JOIN WorksOn w ON w.researcher_id = r.researcher_id
            INNER JOIN project p ON p.project_id = w.project_id WHERE p.end_date > curdate()
            GROUP BY r.researcher_id
            HAVING age < 40
            ORDER BY COUNT(*) DESC; ";

$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $key = $row['researcher_id'];
    unset($row['researcher_id']);
    $data[$key] = $row;
  }
}

?>
    <div class="container mt-5">
        <h1>3.6</h1>
        <p> Βρείτε τους νέους ερευνητές (ηλικία < 40 ετών) που εργάζονται στα περισσότερα ενεργά έργα
        και τον αριθμό των έργων που εργάζονται.
        </p>
    </div>

<?php

    //----------------------------------- LIST ----------------------------------
    ?>
    <div class="container">
        <table class='table table-striped'>
            <thead>
            <tr>
                <th>Όνομα</th>
                <th>Επώνυμο</th>
                <th>Ηλικία</th>
                <th>Πλήθος Έργων</th>
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
        <td><?php echo $row['first_name']; ?></td>
        <td><?php echo $row['last_name']; ?></td>
        <td><?php echo $row['age']; ?></td>
        <td><?php echo $row['count']; ?></td>
    </tr>  <?php
}