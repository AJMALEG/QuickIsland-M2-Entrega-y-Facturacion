
async function eliminarProducto(idProducto, forzar = false) {
    // Verificación de seguridad en el cliente
    if (!idProducto || isNaN(idProducto)) {
        alert("ID de producto no válido.");
        return;
    }

    try {
        // Llamada al PHP usando GET con los parámetros id y forzar
        const response = await fetch(`Php/eliminar_producto.php?id=${idProducto}&forzar=${forzar ? 1 : 0}`);
        
        // Verificamos si la respuesta es un JSON válido
        const texto = await response.text();
        let resultado;
        try {
            resultado = JSON.parse(texto);
        } catch (e) {
            console.error("Respuesta no es JSON:", texto);
            throw new Error("Respuesta del servidor no válida");
        }

        if (resultado.success) {
            alert("✅ Producto eliminado exitosamente.");
            location.reload(); // Recarga para actualizar las tablas
        } else {
            // Manejo del error de Stock enviado por el Trigger de PostgreSQL
            if (resultado.error && resultado.error.includes("BLOQUEO_STOCK")) {
                const stockRestante = resultado.stock || "existente";
                
                const confirmar = confirm(
                    `⚠️ ADVERTENCIA DE INVENTARIO\n\n` +
                    `Todavía quedan ${stockRestante} unidades en stock de este producto.\n\n` +
                    `¿Estás seguro de que deseas eliminarlo permanentemente de todas las islas?`
                );

                if (confirmar) {
                    // Reintento con forzar = true
                    eliminarProducto(idProducto, true);
                }
            } else {
                alert("❌ Error: " + (resultado.error || "No se pudo eliminar el producto"));
            }
        }
    } catch (error) {
        console.error("Error en la operación:", error);
        alert("❌ Error de comunicación con el sistema.");
    }
}
