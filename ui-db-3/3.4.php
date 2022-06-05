<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;





$conf->header('ΕΛΙΔΕΚ');
$conf->menu($active = basename(__FILE__, '.php'));

$query = " SELECT `ab`, `org_name`, `proj_count`, `proj_count2`, concat(`year1`, ' - ', `year2`) AS `span` FROM
            (SELECT o.`abbreviation` as `ab`, `o`.`name` as `org_name`, count(*) AS `proj_count`, year(`p`.`start_date`) AS `year1`
            FROM `organization` `o`
            INNER JOIN `project` `p` ON `o`.`abbreviation` = `p`.`abbreviation`
            GROUP BY `o`.`abbreviation`, year(`p`.`start_date`)
            ) `t`,
            (SELECT `o`.`abbreviation`, `o`.`name`, count(*) AS `proj_count2`, year(`p`.`start_date`) AS `year2`
            FROM `organization` o
            INNER JOIN `project` `p` ON `o`.`abbreviation` = `p`.`abbreviation`
            GROUP BY `o`.`abbreviation`, year(`p`.`start_date`)
            ) `t2`
            WHERE `t2`.`abbreviation` = `ab` AND `year2` - `year1` = 1
            HAVING `proj_count2` = `proj_count` AND `proj_count` >= 10 ";

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
        <h1>3.4</h1>
        <p>  Ποιοι οργανισμοί έχουν λάβει τον ίδιο αριθμό έργων σε διάστημα δύο συνεχόμενων ετών, με 
            τουλάχιστον 10 έργα ετησίως;
        </p>
    </div>

<?php

    //----------------------------------- LIST ----------------------------------
    ?>
    <div class="container">
        <table class='table table-striped'>
            <thead>
            <tr>
                <th>Συντομογραφία</th>
                <th>Όνομα οργανισμού</th>
                <th>Πλήθος έργων ετησίως</th>
                <th>Έτη</th>
            </tr>
            </thead>
            <tbody>    <?php
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
        <td><?php echo $row['ab']; ?></td>
        <td><?php echo $row['org_name']; ?></td>
        <td><?php echo $row['proj_count']; ?></td>
        <td><?php echo $row['span']; ?></td>
    </tr>  <?php
}