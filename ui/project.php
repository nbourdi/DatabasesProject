<?php
require_once('config.php');
$conf = new Config;
$icon = new Icon;
$mysqli = $conf->mysqli;

// DISPLAY FORM FOR INSERT, UPDATE & DELETE
if(isset($_POST['form'], $_POST['type']) && $_POST['form'] == 'project' && in_array($_POST['type'],['insert','update','delete'])) {
	$type = $mysqli->real_escape_string($_POST['type']);
	$data = [];
	if(isset($_POST['edit_id']) && is_numeric($_POST['edit_id'])) {
		$edit_id = $mysqli->real_escape_string($_POST['edit_id']);
		$query = "	SELECT `p`.`project_id`,`p`.`title`,`p`.`summary`,`p`.`amount`, DATE_FORMAT(`p`.`start_date`,'%d/%m/%Y') `start_date`,DATE_FORMAT(`p`.`end_date`,'%d/%m/%Y') `end_date`,
                    `p`.`program_id`,`p`.`executive_id`,`p`.`executive_name`,`p`.`abbreviation`, `p`.`organization`,`p`.`manager_id`,`p`.`manager`,`p`.`field`,
                    `e`.rating,DATE_FORMAT(`e`.`eval_date`,'%d/%m/%Y')`eval_date`,`e`.`researcher_id` `evaluate_id`
                    FROM `project_view` `p`
                    JOIN `eval_view` `e`
                    ON `p`.`project_id` = `e`.`project_id`
					WHERE `p`.`project_id` = '$edit_id'; ";
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
if(isset($_POST['project'], $_POST['id']) && $_POST['project'] == 'deliverable') {
    $type = isset($_POST['type'])?$mysqli->real_escape_string($_POST['type']):'insert';
    $edit_id = $mysqli->real_escape_string($_POST['id']);
    deliverableInput($type,['project_id'=>$edit_id]);
    exit;
}

// INSERT OR UPDATE OR DELETE TO DB
if(isset($_POST['db']) && in_array($_POST['db'], ['insert','update','delete'])) {
    
	echo '<pre>';print_r($_POST);echo '</pre>';exit;
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

// PREVIEW
if(isset($_POST['previw'], $_POST['edit_id']) && $_POST['previw'] == 'project' && is_numeric($_POST['edit_id'])) {
    $edit_id = $mysqli->real_escape_string($_POST['edit_id']);
    $project = [];
    $query = "	SELECT  `p`.`project_id`,  `p`.`title`,  `p`.`summary`, GROUP_CONCAT(DISTINCT `f`.`field_name`) `field`,
                `pg`.`title` `program`,`e`.rating,DATE_FORMAT(`e`.`eval_date`,'%d/%m/%Y')`eval_date`,`e`.`eval_name`
                FROM `project` `p`
                NATURAL JOIN `FieldProject` `fp`
                JOIN `field` `f`
                ON `fp`.`field_id` = `f`.`field_id`
                JOIN `program` `pg`
                ON `p`.`program_id` = `pg`.`program_id`
                JOIN `eval_view` `e`
                ON `p`.`project_id` = `e`.`project_id`
                WHERE  `p`.`project_id` = $edit_id
                GROUP BY `p`.`project_id`; ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        $project = $result->fetch_assoc();
    }


    $deliverable = [];
    $query = "	SELECT d.deliverable_id, d.summary 
                FROM deliverable d
                INNER JOIN project p ON d.project_id = p.project_id
                WHERE `p`.`project_id` = $edit_id; ";
    //echo $query; exit;
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $deliverable[] = $row;
        }
    }
    preview($project, $deliverable);
    //echo $_SERVER['SERVER_ADDR'];
    exit;
}

