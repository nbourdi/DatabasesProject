<?php
require_once('icon.php');

class Config {

	public function __construct() {
		// display errors
		ini_set('display_errors', '1');
		ini_set('display_startup_errors', '1');
		error_reporting(E_ALL);
		$this->config = $config = parse_ini_file("connection.ini");
        $servername = $config['servername'];
        $username = $config['username'];
        $password = $config['password'];

		$database = "elidek";
		// Create connection
		$mysqli = new mysqli($servername, $username, $password, $database);
		$mysqli->set_charset("utf8");
		// Check connection
		if ($mysqli->connect_error) {
		  die("Connection failed: " . $mysqli->connect_error);
		}
		$this->mysqli = $mysqli;
	}
	
	public function __destruct() {
		$this->mysqli->close();
	}

	// ----------------- PAGE SETUP -----------------
	
	public function header($title, $body_class='') {	?>
		<!DOCTYPE html>
		<html lang="el">
			<head>
				<title><?php echo $title; ?></title>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <link rel="stylesheet" href="files/libraries.css" >
                <link rel="stylesheet" href="style.css" >
			</head>
			<body class="<?php echo $body_class; ?>" data-url="<?php echo $_SERVER['REQUEST_URI']; ?>">	<?php
	}
	
	public function footer() {	?>
			<!-- Modal -->
			<div class="modal fade" id="modal" tabindex="-1" aria-hidden="true">
				<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content">
					<div class="modal-header">
					<h5 class="modal-title">...</h5>
					<button type="button" class="btn-close modal-close" title="close modal"></button>
					</div>
					<div class="modal-body">
					...
					</div>
				</div>
				</div>
			</div>
			<script src="files/libraries.js"></script>
			<script src="scripts.js"></script>
		</body>
	</html>	<?php
	}

    public function menu($active = NULL) {   ?>
        <nav class="navbar navbar-expand-lg navbar-light bg-light">
            <div class="container-fluid">
                <a class="navbar-brand" href="./">
                    <img src="files/elidek_logo.png" />
                </a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNavDropdown" aria-controls="navbarNavDropdown" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNavDropdown">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link <?php echo $active == 'project'?'active':'';?>" href="project.php">Έργα</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link <?php echo $active == 'program'?'active':'';?>" href="program.php">Προγράμματα</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link <?php echo $active == 'researcher'?'active':'';?>" href="researcher.php">Ερευνητές</a>
                    </li>
					<li class="nav-item">
                        <a class="nav-link <?php echo $active == 'executives'?'active':'';?>" href="executives.php">Στελέχη</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link <?php echo $active == 'organization'?'active':'';?>" href="organization.php">Οργανισμοί</a>
                    </li>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="navbarDropdownMenuLink" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                        Σεγκεντωτικά στοιχεία
                    </a>
                    <ul class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
                        <li><a class="dropdown-item" href="#">3.1 - Προγράμματα & έργα</a></li>
                        <li><a class="dropdown-item" href="3.2.php">3.2.1 - Έργα ανά ερευνητή</a></li>
						<li><a class="dropdown-item" href="3.2.2.php">3.2.2 - Αξιολογήση ανά έργο</a></li>
                        <li><a class="dropdown-item" href="3.3.php">3.3 - Ενδιαφέρον ερευνητικό πεδίο</a></li>
                        <li><a class="dropdown-item" href="3.4.php">3.4 - Πιο ενεργοί οργανισμοί</a></li>
                        <li><a class="dropdown-item" href="3.5.php">3.5 - Κορυφαία διεπιστημονικά ζεύγη</a></li>
                        <li><a class="dropdown-item" href="3.6.php">3.6 - Νέοι ερευνητές</a></li>
                        <li><a class="dropdown-item" href="3.7.php">3.7 - Στελέχη - χρηματοδότηση</a></li>
                        <li><a class="dropdown-item" href="3.8.php">3.8 - Ερευνητές σε έργα χωρίς παραδοτέα</a></li>
                    </ul>
                    </li>
                </ul>
                </div>
            </div>
        </nav>  <?php
    }

	function isDate($value) { // DD/MM/YYYY
		return preg_match("/^(0[1-9]|[1-2][0-9]|3[0-1])\/(0[1-9]|1[0-2])\/[0-9]{4}$/",$value);
	}
	function dateToDb($value) {
		return (DateTime::createFromFormat('d/m/Y', $value))->format('Y-m-d');
	}

}