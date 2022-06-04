<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;


// DISPLAY FORM FOR INSERT, UPDATE & DELETE
if(isset($_POST['form'], $_POST['type']) && $_POST['form'] == 'organization' && in_array($_POST['type'],['insert','update','delete'])) {
	$type = $mysqli->real_escape_string($_POST['type']);
	$organization = [];
    $phone = [];
	if(isset($_POST['edit_id']) && $_POST['edit_id'] != '' ) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$query = "	SELECT `abbreviation`, `name`, `type`, `budget`,`street`,`street_number`, `postal_code`, `city`
					FROM `organization`
					WHERE `abbreviation` = '$edit_id' ";
		//echo $query; exit;
		$result = $mysqli->query($query);
		if ($result->num_rows > 0) {
		  $organization = $result->fetch_assoc();
		}
        //echo '<pre>';print_r($organization);echo '</pre>';
        $sql = "SELECT `phone`
        FROM `organization__phone`
        WHERE `abbreviation` = '$edit_id'; ";
        $result = $mysqli->query($sql);
        if ($result->num_rows > 0) {
            while($row = $result->fetch_assoc()) {
                $phone[] = $row['phone'];
            }
        }
	}
	form($type,$organization,$phone);
	exit;
}

// DISPLAY POPOVER WITH BADGET
if(isset($_POST['elementDetails'], $_POST['elementId']) && $_POST['elementDetails'] == 'budget' && $_POST['elementId'] != '') {
    $abbreviation = $mysqli->real_escape_string($_POST['elementId']);
    $budgetType = [
        'uni' => ['ministry'=>'Υπ. Παιδείας'],
        'inst' => ['private'=>'Ιδιωτικές δράσεις','ministry'=>'Υπ. Παιδείας'],
        'co' => ['capital'=>'Ίδια κεφάλαια']
    ];
    $sql = "SELECT `type`, `budget`
            FROM `organization`
            WHERE `abbreviation` = '$abbreviation'; ";
    $result = $mysqli->query($sql);
    if ($result->num_rows > 0) {
       $row = $result->fetch_assoc();
       $budgetArray = json_decode($row['budget']);
       foreach ($budgetArray as $key => $value) {
            echo $budgetType[$row['type']][$key].': '.$value.'<br>';
       }
    }
    exit;
}

// DISPLAY POPOVER PHONES
if(isset($_POST['elementDetails'], $_POST['elementId']) && $_POST['elementDetails'] == 'phone' && $_POST['elementId'] != '') {
    $abbreviation = $mysqli->real_escape_string($_POST['elementId']);
    $sql = "SELECT `phone`
            FROM `organization__phone`
            WHERE `abbreviation` = '$abbreviation'; ";
    $result = $mysqli->query($sql);
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            echo $row['phone'].'<br>';
        }
    }
    exit;
}


if(isset($_POST['organization'], $_POST['abbreviation']) && in_array($_POST['organization'], ['uni','inst','co']) && $_POST['abbreviation'] != '') {
    $type = isset($_POST['type'])?$mysqli->real_escape_string($_POST['type']):'insert';
    $orgType = $mysqli->real_escape_string($_POST['organization']);
    budgetInput($type,$orgType);
    exit;
}

if(isset($_POST['organization'], $_POST['abbreviation']) && $_POST['organization'] == 'phone') {
    $type = isset($_POST['type'])?$mysqli->real_escape_string($_POST['type']):'insert';
    $abbreviation = $mysqli->real_escape_string($_POST['abbreviation']);
    phoneInput($type,$abbreviation);
    exit;
}