// FILTERS
if(isset($_POST['filters']) && $_POST['filters'] == 'change')  {
    $filter = [];
    //echo '<pre>'; print_r($_POST);echo'</pre>';
     if(isset($_POST['filter']['date']['min'], $_POST['filter']['date']['max']) && $conf->isDate($_POST['filter']['date']['min']) && $conf->isDate($_POST['filter']['date']['max'])) {
        $min = $mysqli->real_escape_string($_POST['filter']['date']['min']);
        $max = $mysqli->real_escape_string($_POST['filter']['date']['max']);
        $filter[] = "(`start_date` BETWEEN STR_TO_DATE('$min', '%d/%m/%Y') AND STR_TO_DATE('$max', '%d/%m/%Y') 
                        OR `end_date` BETWEEN STR_TO_DATE('$min', '%d/%m/%Y') AND STR_TO_DATE('$max', '%d/%m/%Y')) ";
    }
     if(isset($_POST['filter']['duration']['min'], $_POST['filter']['duration']['max']) && is_numeric($_POST['filter']['duration']['min']) && is_numeric($_POST['filter']['duration']['max'])) {
        $min = $mysqli->real_escape_string($_POST['filter']['duration']['min']);
        $max = $mysqli->real_escape_string($_POST['filter']['duration']['max']);
        $filter[] = "`duration` BETWEEN $min AND $max";
    }
     if(isset($_POST['filter']['executive']) && is_array($_POST['filter']['executive']) && ctype_digit(implode('',array_keys($_POST['filter']['executive'])))) {
        $executives = implode(',',array_keys($_POST['filter']['executive']));
        if(!empty($_POST['filter']['executive']))
            $filter[] = "`executive_id` IN($executives)";
    }

    $filter = implode(" AND ", $filter);
    $data = dataQuery($filter);
    dataList($data);
    exit;
}

// RESEARCHERS
if(isset($_POST['elementDetails'], $_POST['elementId']) && $_POST['elementDetails'] == 'researchersPerProject' && is_numeric($_POST['elementId'])) {
    $project = $mysqli->real_escape_string($_POST['elementId']);
    $sql = "SELECT CONCAT(`r`.`last_name`, ' ', `r`.`first_name`) `name`
            FROM `WorksOn` `w` 
            NATURAL JOIN `researcher` `r` 
            WHERE `w`.`project_id` = $project
            ORDER BY `r`.`last_name`; ";
    $result = $mysqli->query($sql);
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            echo $row['name'].'<br>';
        }
    }
    exit;
}


$conf->header('ΕΛΙΔΕΚ - Έργα / Επιχορηγήσεις');
$conf->menu($active = basename(__FILE__, '.php'));

$data = dataQuery();

$sql = "SELECT DATE_FORMAT(MIN(`start_date`), '%d/%m/%Y') `min_date`,DATE_FORMAT(MAX(`end_date`), '%d/%m/%Y') `max_date`,
        MIN(`duration`) `min_duration`, MAX(`duration`) `max_duration`
        FROM `project_view`;";
$result = $mysqli->query($sql);
$filter = [];
if ($result->num_rows > 0) {
  $row = $result->fetch_assoc();
    $filter['min_date'] = $row['min_date'];
    $filter['max_date'] = $row['max_date'];
    $filter['min_duration'] = $row['min_duration'];
    $filter['max_duration'] = $row['max_duration'];
}
$sql = "SELECT DISTINCT `executive_id`, `executive_name`
        FROM `project_view` ";
$result = $mysqli->query($sql);
$executive = [];
if ($result->num_rows > 0) {
  while($row = $result->fetch_assoc()) {
    $executive[$row['executive_id']] = $row['executive_name'];
  }
}

//echo '<pre>'; print_r($executive);echo'</pre>';

?>
    <div class="container mt-5">
        <h1>Έργα - Επιχορηγήσεις</h1>
        <p>Έργα (Επιχορηγήσεις) με τα σχετικά δεδομένα τους (τίτλος, περίληψη, ποσό
            χρηματοδότησης/επιχορήγησης, ημερομηνία έναρξης και λήξης, διάρκεια σε χρόνια καθώς και
            τους ερευνητές που εργάζονται για το έργο). Κάθε έργο έχει έναν οργανισμό που το διαχειρίζεται,
            έναν ερευνητή που είναι ο επιστημονικός υπεύθυνος του έργου, ελάχιστη διάρκεια 1 έτος - μέγιστη
            τα 4 έτη και αφορά ένα ή περισσότερα επιστημονικά πεδία. Το έργο ενδέχεται να έχει παραδοτέα
            τα οποία και παραδίδονται σε συγκεκριμένη ημερομηνία. Ένα παραδοτέο έχει τίτλο και περίληψη.
            Το κάθε έργο προκειμένου να χρηματοδοτηθεί έχει αξιολογηθεί από έναν ερευνητή που δεν ανήκει
            στο δυναμικό του οργανισμού που συμμετέχει στην πρόταση. Η αξιολόγηση έχει βαθμό και
            ημερομηνία.</p>
        <p>Όλα τα προγράμματα που είναι διαθέσιμα και όλα τα έργα/επιχορηγήσεις που έχουν
            καταχωριστεί με βάση πολλαπλά κριτήρια, να επιλέξει το έργο που τον ενδιαφέρει και να δει
            τους ερευνητές που εργάζονται σε αυτό. Τα κριτήρια αυτά θα πρέπει να είναι η ημερομηνία, η
            διάρκεια καθώς και το στέλεχος που χειρίζεται τη χρηματοδότηση. Τα κριτήρια αυτά θα πρέπει
            να είναι ανεξάρτητα, να μην απαιτούνται όλα και τα αποτελέσματα που θα βλέπει ο χρήστης
            να ενημερώνονται με κάθε διαφοροποίηση στην επιλογή.</p>
    </div>  <?php

    //----------------------------------- LIST ----------------------------------
