<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;


// PREVIEW
if(isset($_POST['previw'], $_POST['edit_id']) && $_POST['previw'] == 'projectresearcher' && is_numeric($_POST['edit_id'])) {
    $edit_id = $mysqli->real_escape_string($_POST['edit_id']);
    $project = [];
    $query = "	SELECT `project_id`, `title`
                FROM `projectresearcher_vw`
                WHERE `researcher_id` = $edit_id; ";
    $result = $mysqli->query($query);
    while($row = $result->fetch_assoc()) {
        $project[$row['project_id']] = $row['title'];
      }
    preview($project);
    //echo $_SERVER['SERVER_ADDR'];
    exit;
}


$conf->header('ΕΛΙΔΕΚ - Εργα ανά ερευνητή');
$conf->menu($active = basename(__FILE__, '.php'));

$query = "  SELECT DISTINCT `researcher_id`, `full_name`, `organization`
            FROM `projectresearcher_vw` ";
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
        <h1>3.2.1</h1>
        <p>Θα πρέπει ακόμα ο χρήστης να μπορεί να δει δύο όψεις (όψεις του σχεσιακού μοντέλου), μία με έργα/επιχορηγήσεις ανά ερευνητή και μία της επιλογής σας.</p>
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
                <th>Οργανισμός</th>
                <th>Έργα</th>
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
        <td><?php echo $row['organization']; ?></td>
        <td>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Έργα ερευνητή (id: '.$key.')'; ?>" 
                data-content='{"previw":"projectresearcher","edit_id":"<?php echo $key; ?>"}'
                data-failure="Παρουσιάστηκε σγάλμα, παρακαλώ δοκιμάστε ξανά." class="">
                <?php echo $icon->boxArrow; ?>
            </a>
        </td>
    </tr>  <?php
}

function preview($project) {
    //echo '<pre>'; print_r($project);echo'</pre>';
    ?>
    <div class="container"> <?php
        if(!empty($project)) { ?>
            <ol> <?php
                foreach ($project as $key => $title) { ?>
                    <li><?php echo $title;?></li> <?php
                } ?>
            </ol> <?php
        } ?>
    </div> <?php
}
