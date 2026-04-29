
<?php
// Php/db_config.php

// Aseguramos que las cookies se guarden en la raíz del proyecto
session_set_cookie_params(0, '/'); 

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$host = "localhost";
$port = "5432";
$dbname = "cafeteriadb";
$user = "postgres";
$password = "ajmagshaka"; 

$strConn = "host=$host port=$port dbname=$dbname user=$user password=$password";
$dbconn = pg_connect($strConn);

if(!$dbconn) {
    die("Error de conexión: " . pg_last_error());
}

// OBTENER USUARIO: Priorizamos el nombre guardado en login_valida.php
$usuario_app = 'Sistema_Sin_Login';

if (isset($_SESSION['quicksiland_user'])) {
    $usuario_app = $_SESSION['quicksiland_user'];
}

// ESTA ES LA CLAVE: Usamos comillas dobles para el parámetro y simples para el valor
pg_query($dbconn, "SET \"myapp.user\" = '$usuario_app'");
?>
