<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;


// DISPLAY FORM FOR INSERT, UPDATE & DELETE
if(isset($_POST['form'], $_POST['type']) && $_POST['form'] == 'researcher' && in_array($_POST['type'],['insert','update','delete'])) {
	$type = $mysqli->real_escape_string($_POST['type']);
	$data = [];
	if(isset($_POST['edit_id']) && is_numeric($_POST['edit_id'])) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$query = "	SELECT `researcher_id`, `first_name`, `last_name`, `gender`, DATE_FORMAT(`birth_date`, '%d/%m/%Y') `birth_date`, `abbreviation`, DATE_FORMAT(`since_date`, '%d/%m/%Y') `since_date`
					FROM `researcher`
					WHERE `researcher_id` = '$edit_id' ";
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
	//echo '<pre>';print_r($_POST['researcher']);echo '</pre>';//exit;
	$action = $mysqli->real_escape_string($_POST['db']);
	$query = "";
	$edit_id = 0;
	if($action == 'insert' && isset($_POST['researcher']) && is_array($_POST['researcher'])) {
		$columns = [];
		$values = [];
		foreach($_POST['researcher'] as $column => $value) {
			$column = $mysqli->real_escape_string($column);
			if(in_array($column, ['first_name','last_name','gender','birth_date','abbreviation','since_date'])) {
				$columns[] = "`$column`";
                if($conf->isDate($value))
                    $value = $conf->dateToDb($value);
				$value = $mysqli->real_escape_string($value);
				$values[] = "'$value'";
			}
		}
        //echo '<pre>';print_r($columns);print_r($values);echo '</pre>';exit;
		$columns = implode(',',$columns);
		$values = implode(',',$values);
		$query = "INSERT INTO `researcher` ($columns) VALUES ($values);";
	}
	else if($action == 'update' && isset($_POST['edit_id'], $_POST['researcher']) && $_POST['edit_id'] && is_array($_POST['researcher'])) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$fields = [];
		foreach($_POST['researcher'] as $column => $value) {
			$column = $mysqli->real_escape_string($column);
			if(in_array($column, ['first_name','last_name','gender','birth_date',`abbreviation`,`since_date`])) {
                if($conf->isDate($value))
                    $value = $conf->dateToDb($value);
				$value = $mysqli->real_escape_string($value);
				$fields[] = "`$column` = '$value'";
			}
		}
		$fields = implode(',',$fields);
		$query = "	UPDATE `researcher`
			SET $fields
			WHERE `researcher_id` = $edit_id ";
	}
	else if($action == 'delete' && isset($_POST['edit_id']) && $_POST['edit_id']) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$fields = [];
		$query = "	DELETE FROM `researcher`
					WHERE `researcher_id` = $edit_id ";
	}
	//echo '###<br>'.$query;exit;
	if($mysqli->query($query))
		echo json_encode(['status'=>'success', 'action'=>$action, 'edit_id'=>$edit_id ? $edit_id : $mysqli->insert_id ]);
	else
		echo json_encode(['status'=>'failure']);
	//echo '<pre>';print_r($fields);echo '</pre>';
	exit;
}

// UPDATE LIST AFTER INSERT, UPDATE & DELETE
if(isset($_POST['list'], $_POST['type']) && $_POST['list'] == 'researcher' && in_array($_POST['type'],['insert','update','delete'])) {
    //echo '<pre>';print_r($_POST);echo '</pre>';//exit;
    $type = $mysqli->real_escape_string($_POST['type']);
	$data = [];
	if(isset($_POST['edit_id']) && is_numeric($_POST['edit_id'])) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$query = "	SELECT `researcher_id`, `first_name`, `last_name`, IF(`gender` = 'male', 'Α', 'Γ') `gender`,  DATE_FORMAT(`birth_date`, '%d/%m/%Y') `birth_date`
                    FROM `researcher`
					WHERE `researcher_id` = '$edit_id' ";
		//echo $query; exit;
		$result = $mysqli->query($query);
		if ($result->num_rows > 0) {
		  $data = $result->fetch_assoc();
		}
	}
	listItem($edit_id, $data);
	exit;
}



$conf->header('ΕΛΙΔΕΚ - Ερευνητές');
$conf->menu($active = basename(__FILE__, '.php'));

