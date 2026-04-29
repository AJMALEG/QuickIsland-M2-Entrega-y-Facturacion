
// Js/islas.js
function irAIsla(idIsla) {
    // Guardamos qué isla eligió el cliente para usarla en la siguiente página
    localStorage.setItem('isla_seleccionada_id', idIsla);
    
    // Lo mandamos a la página donde verá los productos (Crea este .html si no lo tienes)
    window.location.href = 'productos_isla.html';
}
