
<?php
// 1. Iniciar sesión PRIMERO que todo para que db_config la reconozca
session_start(); 

header('Content-Type: application/json');

// 2. Incluimos la configuración (que ya lleva el SET myapp.user con el nombre real)
include('db_config.php'); 

// 3. Captura de datos del formulario
$nombre  = $_POST['nombre'] ?? '';
$precio  = $_POST['precio'] ?? 0;
$stock   = $_POST['stock'] ?? 0;
$desc    = $_POST['descripcion'] ?? 'Sin descripción'; 
$id_isla = $_POST['id_isla'] ?? 0;

// Validaciones básicas
if (empty($nombre) || $id_isla == 0) {
    echo json_encode(["success" => false, "message" => "Datos incompletos"]);
    exit;
}

// 4. Iniciar Transacción para asegurar integridad
pg_query($dbconn, "BEGIN");

try {
    // Insertar en la tabla maestra de PRODUCTO
    $sql1 = "INSERT INTO producto (nombre_producto, precio, descripcion, categoria) 
             VALUES ($1, $2, $3, 'General') RETURNING id_producto";
    $res1 = pg_query_params($dbconn, $sql1, array($nombre, $precio, $desc));

    if (!$res1) throw new Exception("Error al insertar en la tabla producto");

    $row = pg_fetch_assoc($res1);
    $nuevo_id_prod = $row['id_producto'];

    // Insertar en la tabla general de INVENTARIO vinculando a la isla
    // (Esto disparará el trigger que reparte a la tabla inventario_quecas, etc.)
    $sql2 = "INSERT INTO inventario (id_producto, id_isla, stock) VALUES ($1, $2, $3)";
    $res2 = pg_query_params($dbconn, $sql2, array($nuevo_id_prod, $id_isla, $stock));

    if (!$res2) throw new Exception("Error al insertar en la tabla inventario");

    // Si todo salió bien, guardamos cambios
    pg_query($dbconn, "COMMIT");
    echo json_encode(["success" => true]);

} catch (Exception $e) {
    // Si algo falla, deshacemos todo
    pg_query($dbconn, "ROLLBACK");
    echo json_encode(["success" => false, "message" => $e->getMessage()]);
}

pg_close($dbconn);
?>