// INSERT OR UPDATE OR DELETE TO DB
if(isset($_POST['db']) && in_array($_POST['db'], ['insert','update','delete'])) {
    if(isset($_POST['organization']['budget']))
        $_POST['organization']['budget'] = json_encode($_POST['organization']['budget']);
    
	//echo '<pre>';print_r($_POST);echo '</pre>';//exit;
	$action = $mysqli->real_escape_string($_POST['db']);
	$query = '';
	$abbreviation = NULL;
    //START TRANSACTION
    $mysqli->autocommit(FALSE);
	if($action == 'insert' && isset($_POST['organization']) && is_array($_POST['organization'])) {
		$abbreviation = $_POST['organization']['abbreviation'];
        $columns = [];
		$values = [];
		foreach($_POST['organization'] as $column => $value) {
			$column = $mysqli->real_escape_string($column);
			if(in_array($column, ['abbreviation','name','type','budget','street','street_number','postal_code','city'])) {
				$columns[] = "`$column`";
                if($conf->isDate($value))
                    $value = $conf->dateToDb($value);
				$value = $mysqli->real_escape_string($value);
				$values[] = "'$value'";
			}
		}
		$columns = implode(',',$columns);
		$values = implode(',',$values);
		$query = "INSERT INTO `organization` ($columns) VALUES ($values);";
	}
	else if($action == 'update' && isset($_POST['edit_id'], $_POST['organization']) && $_POST['edit_id'] && is_array($_POST['organization'])) {
		$abbreviation = $mysqli->real_escape_string($_POST['edit_id']);
		$fields = [];
		foreach($_POST['organization'] as $column => $value) {
			$column = $mysqli->real_escape_string($column);
			if(in_array($column, ['abbreviation','name','type','budget','street','street_number','postal_code','city'])) {
                if($conf->isDate($value))
                    $value = $conf->dateToDb($value);
				$value = $mysqli->real_escape_string($value);
				$fields[] = "`$column` = '$value'";
			}
		}
		$fields = implode(',',$fields);
		$query = "	UPDATE `organization`
                    SET $fields
                    WHERE `abbreviation` = '$abbreviation' ";
	}
	else if($action == 'delete' && isset($_POST['edit_id']) && $_POST['edit_id']) {
		$abbreviation = $mysqli->real_escape_string($_POST['edit_id']);
		$fields = [];
		$query = "	DELETE FROM `organization`
					WHERE `abbreviation` = '$abbreviation' ";
	}
    $condition = $mysqli->query($query);

    if(isset($_POST['organization__phone']) && in_array($_POST['db'], ['insert','update'])) {
        $queryDeletePhone = "	DELETE FROM `organization__phone`
                                WHERE `abbreviation` = '$abbreviation' ";
        $condition = $condition && $mysqli->query($queryDeletePhone);
        $values = [];
        foreach($_POST['organization__phone'] as $phone) {
            if($value) {
                $value = $mysqli->real_escape_string($value);
                $values[] = "('$phone', '$abbreviation')";
            }
        }
        $values = implode(',',$values);
        $queryInsertPhone = "INSERT INTO `organization__phone` (`phone`,`abbreviation`) VALUES $values;";
        $condition = $condition && $mysqli->query($queryInsertPhone);
    }

	//echo '###'.$query;exit;
	if($condition && $mysqli->commit())
		echo json_encode(['status'=>'success', 'action'=>$action, 'edit_id'=>$abbreviation ]);
	else {
        $mysqli->rollback();
		echo json_encode(['status'=>'failure']);
    }
	//echo '<pre>';print_r($fields);echo '</pre>';
    //END TRANSACTION
    $mysqli->autocommit(TRUE);
	exit;
}

// UPDATE LIST AFTER INSERT, UPDATE & DELETE
if(isset($_POST['list'], $_POST['type']) && $_POST['list'] == 'organization' && in_array($_POST['type'],['insert','update','delete'])) {
    //echo '<pre>';print_r($_POST);echo '</pre>';exit;
    $type = $mysqli->real_escape_string($_POST['type']);
	$data = [];
    $abbreviation = NULL;
	if(isset($_POST['edit_id']) && $_POST['edit_id']!= '') {
		$abbreviation = $mysqli->real_escape_string($_POST['edit_id']);
        $query = "  SELECT `abbreviation`, `name`, `type`, `budget`, CONCAT_WS(' ',`street`,`street_number`, `postal_code`, `city`) `address` 
                    FROM `organization`
					WHERE `abbreviation` = '$abbreviation' ";
		//echo $query; exit;
		$result = $mysqli->query($query);
		if ($result->num_rows > 0) {
		  $data = $result->fetch_assoc();
		}
	}
	listItem($abbreviation, $data);
	exit;
}


$conf->header('ΕΛΙΔΕΚ - Οργανισμοί');
$conf->menu($active = basename(__FILE__, '.php'));

$query = "  SELECT `abbreviation`, `name`, `type`, `budget`, CONCAT_WS(' ',`street`,`street_number`, `postal_code`, `city`) `address` 
            FROM `organization`  ";
$result = $mysqli->query($query);
$data = [];
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
      $key = $row['abbreviation'];
      unset($row['abbreviation']);
    $data[$key] = $row;
  }
  //echo '<pre>';print_r($data);echo '</pre>';//exit;
}

