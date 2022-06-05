<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;


$conf->header('ΕΛΙΔΕΚ - Προγράμματα');
$conf->menu($active = basename(__FILE__, '.php'));

$query = "  SELECT r.researcher_id, r.first_name, r.last_name, COUNT(*) `count`
            FROM researcher r 
            INNER JOIN WorksOn w ON r.researcher_id = w.researcher_id
            inner join project p ON w.project_id = p.project_id 
            WHERE w.project_id NOT IN (SELECT project_id FROM deliverable)  AND p.end_date > curdate()
            GROUP BY r.researcher_id
            HAVING COUNT(*) > 4
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
}   ?>

<div class="container mt-5">
<h1>3.8</h1>
<p>Βρείτε τους ερευνητές που εργάζονται σε 5 ή περισσότερα έργα που δεν έχουν παραδοτέα (όνομα ερευνητή και αριθμός έργων).</p>
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
                <th>Όνομα</th>
                <th>Επώνυμο</th>
                <th>Αριθμός έργων</th>

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
        <td><?php echo $row['count']; ?></td>

    </tr>  <?php
}