?>  
        <div class="container">
            <div class="row mt-4">
                <div class="col-3">
                    <form id="project-filters" action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">
                        <h5>Κριτήρια επιλογής</h5>
                        <div class="daterange-container mb-4 form-group">
                            <label for="usr">Ημερομηνίες:</label>
                            <input type="text" class="form-control daterange" value="" data-start-date="<?php echo $filter['min_date']; ?>" data-end-date="<?php echo $filter['max_date']; ?>" />
                            <input type="hidden" name="filter[date][min]" value="<?php echo $filter['min_date']; ?>" />
                            <input type="hidden" name="filter[date][max]" value="<?php echo $filter['max_date']; ?>" />
                        </div>
                        <div class="range-container mb-4">
                            <input type="hidden" class="min" name="filter[duration][min]" value="<?php echo $filter['min_duration']; ?>" />
                            <input type="hidden" class="max" name="filter[duration][max]" value="<?php echo $filter['max_duration']; ?>" />
                            <div class="display mb-2">Διάρκεια έργου από <span class="min"></span> έως <span class="max"></span> χρόνια</div>
                            <div class="range-input mx-2" data-min="<?php echo $filter['min_duration']; ?>" data-max="<?php echo $filter['max_duration']; ?>" data-step="1"></div>
                        </div>

                        <div class="checkbox-container mb-4">
                            <label>Στέλεχος διαχείρησης έργου</label> <?php
                            foreach ($executive as $id => $name) { ?>
                                <div class="checkbox">
                                    <input id="<?php echo 'executive_'.$id; ?>" type="checkbox" name="<?php echo 'filter[executive]['.$id.']'; ?>" value="0" >
                                    <label for="<?php echo 'executive_'.$id; ?>"><?php echo $name; ?></label>
                                    <span></span>
                                </div>	<?php
                            } ?>
                        </div>
                        <input type='hidden' name='filters' value='change' />
                    </form>

                </div>
                <div class="col-9">
                    <div class="loading">
                        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="200px" height="200px" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid">
                            <rect x="15" y="30" width="10" height="40" fill="#85a2b6">
                            <animate attributeName="opacity" dur="1s" repeatCount="indefinite" calcMode="spline" keyTimes="0;0.5;1" keySplines="0.5 0 0.5 1;0.5 0 0.5 1" values="1;0.2;1" begin="-0.6"></animate>
                            </rect><rect x="35" y="30" width="10" height="40" fill="#bbcedd">
                            <animate attributeName="opacity" dur="1s" repeatCount="indefinite" calcMode="spline" keyTimes="0;0.5;1" keySplines="0.5 0 0.5 1;0.5 0 0.5 1" values="1;0.2;1" begin="-0.4"></animate>
                            </rect><rect x="55" y="30" width="10" height="40" fill="#dce4eb">
                            <animate attributeName="opacity" dur="1s" repeatCount="indefinite" calcMode="spline" keyTimes="0;0.5;1" keySplines="0.5 0 0.5 1;0.5 0 0.5 1" values="1;0.2;1" begin="-0.2"></animate>
                            </rect><rect x="75" y="30" width="10" height="40" fill="#fdfdfd">
                            <animate attributeName="opacity" dur="1s" repeatCount="indefinite" calcMode="spline" keyTimes="0;0.5;1" keySplines="0.5 0 0.5 1;0.5 0 0.5 1" values="1;0.2;1" begin="-1"></animate>
                            </rect>
                        </svg>
                    </div>
                    <div class="filters-table"> <?php
                        dataList($data); ?>
                    </div>
                </div>
            </div>
        </div>    <?php

