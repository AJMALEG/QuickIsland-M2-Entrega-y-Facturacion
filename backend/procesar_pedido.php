
<?php
header('Content-Type: application/json');
include('db_config.php');

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['id_cliente'])) {
    echo json_encode(['success' => false, 'message' => 'Datos incompletos']);
    exit;
}

$idCliente = $data['id_cliente'];
$items = $data['items'];
$idIsla = $items[0]['id_isla'];

// Calcular total
$total = 0;
foreach($items as $item) { $total += ($item['precio'] * $item['cantidad']); }

// INICIO DE TRANSACCIÓN PARA SEGURIDAD DE STOCK
pg_query($dbconn, "BEGIN");

try {
    // 1. Insertar Cabecera del Pedido
    $qP = "INSERT INTO pedido (id_cliente, id_isla, estado_pedido, total) 
           VALUES ($1, $2, 'En espera', $3) RETURNING id_pedido";
    $resP = pg_query_params($dbconn, $qP, array($idCliente, $idIsla, $total));
    $idPedido = pg_fetch_assoc($resP)['id_pedido'];

    // 2. Detalle + Restar Stock
    foreach($items as $prod) {
        // A. Insertar Detalle
        $qD = "INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario) 
               VALUES ($1, $2, $3, $4)";
        pg_query_params($dbconn, $qD, array($idPedido, $prod['id_producto'], $prod['cantidad'], $prod['precio']));

        // B. DESCUENTO DE STOCK (La parte que faltaba)
        $qS = "UPDATE inventario SET stock = stock - $1 
               WHERE id_producto = $2 AND id_isla = $3";
        pg_query_params($dbconn, $qS, array($prod['cantidad'], $prod['id_producto'], $idIsla));
    }

    pg_query($dbconn, "COMMIT");
    echo json_encode(['success' => true, 'folio' => $idPedido]);

} catch (Exception $e) {
    pg_query($dbconn, "ROLLBACK");
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
pg_close($dbconn);
?>
