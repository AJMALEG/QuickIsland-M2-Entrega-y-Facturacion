
<?php
//actualizar stock manual
header('Content-Type: application/json');
include('db_config.php');

$data = json_decode(file_get_contents('php://input'), true);

$idProd = $data['id_producto'] ?? 0;
$cantidad = $data['nueva_cantidad'] ?? 0;
$idIsla = $data['isla_id'] ?? 0;

if ($idProd > 0 && $cantidad > 0) {
    // ACTUALIZAMOS LA TABLA PRINCIPAL
    // Usamos stock = stock + $1 para que se sume a lo que ya hay (o a 0)
    $query = "UPDATE inventario SET stock = stock + $1 WHERE id_producto = $2 AND id_isla = $3";
    $result = pg_query_params($dbconn, $query, array($cantidad, $idProd, $idIsla));

    if ($result) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'message' => pg_last_error($dbconn)]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Datos inválidos']);
}

pg_close($dbconn);
?>