$conf->footer();

function dataQuery($filter = 1) {
    global $mysqli;
    $sql = "SELECT `project_id`,`title`,`amount`,DATE_FORMAT(`start_date`, '%d/%m/%Y') `start_date`,DATE_FORMAT(`end_date`, '%d/%m/%Y') `end_date`,`duration`,`organization`,`manager`,`executive_name`,`researchers`
        FROM `project_view`
        WHERE $filter ";
    $result = $mysqli->query($sql);
    $data = [];
    if ($result->num_rows > 0) {
        //$count_results = $mysqli->countQuery($subquery, $filters);
        while($row = $result->fetch_assoc()) {
            $id = $row['project_id'];
            unset($row['project_id']);
            $data[$id] = $row;
        }
        return $data;
    }
}

function dataList($data) {
    global $icon;
    if(is_array($data)) { ?>
        <div class="text-end mb-2">
            <?php echo 'Βρέθηκαν '.count($data).' εγγραφές'; ?>
        </div>
        <table class='table table-striped'>
            <thead>
            <tr>
                <th>Τίτλος</th>
                <th>Ποσό</th>
                <th>Διάρκεια</th>
                <th>Πληροφορίες</th>
                <th colspan="1">
                    <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="Προσθήκη έργου" 
                        data-content='{"form":"project","type":"insert"}'> 
                        <?php echo $icon->add; ?>
                    </a>
                </th>
            </tr>
            </thead>    <?php
            foreach ($data as $key => $row) {
                ob_start(); ?>
                    <a class="element-details" data-name="researchersPerProject" data-id="<?php echo $key; ?>" href="javascript:void(0)">
                        <?php echo $row['researchers']; ?>
                    </a> <?php 
                $researchers = ob_get_clean(); ?> 
                <tr>
                    <td><?php echo $row['title']; ?></td>
                    <td><?php echo $row['amount']; ?></td>
                    <td><?php echo $row['start_date'].' '.$row['end_date'].' '.$row['duration'].' χρόν'.($row['duration'] == 1?'ος':'ια'); ?></td>
                    <td>
                        <?php echo 'Οργανισμός:<br>'.$row['organization'].'<br>Yπεύθυνος:<br>'.$row['manager'].'<br>Στέλεχος:<br>'.$row['executive_name'].'<br>Ερευνητές: '.$researchers; ?>
                    </td>
                    <td >
                        <div class="d-flex flex-column">
                            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open mb-4" title="<?php echo 'Προβολή έργου - Παραδοτέα'; ?>" 
                                data-content='{"previw":"project","edit_id":"<?php echo $key; ?>"}'
                                data-failure="Παρουσιάστηκε σφάλμα, παρακαλώ δοκιμάστε ξανά." data-modal-size="lg">
                                <?php echo $icon->boxArrow; ?>
                            </a>
                            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open mb-4" title="<?php echo 'Επεξεργασία έργου'; ?>" 
                                data-content='{"form":"project","type":"update","edit_id":"<?php echo $key; ?>"}' data-success="Η προσθήκη του έργου ολοκληρώθηκε."
                                data-failure="Η προσθήκη απέτυχε, παρακαλώ δοκιμάστε ξανά." data-modal-size="md">
                                <?php echo $icon->edit; ?>
                            </a>
                            <a href="<?php echo $_SERVER['REQUEST_URI']; ?>" class="modal-open" title="<?php echo 'Διαγραφή έργου'; ?>" 
                                data-content='{"form":"project","type":"delete","edit_id":"<?php echo $key; ?>"}' data-modal-size="md">
                                <?php echo $icon->delete; ?>
                            </a>
                        <div>
                    </td>

                </tr>    <?php
            }   ?>
            </tbody>
        </table> <?php
    }
    else {  ?>
        <div class="text-center mt-5">Δεν υπάρχουν αποτελέσματα</div>   <?php
    }
}
// -------------------- FORM --------------------