?>
    <div class="container mt-5">
        <h1>Οργανισμοί</h1>
        <p>Οργανισμούς που διαχειρίζονται έργα (δεν υπάρχει περιορισμός στον αριθμό των έργων που θα
            συμμετέχει ένας οργανισμός). Για κάθε οργανισμό θα πρέπει να υπάρχει συντομογραφία, όνομα,
            Ταχυδρομική Διεύθυνση (με επιμέρους στοιχεία Οδός, Αριθμός , ΤΚ, Πόλη) και περισσότερα από
            ένα τηλέφωνα επικοινωνίας. Οι οργανισμοί ανήκουν σε μια από τις 3 κατηγορίες: α) Πανεπιστήμια
            τα οποία έχουν ξεχωριστό προϋπολογισμό από το Υπ. Παιδείας, β) Ερευνητικά Κέντρα που έχουν
            ξεχωριστό προϋπολογισμό από το Υπ. Παιδείας και προϋπολογισμό από ιδιωτικές δράσεις και γ)
            εταιρίες που έχουν ίδια κεφάλαια.</p>
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
                <th></th>
                <th>Όνομα</th>
                <th>Κατηγορία</th>
                <th>Προϋπολογισμός</th>
                <th>Διεύθυνση</th>
                <th></th>
                <th></th>
                <th colspan="1">
                    <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="Προσθήκη οργανισμού" 
                        data-content='{"form":"organization","type":"insert"}'> 
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
    global $icon;
    $type = [
        'uni' => 'Πανεπιστήμιο',
        'inst' => 'Ερευνητικό Κέντρο',
        'co' => 'Εταιρία'
    ];
    //echo '<pre>';print_r($row);echo '</pre>';
    $budget = 0;
    $budgetArray = json_decode($row['budget']);
    array_walk($budgetArray, function($value) use(&$budget){$budget += (int)$value;});
    //$budget = json_decode($row['budget']);
    ?>
    <tr>
        <td><?php echo $key; ?></td>
        <td><?php echo $row['name']; ?></td>
        <td><?php echo $type[$row['type']]; ?></td>
        <td>
            <a class="element-details" data-name="budget" data-id="<?php echo $key; ?>" href="javascript:void(0)">
                <?php echo $budget; ?>
            </a>
        </td>
        <td><?php echo $row['address']; ?></td>
        <td>
            <a class="element-details" data-name="phone" data-id="<?php echo $key; ?>" href="javascript:void(0)">
                <?php echo $icon->phone; ?>
            </a>
        </td>
        <td>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Επεξεργασία οργανισμού (id: '.$key.')'; ?>" 
                data-content='{"form":"organization","type":"update","edit_id":"<?php echo $key; ?>"}' data-success="Η προσθήκη του οργανισμού ολοκληρώθηκε."
                data-failure="Η προσθήκη απέτυχε, παρακαλώ δοκιμάστε ξανά." class="">
                <?php echo $icon->edit; ?>
            </a>
        </td>
        <td>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Διαγραφή οργανισμού (id: '.$key.')'; ?>" 
                data-content='{"form":"organization","type":"delete","edit_id":"<?php echo $key; ?>"}'>
                <?php echo $icon->delete; ?>
            </a>
        </td> 
    </tr>  <?php
}