$query = "SELECT `researcher_id`, `first_name`, `last_name`, IF(`gender` = 'male', 'Α', 'Γ') `gender`,  DATE_FORMAT(`birth_date`, '%d/%m/%Y') `birth_date`
        FROM `researcher` ";
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
        <h1>Ερευνητές</h1>
        <p>Ερευνητές που εργάζονται σε έργα (δεν υπάρχει περιορισμός στον αριθμό των έργων που θα
            συμμετέχει ένας ερευνητής). Ο κάθε ερευνητής εργάζεται σε ένα (και μόνο) οργανισμό από κάποια
            ημερομηνία. Για κάθε ερευνητή, καταχωρίζονται όνομα, επώνυμο, φύλο και ημερομηνία γέννησης.</p>
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
                <th>Επώνυμο</th>
                <th>Όνομα</th>
                <th>Φύλο</th>
                <th>Ημ. γέννησης</th>
                <th></th>
                <th colspan="1">
                    <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="Προσθήκη ερευνητή" 
                        data-content='{"form":"researcher","type":"insert"}'> 
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
        <td><?php echo $row['last_name']; ?></td>
        <td><?php echo $row['first_name']; ?></td>
        <td><?php echo $row['gender']; ?></td>
        <td><?php echo $row['birth_date']; ?></td>
        <td>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Επεξεργασία ερευνητή (id: '.$key.')'; ?>" 
                data-content='{"form":"researcher","type":"update","edit_id":"<?php echo $key; ?>"}' data-success="Η προσθήκη του ερευνητή ολοκληρώθηκε."
                data-failure="Η προσθήκη απέτυχε, παρακαλώ δοκιμάστε ξανά." class="">
                <?php echo $icon->edit; ?>
            </a>
        </td>
        <td>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Διαγραφή ερευνητή (id: '.$key.')'; ?>" 
                data-content='{"form":"researcher","type":"delete","edit_id":"<?php echo $key; ?>"}'>
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
    <form action="<?php echo $_SERVER['REQUEST_URI']; ?>" class="<?php echo $type; ?>" method="POST" data-item="researcher">
        <div class="container d-flex flex-column">
            <div class="input-field">
                <input type="text" class="form-control" id="researcher_firstname" name="researcher[first_name]" required value="<?php echo $data['first_name'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="researcher_firstname" class="form-label">Όνομα<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <input type="text" class="form-control" id="researcher_lastname" name="researcher[last_name]" required value="<?php echo $data['last_name'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="researcher_lastname" class="form-label">Επώνυμο<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="btn-group btn-group-toggle ml-4" data-toggle="buttons">
                <label class="<?php echo 'btn radio-btn'.(@$data['gender']=='male'?' active':''); ?>" for="researcher_gender_male">
                    <input <?php echo @$data['gender']=='male'?'checked':''; ?> type="radio" name="researcher[gender]" id="researcher_gender_male" value="male"> Άντρας
                </label>
                <label class="<?php echo 'btn radio-btn'.(@$data['gender']=='female'?' active':''); ?>" for="researcher_gender_female">
                    <input <?php echo @$data['gender']=='female'?'checked':''; ?> type="radio" name="researcher[gender]" id="researcher_gender_female" value="female"> Γυναίκα
                </label>
            </div>
            <div class="input-field">
                <input type="text" class="form-control datepicker birthday" id="researcher_birth_date" name="researcher[birth_date]" required value="<?php echo $data['birth_date'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="researcher_birth_date" class="form-label">Ημερομηνία γέννησης<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field" >
                <select class="selectpicker select-organization form-control" name="researcher[abbreviation]" id="researcher_organization" title="Χωρίς επιλογή" required >	<?php
                    foreach($organization as $abbreviation => $name) {	?>
                        <option value="<?php echo $abbreviation; ?>" <?php echo isset($data['abbreviation']) && $data['abbreviation'] == $abbreviation ? 'selected' : '';?> >
                            <?php echo $name; ?>
                        </option>	<?php
                    }	?>
				</select>
                <label for="researcher_organization" class="form-label">Οργανισμός<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>

            <div class="input-field">
                <input type="text" id="researcher_since_date" class="form-control datepicker since-date" name="researcher[since_date]" required value="<?php echo $data['since_date'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?>>
                <label for="researcher_since_date" class="form-label">Εργάζεται από<span class="text-danger">&nbsp;*</span></label>
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
        <input type="hidden" name="edit_id" value="<?php echo $data['researcher_id'] ?? NULL; ?>" />
    </form>	<?php
}
