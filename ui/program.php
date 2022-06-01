<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;


// DISPLAY FORM FOR INSERT, UPDATE & DELETE
if(isset($_POST['form'], $_POST['type']) && $_POST['form'] == 'program' && in_array($_POST['type'],['insert','update','delete'])) {
	$type = $mysqli->real_escape_string($_POST['type']);
	$data = [];
	if(isset($_POST['edit_id']) && is_numeric($_POST['edit_id'])) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$query = "	SELECT `program_id`, `title`, `department`
                    FROM `program`
					WHERE `program_id` = '$edit_id' ";
		//echo $query; exit;
		$result = $mysqli->query($query);
		if ($result->num_rows > 0) {
		  $data = $result->fetch_assoc();
		}
	}
	form($type, $data);
	//echo $_SERVER['SERVER_ADDR'];
	exit;
}

// INSERT OR UPDATE OR DELETE TO DB
if(isset($_POST['db']) && in_array($_POST['db'], ['insert','update','delete'])) {
	//echo '<pre>';print_r($_POST);echo '</pre>';exit;
	$action = $mysqli->real_escape_string($_POST['db']);
	$query = '';
	$edit_id = 0;
	if($action == 'insert' && isset($_POST['program']) && is_array($_POST['program'])) {
		$columns = [];
		$values = [];
		foreach($_POST['program'] as $column => $value) {
			$column = $mysqli->real_escape_string($column);
			if(in_array($column, ['title','department'])) {
				$columns[] = "`$column`";
                if($conf->isDate($value))
                    $value = $conf->dateToDb($value);
				$value = $mysqli->real_escape_string($value);
				$values[] = "'$value'";
			}
		}
		$columns = implode(',',$columns);
		$values = implode(',',$values);
		$query = "INSERT INTO `program` ($columns) VALUES ($values);";
	}
	else if($action == 'update' && isset($_POST['edit_id'], $_POST['program']) && $_POST['edit_id'] && is_array($_POST['program'])) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$fields = [];
		foreach($_POST['program'] as $column => $value) {
			$column = $mysqli->real_escape_string($column);
			if(in_array($column, ['title','department'])) {
                if($conf->isDate($value))
                    $value = $conf->dateToDb($value);
				$value = $mysqli->real_escape_string($value);
				$fields[] = "`$column` = '$value'";
			}
		}
		$fields = implode(',',$fields);
		$query = "	UPDATE `program`
                    SET $fields
                    WHERE `program_id` = $edit_id ";
	}
	else if($action == 'delete' && isset($_POST['edit_id']) && $_POST['edit_id']) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$fields = [];
		$query = "	DELETE FROM `program`
					WHERE `program_id` = $edit_id ";
	}
	//echo '###'.$query;exit;
	if($mysqli->query($query))
		echo json_encode(['status'=>'success', 'action'=>$action, 'edit_id'=>$edit_id ? $edit_id : $mysqli->insert_id ]);
	else
		echo json_encode(['status'=>'failure']);
	//echo '<pre>';print_r($fields);echo '</pre>';
	exit;
}

// UPDATE LIST AFTER INSERT, UPDATE & DELETE
if(isset($_POST['list'], $_POST['type']) && $_POST['list'] == 'program' && in_array($_POST['type'],['insert','update','delete'])) {
    //echo '<pre>';print_r($_POST);echo '</pre>';//exit;
    $type = $mysqli->real_escape_string($_POST['type']);
	$data = [];
	if(isset($_POST['edit_id']) && is_numeric($_POST['edit_id'])) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$query = "	SELECT `program_id`, `title`, `department`
                    FROM `program`
					WHERE `program_id` = '$edit_id' ";
		//echo $query; exit;
		$result = $mysqli->query($query);
		if ($result->num_rows > 0) {
		  $data = $result->fetch_assoc();
		}
	}
	listItem($edit_id, $data);
	exit;
}



$conf->header('ΕΛΙΔΕΚ - Προγράμματα');
$conf->menu($active = basename(__FILE__, '.php'));

$query = "  SELECT `program_id`, `title`, `department`
            FROM `program`; ";
$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $key = $row['program_id'];
    unset($row['program_id']);
    $data[$key] = $row;
  }
}