function form($type, $data = NULL) {
    global $mysqli;
    $save_btn = ['insert'=>'Αποθήκευση', 'update'=>'Αποθήκευση', 'delete'=>'Διαγραφή'];
    $save_btn_disabled = ['insert'=>'', 'update'=>''];
    $message = ['delete' => 'Να γίνει οριστική διαγραφή της εγγραφής;'];
    $success = ['insert'=>'Η προσθήκη των στοιχείων ολοκληρώθηκε.', 'update'=>'Η ενημέρωση των στοιχείων ολοκληρώθηκε.', 'delete'=>'Η διαγραφή ολοκληρώθηκε.'];
    $failure = ['insert'=>'Η προσθήκη απέτυχε, παρακαλώ δοκιμάστε ξανά.', 'update'=>'Η ενημέρωση των στοιχείων απέτυχε, παρακαλώ δοκιμάστε ξανά.', 'delete'=>'Η διαγραφή απέτυχε, παρακαλώ δοκιμάστε ξανά.'];
    $read_only = ['delete'=>'disabled'];

    $project_id = $data['project_id']??0;

    $program = [];
    $query = "  SELECT `program_id`,`title` 
                FROM `program` ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $program[$row['program_id']] = $row['title'];
        }
    }
    $organization = [];
    $query = "  SELECT `abbreviation`,`name` 
                FROM `organization` ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $organization[$row['abbreviation']] = $row['name'];
        }
    }

    $researcher = [];
    $query = "  SELECT `researcher_id`, CONCAT(`last_name`, ' ', `first_name`) `name`
                FROM `researcher` ; ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $researcher[$row['researcher_id']] = $row['name'];
        }
    }
    $executive = [];
    $query = "  SELECT `executive_id`, CONCAT(`last_name`, ' ', `first_name`) `name`
                FROM `executive` ; ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $executive[$row['executive_id']] = $row['name'];
        }
    }
    $field = [];
    $query = "  SELECT `field_id`,`field_name` 
                FROM `field` ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $field[$row['field_id']] = $row['field_name'];
        }
    }
    $workson = [];
    $query = "  SELECT `researcher_id` 
                FROM `WorksOn` 
                WHERE `project_id` = $project_id ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $workson[] = $row['researcher_id'];
        }
    }
    $deliverable = [];
    $query = "  SELECT `project_id`, `deliverable_id` `title`, `summary`
                FROM `deliverable`
                WHERE `project_id` = $project_id ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $deliverable[] = $row;
        }
    }
    $evaluates = [];
    $query = "  SELECT `r`.`researcher_id`,CONCAT(`last_name`, ' ', `first_name`) `name`
                FROM `researcher` `r`
                WHERE `abbreviation` != (SELECT `abbreviation`
                    FROM `project` WHERE `project_id` = $project_id
                ); ";
    $result = $mysqli->query($query);
    if ($result->num_rows > 0) {
        // output data of each row
        while($row = $result->fetch_assoc()) {
            $evaluates[$row['researcher_id']] = $row['name'];
        }
    }
    //echo '<pre>'; print_r($program);echo'</pre>'; ?>
    <form action="<?php echo $_SERVER['REQUEST_URI']; ?>" class="<?php echo $type; ?>" method="POST" data-item="project" data-type="<?php echo $type; ?>">
        <div class="container d-flex flex-column">
            <div class="input-field">
                <input type="text" class="form-control" id="project_title" name="project[title]" required value="<?php echo $data['title'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="project_title" class="form-label">Τίτλος<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <textarea class="form-control" id="project_summary" rows="3" name="project[summary]" required <?php echo $read_only[$type]??''; ?> ><?php echo $data['summary'] ?? ''; ?></textarea>
                <label for="project_summary" class="form-label">Περίληψη<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <input type="text" class="form-control" id="project_amount" name="project[amount]" required value="<?php echo $data['amount'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?> >
                <label for="project_amount" class="form-label">Ποσό<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <input type="text" id="project_start_date" class="form-control datepicker calendar" name="project[start_date]" required value="<?php echo $data['start_date'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?>>
                <label for="project_start_date" class="form-label">Έναρξη<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field">
                <input type="text" id="project_end_date" class="form-control datepicker calendar" name="project[end_date]" required value="<?php echo $data['end_date'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?>>
                <label for="project_end_date" class="form-label">Λήξη<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field" >
                <select class="selectpicker select-program form-control" name="project[program_id]" id="project-program_id" title="Χωρίς επιλογή" required required <?php echo $read_only[$type]??''; ?> >	<?php
                    foreach($program as $id => $name) {	?>
                        <option value="<?php echo $id; ?>" <?php echo isset($data['program_id']) && $data['program_id'] == $id ? 'selected' : '';?> >
                            <?php echo $name; ?>
                        </option>	<?php
                    }	?>
				</select>
                <label for="project-manager" class="form-label">Πρόγραμμα χρηματοδότησης<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field" >
                <select class="selectpicker select-organization form-control" name="project[organization]" id="project_organization" title="Χωρίς επιλογή" required data-live-search="true" <?php echo $read_only[$type]??''; ?> >	<?php
                    foreach($organization as $abbreviation => $name) {	?>
                        <option value="<?php echo $abbreviation; ?>" <?php echo isset($data['abbreviation']) && $data['abbreviation'] == $abbreviation ? 'selected' : '';?> >
                            <?php echo $name; ?>
                        </option>	<?php
                    }	?>
				</select>
                <label for="researcher_organization" class="form-label">Οργανισμός διαχείρισης<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field" >
                <select class="selectpicker select-manager form-control" name="project[manager]" id="project-manager" title="Χωρίς επιλογή" required required data-live-search="true" <?php echo $read_only[$type]??''; ?> >	<?php
                    foreach($researcher as $id => $name) {	?>
                        <option value="<?php echo $id; ?>" <?php echo isset($data['manager_id']) && $data['manager_id'] == $id ? 'selected' : '';?> >
                            <?php echo $name; ?>
                        </option>	<?php
                    }	?>
				</select>
                <label for="project-manager" class="form-label">Επιστημονικός υπεύθυνος<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field" >
                <select class="selectpicker select-executive form-control" name="project[executive]" id="project_executive" title="Χωρίς επιλογή" required required data-live-search="true" <?php echo $read_only[$type]??''; ?> >	<?php
                    foreach($executive as $id => $name) {	?>
                        <option value="<?php echo $id; ?>" <?php echo isset($data['executive_id']) && $data['executive_id'] == $id ? 'selected' : '';?> >
                            <?php echo $name; ?>
                        </option>	<?php
                    }	?>
				</select>
                <label for="project_executive" class="form-label">Στέλεχος διαχείρισης<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field" >
                <select class="selectpicker select-filed form-control" multiple name="project[field]" id="project_field" title="Χωρίς επιλογή" required <?php echo $read_only[$type]??''; ?> >	<?php
                    foreach($field as $id => $name) {	?>
                        <option value="<?php echo $id; ?>" <?php echo isset($data['field']) && in_array($id, explode(',',$data['field'])) ? 'selected' : '';?> >
                            <?php echo $name; ?>
                        </option>	<?php
                    }	?>
				</select>
                <label for="project_field" class="form-label">Επιστημονικά πεδία<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
            <div class="input-field" >
                <select class="selectpicker select-researcher form-control" multiple data-live-search="true" name="project[researcher]" id="project_researcher" title="Χωρίς επιλογή" required <?php echo $read_only[$type]??''; ?> >	<?php
                    foreach($researcher as $id => $name) {	?>
                        <option value="<?php echo $id; ?>" <?php echo in_array($id, $workson) ? 'selected' : '';?> >
                            <?php echo $name; ?>
                        </option>	<?php
                    }	?>
				</select>
                <label for="project_researcher" class="form-label">Ερευνητές<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div> <?php
            if(!empty($deliverable)) {
                foreach ($deliverable as $row) {
                    deliverableInput($type, $row );
                }
            } ?>
            <a href="javascript:void(0)" class="btn btn-light add-deliverable mb-3" title="<?php echo 'Προσθήκη παραδοτέου (id: '.($project_id??'').')'; ?>" 
                data-project="deliverable" data-id="<?php echo $project_id??''; ?>" >
                Προσθήκη παραδοτέου
            </a>
            <div class="deliverable-group border mb-3 px-4 py-2">
                <h6>Αξιολόγηση</h6>
                <div class="d-flex flex-row mb-3">
                    <div class="btn-group btn-group-toggle program-rating my-0 me-4" data-toggle="buttons">
                        <label class="<?php echo 'btn radio-btn'.(@$data['rating']=='A'?' active':''); ?>" for="program_rating_a">
                            <input <?php echo @$data['rating']=='A'?'checked':''; ?> type="radio" name="evaluates[rating]" id="program_rating_a" value="uni"> Α
                        </label>
                        <label class="<?php echo 'btn radio-btn'.(@$data['rating']=='B'?' active':''); ?>" for="program_rating_b">
                            <input <?php echo @$data['rating']=='B'?'checked':''; ?> type="radio" name="evaluates[rating]" id="program_rating_b" value="co"> Β
                        </label>
                    </div>
                    <div class="input-field ps-0 w-100 my-0">
                        <input type="text" id="project_start_date" class="form-control datepicker calendar" name="project[start_date]" required value="<?php echo $data['eval_date'] ?? ''; ?>" <?php echo $read_only[$type]??''; ?>>
                        <label for="project_start_date" class="form-label">Ημερομηνία<span class="text-danger">&nbsp;*</span></label>
                        <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
                    </div>
                </div>
                <div class="input-field" >
                    <select class="selectpicker select-evaluate form-control" name="project[evaluate]" id="project-evaluate" title="Χωρίς επιλογή" required required data-live-search="true" <?php echo $read_only[$type]??''; ?> >	<?php
                        foreach($evaluates as $id => $name) {	?>
                            <option value="<?php echo $id; ?>" <?php echo isset($data['evaluate_id']) && $data['evaluate_id'] == $id ? 'selected' : '';?> >
                                <?php echo $name; ?>
                            </option>	<?php
                        }	?>
                    </select>
                    <label for="project-evaluate" class="form-label">Αξιολογητής<span class="text-danger">&nbsp;*</span></label>
                    <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
                </div>
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
        <input type="hidden" name="edit_id" value="<?php echo $data['project_id'] ?? NULL; ?>" />
    </form>	<?php
}
function deliverableInput($type, $row = NULL) {
    global $icon;
    $rand = str_shuffle(time().rand(1000,9999));
    $read_only = ['delete'=>'disabled']; ?>
        <div class="deliverable-group border mb-3 px-4 py-2">
            <h6>Παραδοτέο</h6>
            <div class="input-field input-group ps-0 w-100">
                <input type="text" class="form-control" id="organization_phone" name="deliverable[<?php echo $rand; ?>][deliverable_id]" required value="<?php echo $row['title']??''; ?>" <?php echo @$read_only[$type]??''; ?> >
                <label for="organization_phone" class="form-label">Τίτλος<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
                <button class="btn btn-outline-secondary remove-deliverable" type="button" data-project="deliverable">
                    <?php echo $icon->delete; ?>
                </button>
            </div>
            <div class="input-field ps-0 w-100">
                <textarea class="form-control" id="project_summary" rows="3" name="deliverable[<?php echo $rand; ?>][summary]" required <?php echo $read_only[$type]??''; ?> ><?php echo $row['summary']??''; ?></textarea>
                <label for="project_summary" class="form-label">Περίληψη<span class="text-danger">&nbsp;*</span></label>
                <span class="error is-required">Το πεδίο είναι υποχρεωτικό</span>
            </div>
        </div> <?php
}

function preview($project,$deliverable) {
    //echo '<pre>'; print_r($project);print_r($deliverable);echo'</pre>'; ?>
    <div class="container">
        <div class="w-100 d-flex justify-content-between mb-2">
            <span class="badge bg-info text-dark">
                <?php echo $project['program']; ?>
            </span>
            <span class="badge bg-warning text-dark">
                <?php echo 'Βαθμός: '.$project['rating'].' '.$project['eval_date'].' Αξιολογητής: '.$project['eval_name']; ?>
            </span>
        </div>
        <h4><?php echo $project['title']; ?></h4>
        <div class="mb-2"> <?php
            foreach (explode(',',$project['field']) as $field) { ?>
                <span class="badge bg-secondary">
                    <?php echo $field.'<br>'; ?>
                </span>  <?php
            } ?>
        </div>
        <p><?php echo $project['summary']; ?></p>   <?php
        if(!empty($deliverable)) { ?>
            <h4 class="my-4">Παραδοτέα</h4> <?php
            foreach ($deliverable as $key => $row) { ?>
                <h5><?php echo $row['deliverable_id'];?></h5>
                <p><?php echo $row['summary'];?></p> <?php
            }
        } ?>
    </div> <?php
}