function form($type, $data = NULL, $phone=NULL) {
    $save_btn = ['insert'=>'Αποθήκευση', 'update'=>'Αποθήκευση', 'delete'=>'Διαγραφή'];
    $save_btn_disabled = ['insert'=>'', 'update'=>''];
    $message = ['delete' => 'Να γίνει οριστική διαγραφή της εγγραφής;'];
    $success = ['insert'=>'Η προσθήκη των στοιχείων ολοκληρώθηκε.', 'update'=>'Η ενημέρωση των στοιχείων ολοκληρώθηκε.', 'delete'=>'Η διαγραφή ολοκληρώθηκε.'];
    $failure = ['insert'=>'Η προσθήκη απέτυχε, παρακαλώ δοκιμάστε ξανά.', 'update'=>'Η ενημέρωση των στοιχείων απέτυχε, παρακαλώ δοκιμάστε ξανά.', 'delete'=>'Η διαγραφή απέτυχε, παρακαλώ δοκιμάστε ξανά.'];
    $read_only = ['delete'=>'disabled']; ?>
    <form action="<?php echo $_SERVER['REQUEST_URI']; ?>" class="<?php echo $type; ?>" data-type="<?php echo $type; ?>" method="POST" data-item="organization">
        <div class="container d-flex flex-column">
            <div class="input-field">
                <input type="text" class="form-control" id="organization_abbreviation" name="organization[abbreviation]" required value="<?php echo $data['abbreviation'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_abbreviation" class="form-label">Συντομογραφία<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <input type="text" class="form-control" id="organization_name" name="organization[name]" required value="<?php echo $data['name'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_name" class="form-label">Όνομα<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="btn-group btn-group-toggle organization-type ml-4" data-toggle="buttons">
                <label class="<?php echo 'btn radio-btn'.(@$data['type']=='uni'?' active':''); ?>" for="organization_type_uni">
                    <input <?php echo @$data['type']=='uni'?'checked':''; ?> type="radio" name="organization[type]" id="organization_type_uni" value="uni"> Πανεπιστήμιο
                </label>
                <label class="<?php echo 'btn radio-btn'.(@$data['type']=='inst'?' active':''); ?>" for="organization_type_inst">
                    <input <?php echo @$data['type']=='inst'?'checked':''; ?> type="radio" name="organization[type]" id="organization_type_inst" value="inst"> Ερευνητικό Κέντρο
                </label>
                <label class="<?php echo 'btn radio-btn'.(@$data['type']=='co'?' active':''); ?>" for="organization_type_co">
                    <input <?php echo @$data['type']=='co'?'checked':''; ?> type="radio" name="organization[type]" id="organization_type_co" value="co"> Εταιρία
                </label>
            </div> <?php
            if(isset($data['type']) && !empty($data['type'])) {
                budgetInput($type,$data['type'],$data['budget']);
            } ?>
            <div class="input-field">
                <input type="text" class="form-control" id="organization_street" name="organization[street]" value="<?php echo $data['street'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_street" class="form-label">Οδός</label>
            </div>
            <div class="input-field">
                <input type="text" class="form-control" id="organization_street_number" name="organization[street_number]" value="<?php echo $data['street_number'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_street_number" class="form-label">Αριθμός</label>
            </div>
            <div class="input-field">
                <input type="text" class="form-control" id="organization_postal_code" name="organization[postal_code]" required value="<?php echo $data['postal_code'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_postal_code" class="form-label">Ταχυδρομικός κώδικας<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <input type="text" class="form-control" id="organization_city" name="organization[city]" required value="<?php echo $data['city'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_city" class="form-label">Πόλη<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div> <?php
            if(!empty($phone)) {
                foreach ($phone as $value) {
                    phoneInput($type, $data['abbreviation'], $value );
                }
            } ?>
            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="btn btn-light add-phone" title="<?php echo 'Προσθήκη τηλεφώνου (id: '.($data['abbreviation']??'').')'; ?>" 
                data-organization="phone" data-abbreviation="<?php echo $data['abbreviation']??''; ?>" >
                Προσθήκη τηλεφώνου
            </a>

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
        <input type="hidden" name="edit_id" value="<?php echo $data['abbreviation'] ?? NULL; ?>" />
    </form>	<?php
}

function budgetInput($type, $orgType,$budget = NULL) {
    $budget = $budget?json_decode($budget,true):NULL;
    $read_only = ['delete'=>'disabled'];
    //echo '<pre>';print_r($budget);echo '</pre>';
    switch ($orgType) {
        case 'uni': ?>
            <div class="input-field">
                <input type="text" class="form-control organization-budget" id="organization_uni_budget_ministry" name="organization[budget][ministry]" required value="<?php echo $budget['ministry']??''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_uni_budget_ministry" class="form-label">Προϋπολογισμός Υπ. Παιδείας<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div> <?php
            break;
        case 'inst': ?>
            <div class="input-field">
                <input type="text" class="form-control organization-budget" id="organization_inst_budget_ministry" name="organization[budget][ministry]" required value="<?php echo $budget['ministry'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_inst_budget_ministry" class="form-label">Προϋπολογισμός Υπ. Παιδείας<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <input type="text" class="form-control organization-budget" id="organization_inst_budget_private" name="organization[budget][private]" required value="<?php echo $budget['private'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_inst_budget_private" class="form-label">Προϋπολογισμός ιδιωτικών δράσεων<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div> <?php
            break;
        case 'co': ?>
            <div class="input-field">
                <input type="text" class="form-control organization-budget" id="organization_co_budget_capital" name="organization[budget][capital]" required value="<?php echo $budget['capital'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="organization_co_budget_capital" class="form-label">Ίδια κεφάλαια<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div> <?php
            break;
    
    }
}

function phoneInput($type, $abbreviation, $phone = NULL) {
    global $icon;
    $read_only = ['delete'=>'disabled']; ?>
    <div class="input-field input-group">
        <input type="text" class="form-control" id="organization_phone" name="organization__phone[]" required value="<?php echo $phone; ?>" <?php echo @$read_only[$type]??''; ?> >
        <label for="organization_phone" class="form-label">Τηλέφωνο<span class="text-danger">&nbsp;*</span></label>
        <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
        <button class="btn btn-outline-secondary remove-phone" type="button" data-organization="phone">
            <?php echo $icon->delete; ?>
        </button>
    </div> <?php
}