?>
    <div class="container mt-5">
        <h1>Προγράμματα</h1>
        <p>Προγράμματα που υλοποιούνται από το ΕΛ.ΙΔ.Ε.Κ. και χορηγούν χρηματοδοτήσεις στα έργα.
            Το κάθε έργο λαμβάνει χρηματοδότηση από ένα πρόγραμμα. Το κάθε πρόγραμμα ανήκει σε μια διεύθυνση του ΕΛ.ΙΔ.Ε.Κ..</p>
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
                <th>Διεύθυνση</th>
                <th></th>
                <th colspan="1">
                    <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="Προσθήκη προγράμματος" 
                        data-content='{"form":"program","type":"insert"}'> 
                        <?php echo $icon->add; ?>
                    </a>
                </th>
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
        <td><?php echo $row['department']; ?></td>
        <td>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Επεξεργασία προγράμματος (id: '.$key.')'; ?>" 
                data-content='{"form":"program","type":"update","edit_id":"<?php echo $key; ?>"}' data-success="Η προσθήκη του προγράμματος ολοκληρώθηκε."
                data-failure="Η προσθήκη απέτυχε, παρακαλώ δοκιμάστε ξανά." class="">
                <?php echo $icon->edit; ?>
            </a>
        </td>
        <td>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Διαγραφή προγράμματος (id: '.$key.')'; ?>" 
                data-content='{"form":"program","type":"delete","edit_id":"<?php echo $key; ?>"}'>
                <?php echo $icon->delete; ?>
            </a>
        </td> 
    </tr>  <?php
}

function form($type, $data = NULL) {
    global $mysqli;
    $save_btn = ['insert'=>'Αποθήκευση', 'update'=>'Αποθήκευση', 'delete'=>'Διαγραφή'];
    $save_btn_disabled = ['insert'=>'disabled', 'update'=>'disabled'];
    $message = ['delete' => 'Να γίνει οριστική διαγραφή της εγγραφής;'];
    $success = ['insert'=>'Η προσθήκη των στοιχείων ολοκληρώθηκε.', 'update'=>'Η ενημέρωση των στοιχείων ολοκληρώθηκε.', 'delete'=>'Η διαγραφή ολοκληρώθηκε.'];
    $failure = ['insert'=>'Η προσθήκη απέτυχε, παρακαλώ δοκιμάστε ξανά.', 'update'=>'Η ενημέρωση των στοιχείων απέτυχε, παρακαλώ δοκιμάστε ξανά.', 'delete'=>'Η διαγραφή απέτυχε, παρακαλώ δοκιμάστε ξανά.'];
    $read_only = ['delete'=>'disabled'];
    $query = "SELECT `abbreviation`,`name` FROM `organization` ";
    $result = $mysqli->query($query);
    $organization = [];
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $organization[$row['abbreviation']] = $row['name'];
        }
    } ?>
    <form action="<?php echo $_SERVER['REQUEST_URI']; ?>" class="<?php echo $type; ?>" method="POST" data-item="program">
        <div class="container d-flex flex-column">
            <div class="input-field">
                <input type="text" class="form-control" id="program_title" name="program[title]" required value="<?php echo $data['title'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="program_title" class="form-label">Τίτλος<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <input type="text" class="form-control" id="program_department" name="program[department]" required value="<?php echo $data['department'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="program_department" class="form-label">Διεύθυνση<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <?php
            if(isset($message[$type])) { ?>
                <p>	<?php
                    echo $message[$type]; ?>
                </p> <?php
            }	?>
            <div class="ms-auto mt-4">
                <button type="button" class="btn btn-light modal-close me-2">Ακύρωση</button>
                <button type="submit" class="btn btn-dark ms-auto" data-success="<?php echo $success[$type]; ?>" data-failure="<?php echo $failure[$type]; ?>" <?php echo $save_btn_disabled[$type] ?? ''; ?> >
                    <?php echo $save_btn[$type]; ?>
                </button>
            </div>
        </div>
        <input type="hidden" name="db" value="<?php echo $type; ?>" />
        <input type="hidden" name="edit_id" value="<?php echo $data['program_id'] ?? NULL; ?>" />
    </form>	<?php
}
