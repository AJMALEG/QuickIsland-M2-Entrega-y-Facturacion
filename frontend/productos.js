
document.addEventListener('DOMContentLoaded', async () => {
    const params = new URLSearchParams(window.location.search);
    const idIsla = params.get('isla') || localStorage.getItem('isla_seleccionada_id');
    const contenedor = document.getElementById('listaProductos');

    try {
        const response = await fetch(`Php/get_productos_cliente.php?id_isla=${idIsla}`);
        const data = await response.json();

        contenedor.innerHTML = "";
        data.forEach(prod => {
            const stockActual = parseInt(prod.stock);
            const agotado = stockActual <= 0;

            contenedor.innerHTML += `
                <div class="card-bakery">
                    <h3>${prod.nombre_producto}</h3>
                    <div class="precio">$${parseFloat(prod.precio).toFixed(2)}</div>
                    <p style="font-size:0.7rem;">Stock disponible: <b>${stockActual}</b></p>
                    <button class="${agotado ? 'btn-agotado' : 'btn-agregar'}" 
                        ${agotado ? 'disabled' : ''}
                        onclick="agregarCarrito(${prod.id_producto}, '${prod.nombre_producto}', ${prod.precio}, ${idIsla}, ${stockActual})">
                        ${agotado ? 'Sin Stock' : 'Añadir al Carrito'}
                    </button>
                </div>
            `;
        });
    } catch (e) { console.error(e); }
});

function agregarCarrito(id, nombre, precio, isla, stockMax) {
    let carrito = JSON.parse(localStorage.getItem('qi_carrito')) || [];
    let item = carrito.find(i => i.id_producto === id);

    if (item) {
        if (item.cantidad < stockMax) item.cantidad++;
        else return alert("No hay más piezas en stock.");
    } else {
        carrito.push({ id_producto: id, nombre, precio, id_isla: isla, cantidad: 1 });
    }

    localStorage.setItem('qi_carrito', JSON.stringify(carrito));
    alert("¡Añadido!");
}
