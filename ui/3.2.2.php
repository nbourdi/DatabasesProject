<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;


// PREVIEW
if(isset($_POST['previw'], $_POST['edit_id']) && $_POST['previw'] == 'eval' && is_numeric($_POST['edit_id'])) {
    $edit_id = $mysqli->real_escape_string($_POST['edit_id']);
    $evaluation = [];
    $query = "		SELECT `rating`, `eval_name`
                    FROM `eval_view`
                    WHERE `project_id` = $edit_id; ";
    $result = $mysqli->query($query);
    while($row = $result->fetch_assoc()) {
        $evaluation[$row['eval_name']] = $row['rating'];
      }
    preview($evaluation);
    //echo $_SERVER['SERVER_ADDR'];
    exit;
}


$conf->header('ΕΛΙΔΕΚ - Αξιολόγησεις των έργων');
$conf->menu($active = basename(__FILE__, '.php'));

$query = "  SELECT DISTINCT `project_id`, `title`, `eval_date`, `abbreviation`
            FROM `eval_view` ";
$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $key = $row['project_id'];
    unset($row['project_id']);
    $data[$key] = $row;
  }
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
                <th>Αξιολόγηση</th>
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
        <td><?php echo $row['title']; ?></td>
        <td><?php echo $row['abbreviation']; ?></td>
        <td>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Αξιολόγηση'; ?>" 
                data-content='{"previw":"eval","edit_id":"<?php echo $key; ?>"}'
                data-failure="Παρουσιάστηκε σφάλμα, παρακαλώ δοκιμάστε ξανά." class="">
                <?php echo $icon->boxArrow; ?>
            </a>
        </td>
    </tr>  <?php
}

function preview($evaluation) {
    //echo '<pre>'; print_r($project);echo'</pre>';
    ?>
    <div class="container"> <?php
        if(!empty($evaluation)) { ?>
            <h3 class="my-4"></h3>
             <?php
                foreach ($evaluation as $key => $rating) { ?>
                    <li><?php echo $rating;?></li> <?php
                } ?>
             <?php
        } ?>
    </div> <?php
}
