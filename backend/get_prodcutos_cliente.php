
<?php
header('Content-Type: application/json');
include('db_config.php');

$id_isla = $_GET['id_isla'] ?? 0;

if ($id_isla == 0) {
    echo json_encode([]);
    exit;
}

/**
 * CONSULTA MAESTRA:
 * 1. Tomamos los datos del producto (nombre, precio, id).
 * 2. Tomamos el stock real de la tabla 'inventario' (la tabla principal).
 * 3. Filtramos para que NO aparezcan productos con stock 0 o menos.
 */
$query = "SELECT 
            p.id_producto, 
            p.nombre_producto as nombre, 
            p.precio, 
            inv.stock 
          FROM inventario inv
          JOIN producto p ON inv.id_producto = p.id_producto
          WHERE inv.id_isla = $1 AND inv.stock > 0
          ORDER BY p.nombre_producto ASC";

$result = pg_query_params($dbconn, $query, array($id_isla));

if ($result) {
    $productos = pg_fetch_all($result);
    // Si no hay nada, mandamos un array vacío [] en lugar de false
    echo json_encode($productos ? $productos : []);
} else {
    echo json_encode([]);
}

pg_close($dbconn);
?>
