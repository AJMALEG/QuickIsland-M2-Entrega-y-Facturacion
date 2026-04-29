
document.addEventListener('DOMContentLoaded', renderizarCarrito);

function renderizarCarrito() {
    const lista = document.getElementById('lista-pedido');
    const carrito = JSON.parse(localStorage.getItem('qi_carrito')) || [];
    const totalTxt = document.getElementById('gran-total');

    if (carrito.length === 0) {
        lista.innerHTML = "<h3 style='text-align:center; opacity:0.5;'>Tu carrito está vacío...</h3>";
        totalTxt.innerText = "Total: $0.00";
        return;
    }

    let totalGlobal = 0;
    lista.innerHTML = "";

    carrito.forEach((item, index) => {
        const subtotal = item.precio * item.cantidad;
        totalGlobal += subtotal;

        lista.innerHTML += `
            <div class="item-carrito">
                <div class="item-info">
                    <h4>${item.nombre}</h4>
                    <span>Isla: ${item.id_isla}</span>
                </div>
                <div class="qty-controls">
                    <button class="qty-btn" onclick="cambiarCant(${index}, -1)">-</button>
                    <span>${item.cantidad}</span>
                    <button class="qty-btn" onclick="cambiarCant(${index}, 1)">+</button>
                </div>
                <div style="width: 100px; text-align: right; font-weight: bold;">
                    $${subtotal.toFixed(2)}
                </div>
                <button onclick="eliminarItem(${index})" style="background:none; border:none; color:#e74c3c; cursor:pointer; margin-left:15px;">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `;
    });

    totalTxt.innerText = `Total: $${totalGlobal.toFixed(2)}`;
}

function cambiarCant(index, delta) {
    let carrito = JSON.parse(localStorage.getItem('qi_carrito'));
    carrito[index].cantidad += delta;

    if (carrito[index].cantidad <= 0) {
        carrito.splice(index, 1);
    }

    localStorage.setItem('qi_carrito', JSON.stringify(carrito));
    renderizarCarrito();
}

function eliminarItem(index) {
    let carrito = JSON.parse(localStorage.getItem('qi_carrito'));
    carrito.splice(index, 1);
    localStorage.setItem('qi_carrito', JSON.stringify(carrito));
    renderizarCarrito();
}

function procesarVenta() {
    const carrito = JSON.parse(localStorage.getItem('qi_carrito')) || [];
    
    if (carrito.length === 0) {
        alert("El carrito está vacío.");
        return;
    }

    // En lugar de enviar al PHP aquí, vamos directo a la pantalla de pago
    // El "Procesando" ya no se quedará trabado porque es un salto de página
    window.location.href = 'pago.html';
}

