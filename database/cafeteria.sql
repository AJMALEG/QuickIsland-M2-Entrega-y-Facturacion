--
-- PostgreSQL database dump
--

\restrict kWJqOiIsMzD0TOZxYBqCjTyVrJsJsbcbu8HUulWWJeOshVmzLj1ThzfR17G238T

-- Dumped from database version 16.13 (Ubuntu 16.13-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.13 (Ubuntu 16.13-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: crear_tabla_inventario(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.crear_tabla_inventario(nombre_tabla text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE 'CREATE TABLE ' || nombre_tabla || ' (
        id_inventario SERIAL PRIMARY KEY,
        id_isla INT,
        id_producto INT,
        nombre_producto VARCHAR(100),
        detalle_producto TEXT,
        precio DECIMAL(10,2),
        stock INT
    )';
END;
$$;


ALTER FUNCTION public.crear_tabla_inventario(nombre_tabla text) OWNER TO postgres;

--
-- Name: distribuir_nuevo_producto(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.distribuir_nuevo_producto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tabla_destino TEXT;
    v_stock_inicial INT := 10;
BEGIN
    -- Usamos el id_isla que viene directamente en el nuevo producto
    IF NEW.id_isla IS NOT NULL THEN
        v_tabla_destino := CASE NEW.id_isla
            WHEN 1 THEN 'inventario_tiendita'
            WHEN 2 THEN 'inventario_deli'
            WHEN 3 THEN 'inventario_gorditas'
            WHEN 4 THEN 'inventario_churros'
            WHEN 5 THEN 'inventario_quecas'
            WHEN 6 THEN 'inventario_comida'
            WHEN 7 THEN 'inventario_aguas'
            WHEN 8 THEN 'inventario_pizza'
        END;

        -- 1. Insertar en la tabla específica de la isla con todos los datos
        EXECUTE format('INSERT INTO %I (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) 
                        VALUES (%L, %L, %L, %L, %L, %L)', 
                        v_tabla_destino, NEW.id_isla, NEW.id_producto, NEW.nombre_producto, NEW.descripcion, NEW.precio, v_stock_inicial);
        
        -- 2. Asegurar que también exista en la tabla inventario general
        INSERT INTO inventario (id_isla, id_producto, stock) 
        VALUES (NEW.id_isla, NEW.id_producto, v_stock_inicial)
        ON CONFLICT (id_producto) DO UPDATE SET stock = v_stock_inicial;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.distribuir_nuevo_producto() OWNER TO postgres;

--
-- Name: distribuir_stock_a_isla(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.distribuir_stock_a_isla() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nombre VARCHAR;
    v_desc TEXT;
    v_precio NUMERIC;
BEGIN
    SELECT nombre_producto, descripcion, precio INTO v_nombre, v_desc, v_precio
    FROM producto WHERE id_producto = NEW.id_producto;

    CASE NEW.id_isla
        WHEN 1 THEN INSERT INTO inventario_tiendita (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) VALUES (NEW.id_isla, NEW.id_producto, v_nombre, v_desc, v_precio, NEW.stock);
        WHEN 2 THEN INSERT INTO inventario_deli (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) VALUES (NEW.id_isla, NEW.id_producto, v_nombre, v_desc, v_precio, NEW.stock);
        WHEN 3 THEN INSERT INTO inventario_gorditas (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) VALUES (NEW.id_isla, NEW.id_producto, v_nombre, v_desc, v_precio, NEW.stock);
        WHEN 4 THEN INSERT INTO inventario_churros (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) VALUES (NEW.id_isla, NEW.id_producto, v_nombre, v_desc, v_precio, NEW.stock);
        WHEN 5 THEN INSERT INTO inventario_quecas (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) VALUES (NEW.id_isla, NEW.id_producto, v_nombre, v_desc, v_precio, NEW.stock);
        WHEN 6 THEN INSERT INTO inventario_comida (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) VALUES (NEW.id_isla, NEW.id_producto, v_nombre, v_desc, v_precio, NEW.stock);
        WHEN 7 THEN INSERT INTO inventario_aguas (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) VALUES (NEW.id_isla, NEW.id_producto, v_nombre, v_desc, v_precio, NEW.stock);
        WHEN 8 THEN INSERT INTO inventario_pizza (id_isla, id_producto, nombre_producto, detalle_producto, precio, stock) VALUES (NEW.id_isla, NEW.id_producto, v_nombre, v_desc, v_precio, NEW.stock);
    END CASE;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.distribuir_stock_a_isla() OWNER TO postgres;

--
-- Name: eliminar_producto_de_isla(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.eliminar_producto_de_isla() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tabla_destino TEXT;
BEGIN
    -- Determinamos la tabla según el ID de la isla que tenía el registro borrado
    v_tabla_destino := CASE OLD.id_isla
        WHEN 1 THEN 'inventario_tiendita'
        WHEN 2 THEN 'inventario_deli'
        WHEN 3 THEN 'inventario_gorditas'
        WHEN 4 THEN 'inventario_churros'
        WHEN 5 THEN 'inventario_quecas'
        WHEN 6 THEN 'inventario_comida'
        WHEN 7 THEN 'inventario_aguas'
        WHEN 8 THEN 'inventario_pizza'
    END;

    -- Ejecutamos el borrado dinámico en la tabla de la isla
    IF v_tabla_destino IS NOT NULL THEN
        EXECUTE format('DELETE FROM %I WHERE id_producto = %L', v_tabla_destino, OLD.id_producto);
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.eliminar_producto_de_isla() OWNER TO postgres;

--
-- Name: funcion_auditar_cambios(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.funcion_auditar_cambios() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO auditoria_cambios(nombre_tabla, operacion, datos_anteriores)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD));
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO auditoria_cambios(nombre_tabla, operacion, datos_anteriores, datos_nuevos)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO auditoria_cambios(nombre_tabla, operacion, datos_nuevos)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.funcion_auditar_cambios() OWNER TO postgres;

--
-- Name: sincronizar_stock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sincronizar_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Si es la isla 5 (Quecas), actualiza su tabla específica
    IF (NEW.id_isla = 5) THEN
        UPDATE inventario_quecas SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
    END IF;
    -- Puedes agregar más IF para otras islas aquí
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.sincronizar_stock() OWNER TO postgres;

--
-- Name: sincronizar_subislas(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sincronizar_subislas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    CASE NEW.id_isla
        WHEN 1 THEN UPDATE inventario_tiendita SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
        WHEN 2 THEN UPDATE inventario_deli      SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
        WHEN 3 THEN UPDATE inventario_gorditas  SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
        WHEN 4 THEN UPDATE inventario_churros   SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
        WHEN 5 THEN UPDATE inventario_quecas    SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
        WHEN 6 THEN UPDATE inventario_comida    SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
        WHEN 7 THEN UPDATE inventario_aguas     SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
        WHEN 8 THEN UPDATE inventario_pizza     SET stock = NEW.stock WHERE id_producto = NEW.id_producto;
    END CASE;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.sincronizar_subislas() OWNER TO postgres;

--
-- Name: validar_borrado_stock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validar_borrado_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_forzar_borrado TEXT;
BEGIN
    -- Intentamos obtener la variable de sesión de forma segura
    BEGIN
        SHOW app.forzar_borrado INTO v_forzar_borrado;
    EXCEPTION WHEN OTHERS THEN
        v_forzar_borrado := 'off';
    END;

    -- Si el stock > 0 Y NO se ha forzado el borrado, lanzamos el error
    IF OLD.stock > 0 AND v_forzar_borrado <> 'on' THEN
        RAISE EXCEPTION 'BLOQUEO_STOCK: %', OLD.stock;
    END IF;

    -- LÍNEA CRÍTICA: Permite que el proceso de borrado termine con éxito
    RETURN OLD;
END;
$$;


ALTER FUNCTION public.validar_borrado_stock() OWNER TO postgres;

--
-- Name: validar_precios_y_datos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validar_precios_y_datos() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NEW.precio <= 0 THEN
        RAISE EXCEPTION 'Error: El precio del producto (%) debe ser mayor a $0.00', NEW.nombre_producto;
    END IF;
    NEW.nombre_producto = INITCAP(NEW.nombre_producto);
    RETURN NEW;
END;
$_$;


ALTER FUNCTION public.validar_precios_y_datos() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auditoria_cambios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditoria_cambios (
    id_auditoria integer NOT NULL,
    nombre_tabla character varying(50),
    operacion character varying(20),
    usuario_db character varying(50) DEFAULT CURRENT_USER,
    fecha_cambio timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    datos_anteriores jsonb,
    datos_nuevos jsonb
);


ALTER TABLE public.auditoria_cambios OWNER TO postgres;

--
-- Name: auditoria_cambios_id_auditoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auditoria_cambios_id_auditoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auditoria_cambios_id_auditoria_seq OWNER TO postgres;

--
-- Name: auditoria_cambios_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auditoria_cambios_id_auditoria_seq OWNED BY public.auditoria_cambios.id_auditoria;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id_cliente integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    rfc character varying(13),
    email character varying(150),
    telefono character varying(15),
    fecha_registro date DEFAULT CURRENT_DATE,
    rol character varying(20),
    contrasena character varying(100),
    id_isla_asignada integer,
    numero_control character varying(20)
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_id_cliente_seq OWNER TO postgres;

--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cliente_id_cliente_seq OWNED BY public.usuarios.id_cliente;


--
-- Name: detalle_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_pedido (
    id_detalle integer NOT NULL,
    id_pedido integer,
    id_producto integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) NOT NULL
);


ALTER TABLE public.detalle_pedido OWNER TO postgres;

--
-- Name: detalle_pedido_id_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.detalle_pedido_id_detalle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.detalle_pedido_id_detalle_seq OWNER TO postgres;

--
-- Name: detalle_pedido_id_detalle_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.detalle_pedido_id_detalle_seq OWNED BY public.detalle_pedido.id_detalle;


--
-- Name: factura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factura (
    id_factura integer NOT NULL,
    folio_fiscal character varying(50),
    fecha_emision timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    subtotal numeric(10,2),
    total_neto numeric(10,2),
    metodo_pago character varying(50),
    id_pedido integer
);


ALTER TABLE public.factura OWNER TO postgres;

--
-- Name: factura_id_factura_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.factura_id_factura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.factura_id_factura_seq OWNER TO postgres;

--
-- Name: factura_id_factura_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.factura_id_factura_seq OWNED BY public.factura.id_factura;


--
-- Name: inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    stock integer DEFAULT 0
);


ALTER TABLE public.inventario OWNER TO postgres;

--
-- Name: inventario_aguas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_aguas (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    nombre_producto character varying(100),
    detalle_producto text,
    precio numeric(10,2),
    stock integer
);


ALTER TABLE public.inventario_aguas OWNER TO postgres;

--
-- Name: inventario_aguas_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_aguas_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_aguas_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_aguas_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_aguas_id_inventario_seq OWNED BY public.inventario_aguas.id_inventario;


--
-- Name: inventario_churros; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_churros (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    nombre_producto character varying(100),
    detalle_producto text,
    precio numeric(10,2),
    stock integer
);


ALTER TABLE public.inventario_churros OWNER TO postgres;

--
-- Name: inventario_churros_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_churros_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_churros_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_churros_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_churros_id_inventario_seq OWNED BY public.inventario_churros.id_inventario;


--
-- Name: inventario_comida; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_comida (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    nombre_producto character varying(100),
    detalle_producto text,
    precio numeric(10,2),
    stock integer
);


ALTER TABLE public.inventario_comida OWNER TO postgres;

--
-- Name: inventario_comida_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_comida_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_comida_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_comida_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_comida_id_inventario_seq OWNED BY public.inventario_comida.id_inventario;


--
-- Name: inventario_deli; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_deli (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    nombre_producto character varying(100),
    detalle_producto text,
    precio numeric(10,2),
    stock integer
);


ALTER TABLE public.inventario_deli OWNER TO postgres;

--
-- Name: inventario_deli_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_deli_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_deli_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_deli_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_deli_id_inventario_seq OWNED BY public.inventario_deli.id_inventario;


--
-- Name: inventario_gorditas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_gorditas (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    nombre_producto character varying(100),
    detalle_producto text,
    precio numeric(10,2),
    stock integer
);


ALTER TABLE public.inventario_gorditas OWNER TO postgres;

--
-- Name: inventario_gorditas_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_gorditas_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_gorditas_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_gorditas_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_gorditas_id_inventario_seq OWNED BY public.inventario_gorditas.id_inventario;


--
-- Name: inventario_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_id_inventario_seq OWNED BY public.inventario.id_inventario;


--
-- Name: inventario_pizza; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_pizza (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    nombre_producto character varying(100),
    detalle_producto text,
    precio numeric(10,2),
    stock integer
);


ALTER TABLE public.inventario_pizza OWNER TO postgres;

--
-- Name: inventario_pizza_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_pizza_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_pizza_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_pizza_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_pizza_id_inventario_seq OWNED BY public.inventario_pizza.id_inventario;


--
-- Name: inventario_quecas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_quecas (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    nombre_producto character varying(100),
    detalle_producto text,
    precio numeric(10,2),
    stock integer
);


ALTER TABLE public.inventario_quecas OWNER TO postgres;

--
-- Name: inventario_quecas_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_quecas_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_quecas_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_quecas_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_quecas_id_inventario_seq OWNED BY public.inventario_quecas.id_inventario;


--
-- Name: inventario_tiendita; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_tiendita (
    id_inventario integer NOT NULL,
    id_isla integer,
    id_producto integer,
    nombre_producto character varying(100),
    detalle_producto text,
    precio numeric(10,2),
    stock integer
);


ALTER TABLE public.inventario_tiendita OWNER TO postgres;

--
-- Name: inventario_tiendita_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_tiendita_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_tiendita_id_inventario_seq OWNER TO postgres;

--
-- Name: inventario_tiendita_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_tiendita_id_inventario_seq OWNED BY public.inventario_tiendita.id_inventario;


--
-- Name: isla; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.isla (
    id_isla integer NOT NULL,
    nombre_isla character varying(100),
    tipo_isla character varying(50),
    estado character varying(20)
);


ALTER TABLE public.isla OWNER TO postgres;

--
-- Name: isla_id_isla_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.isla_id_isla_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.isla_id_isla_seq OWNER TO postgres;

--
-- Name: isla_id_isla_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.isla_id_isla_seq OWNED BY public.isla.id_isla;


--
-- Name: pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedido (
    id_pedido integer NOT NULL,
    fecha_hora timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    estado_pedido character varying(30),
    subtotal numeric(10,2),
    id_cliente integer,
    id_isla integer,
    total numeric(10,2)
);


ALTER TABLE public.pedido OWNER TO postgres;

--
-- Name: pedido_id_pedido_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pedido_id_pedido_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedido_id_pedido_seq OWNER TO postgres;

--
-- Name: pedido_id_pedido_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pedido_id_pedido_seq OWNED BY public.pedido.id_pedido;


--
-- Name: producto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producto (
    id_producto integer NOT NULL,
    nombre_producto character varying(100) NOT NULL,
    descripcion text,
    precio numeric(10,2) NOT NULL,
    categoria character varying(50),
    id_isla integer
);


ALTER TABLE public.producto OWNER TO postgres;

--
-- Name: producto_id_producto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.producto_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.producto_id_producto_seq OWNER TO postgres;

--
-- Name: producto_id_producto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.producto_id_producto_seq OWNED BY public.producto.id_producto;


--
-- Name: auditoria_cambios id_auditoria; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_cambios ALTER COLUMN id_auditoria SET DEFAULT nextval('public.auditoria_cambios_id_auditoria_seq'::regclass);


--
-- Name: detalle_pedido id_detalle; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido ALTER COLUMN id_detalle SET DEFAULT nextval('public.detalle_pedido_id_detalle_seq'::regclass);


--
-- Name: factura id_factura; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura ALTER COLUMN id_factura SET DEFAULT nextval('public.factura_id_factura_seq'::regclass);


--
-- Name: inventario id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_id_inventario_seq'::regclass);


--
-- Name: inventario_aguas id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_aguas ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_aguas_id_inventario_seq'::regclass);


--
-- Name: inventario_churros id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_churros ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_churros_id_inventario_seq'::regclass);


--
-- Name: inventario_comida id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_comida ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_comida_id_inventario_seq'::regclass);


--
-- Name: inventario_deli id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_deli ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_deli_id_inventario_seq'::regclass);


--
-- Name: inventario_gorditas id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_gorditas ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_gorditas_id_inventario_seq'::regclass);


--
-- Name: inventario_pizza id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_pizza ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_pizza_id_inventario_seq'::regclass);


--
-- Name: inventario_quecas id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_quecas ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_quecas_id_inventario_seq'::regclass);


--
-- Name: inventario_tiendita id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_tiendita ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_tiendita_id_inventario_seq'::regclass);


--
-- Name: isla id_isla; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.isla ALTER COLUMN id_isla SET DEFAULT nextval('public.isla_id_isla_seq'::regclass);


--
-- Name: pedido id_pedido; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido ALTER COLUMN id_pedido SET DEFAULT nextval('public.pedido_id_pedido_seq'::regclass);


--
-- Name: producto id_producto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto ALTER COLUMN id_producto SET DEFAULT nextval('public.producto_id_producto_seq'::regclass);


--
-- Name: usuarios id_cliente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id_cliente SET DEFAULT nextval('public.cliente_id_cliente_seq'::regclass);


--
-- Name: auditoria_cambios auditoria_cambios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_cambios
    ADD CONSTRAINT auditoria_cambios_pkey PRIMARY KEY (id_auditoria);


--
-- Name: usuarios cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- Name: usuarios cliente_rfc_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT cliente_rfc_key UNIQUE (rfc);


--
-- Name: detalle_pedido detalle_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pkey PRIMARY KEY (id_detalle);


--
-- Name: factura factura_folio_fiscal_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_folio_fiscal_key UNIQUE (folio_fiscal);


--
-- Name: factura factura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id_factura);


--
-- Name: inventario_aguas inventario_aguas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_aguas
    ADD CONSTRAINT inventario_aguas_pkey PRIMARY KEY (id_inventario);


--
-- Name: inventario_churros inventario_churros_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_churros
    ADD CONSTRAINT inventario_churros_pkey PRIMARY KEY (id_inventario);


--
-- Name: inventario_comida inventario_comida_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_comida
    ADD CONSTRAINT inventario_comida_pkey PRIMARY KEY (id_inventario);


--
-- Name: inventario_deli inventario_deli_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_deli
    ADD CONSTRAINT inventario_deli_pkey PRIMARY KEY (id_inventario);


--
-- Name: inventario_gorditas inventario_gorditas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_gorditas
    ADD CONSTRAINT inventario_gorditas_pkey PRIMARY KEY (id_inventario);


--
-- Name: inventario_pizza inventario_pizza_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_pizza
    ADD CONSTRAINT inventario_pizza_pkey PRIMARY KEY (id_inventario);


--
-- Name: inventario inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_pkey PRIMARY KEY (id_inventario);


--
-- Name: inventario_quecas inventario_quecas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_quecas
    ADD CONSTRAINT inventario_quecas_pkey PRIMARY KEY (id_inventario);


--
-- Name: inventario_tiendita inventario_tiendita_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_tiendita
    ADD CONSTRAINT inventario_tiendita_pkey PRIMARY KEY (id_inventario);


--
-- Name: isla isla_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.isla
    ADD CONSTRAINT isla_pkey PRIMARY KEY (id_isla);


--
-- Name: pedido pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_pkey PRIMARY KEY (id_pedido);


--
-- Name: producto producto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id_producto);


--
-- Name: inventario_deli trg_auditoria_deli; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_deli AFTER INSERT OR DELETE OR UPDATE ON public.inventario_deli FOR EACH ROW EXECUTE FUNCTION public.funcion_auditar_cambios();


--
-- Name: inventario trg_auditoria_inventario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_inventario AFTER INSERT OR DELETE OR UPDATE ON public.inventario FOR EACH ROW EXECUTE FUNCTION public.funcion_auditar_cambios();


--
-- Name: producto trg_auditoria_producto; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_producto AFTER INSERT OR DELETE OR UPDATE ON public.producto FOR EACH ROW EXECUTE FUNCTION public.funcion_auditar_cambios();


--
-- Name: usuarios trg_auditoria_usuarios; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_usuarios AFTER INSERT OR DELETE OR UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.funcion_auditar_cambios();


--
-- Name: inventario trg_distribuir_inventario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_distribuir_inventario AFTER INSERT ON public.inventario FOR EACH ROW EXECUTE FUNCTION public.distribuir_stock_a_isla();


--
-- Name: inventario trg_eliminar_producto_inventario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_eliminar_producto_inventario AFTER DELETE ON public.inventario FOR EACH ROW EXECUTE FUNCTION public.eliminar_producto_de_isla();


--
-- Name: inventario trg_prevenir_borrado_con_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevenir_borrado_con_stock BEFORE DELETE ON public.inventario FOR EACH ROW EXECUTE FUNCTION public.validar_borrado_stock();


--
-- Name: inventario trg_repartir_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_repartir_stock AFTER UPDATE ON public.inventario FOR EACH ROW EXECUTE FUNCTION public.sincronizar_subislas();


--
-- Name: inventario trg_sincronizar_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sincronizar_stock AFTER UPDATE ON public.inventario FOR EACH ROW EXECUTE FUNCTION public.sincronizar_stock();


--
-- Name: producto trg_validar_producto; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validar_producto BEFORE INSERT OR UPDATE ON public.producto FOR EACH ROW EXECUTE FUNCTION public.validar_precios_y_datos();


--
-- Name: usuarios cliente_id_isla_asignada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT cliente_id_isla_asignada_fkey FOREIGN KEY (id_isla_asignada) REFERENCES public.isla(id_isla);


--
-- Name: detalle_pedido detalle_pedido_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedido(id_pedido);


--
-- Name: factura factura_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedido(id_pedido);


--
-- Name: inventario inventario_id_isla_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_id_isla_fkey FOREIGN KEY (id_isla) REFERENCES public.isla(id_isla);


--
-- Name: inventario inventario_id_producto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.producto(id_producto);


--
-- Name: pedido pedido_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.usuarios(id_cliente);


--
-- Name: pedido pedido_id_isla_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_id_isla_fkey FOREIGN KEY (id_isla) REFERENCES public.isla(id_isla);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO gestoru;
GRANT USAGE ON SCHEMA public TO clienteu;
GRANT USAGE ON SCHEMA public TO rol_gestor;
GRANT USAGE ON SCHEMA public TO rol_consulta;


--
-- Name: TABLE usuarios; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.usuarios TO shaka;
GRANT ALL ON TABLE public.usuarios TO admin;
GRANT SELECT,INSERT ON TABLE public.usuarios TO gestoru;
GRANT SELECT ON TABLE public.usuarios TO clienteu;
GRANT SELECT,INSERT ON TABLE public.usuarios TO rol_gestor;
GRANT SELECT ON TABLE public.usuarios TO rol_consulta;


--
-- Name: SEQUENCE cliente_id_cliente_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.cliente_id_cliente_seq TO shaka;
GRANT ALL ON SEQUENCE public.cliente_id_cliente_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.cliente_id_cliente_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.cliente_id_cliente_seq TO rol_gestor;


--
-- Name: TABLE detalle_pedido; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.detalle_pedido TO gestoru;
GRANT SELECT ON TABLE public.detalle_pedido TO clienteu;
GRANT SELECT,INSERT ON TABLE public.detalle_pedido TO rol_gestor;
GRANT SELECT ON TABLE public.detalle_pedido TO rol_consulta;


--
-- Name: SEQUENCE detalle_pedido_id_detalle_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.detalle_pedido_id_detalle_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.detalle_pedido_id_detalle_seq TO rol_gestor;


--
-- Name: TABLE factura; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.factura TO shaka;
GRANT ALL ON TABLE public.factura TO admin;
GRANT SELECT,INSERT ON TABLE public.factura TO gestoru;
GRANT SELECT ON TABLE public.factura TO clienteu;
GRANT SELECT,INSERT ON TABLE public.factura TO rol_gestor;
GRANT SELECT ON TABLE public.factura TO rol_consulta;


--
-- Name: SEQUENCE factura_id_factura_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.factura_id_factura_seq TO shaka;
GRANT ALL ON SEQUENCE public.factura_id_factura_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.factura_id_factura_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.factura_id_factura_seq TO rol_gestor;


--
-- Name: TABLE inventario; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.inventario TO shaka;
GRANT ALL ON TABLE public.inventario TO admin;
GRANT SELECT,INSERT ON TABLE public.inventario TO gestoru;
GRANT SELECT ON TABLE public.inventario TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario TO rol_gestor;
GRANT SELECT ON TABLE public.inventario TO rol_consulta;


--
-- Name: TABLE inventario_aguas; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.inventario_aguas TO gestoru;
GRANT SELECT ON TABLE public.inventario_aguas TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario_aguas TO rol_gestor;
GRANT SELECT ON TABLE public.inventario_aguas TO rol_consulta;


--
-- Name: SEQUENCE inventario_aguas_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventario_aguas_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_aguas_id_inventario_seq TO rol_gestor;


--
-- Name: TABLE inventario_churros; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.inventario_churros TO gestoru;
GRANT SELECT ON TABLE public.inventario_churros TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario_churros TO rol_gestor;
GRANT SELECT ON TABLE public.inventario_churros TO rol_consulta;


--
-- Name: SEQUENCE inventario_churros_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventario_churros_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_churros_id_inventario_seq TO rol_gestor;


--
-- Name: TABLE inventario_comida; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.inventario_comida TO gestoru;
GRANT SELECT ON TABLE public.inventario_comida TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario_comida TO rol_gestor;
GRANT SELECT ON TABLE public.inventario_comida TO rol_consulta;


--
-- Name: SEQUENCE inventario_comida_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventario_comida_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_comida_id_inventario_seq TO rol_gestor;


--
-- Name: TABLE inventario_deli; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.inventario_deli TO gestoru;
GRANT SELECT ON TABLE public.inventario_deli TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario_deli TO rol_gestor;
GRANT SELECT ON TABLE public.inventario_deli TO rol_consulta;


--
-- Name: SEQUENCE inventario_deli_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventario_deli_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_deli_id_inventario_seq TO rol_gestor;


--
-- Name: TABLE inventario_gorditas; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.inventario_gorditas TO gestoru;
GRANT SELECT ON TABLE public.inventario_gorditas TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario_gorditas TO rol_gestor;
GRANT SELECT ON TABLE public.inventario_gorditas TO rol_consulta;


--
-- Name: SEQUENCE inventario_gorditas_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventario_gorditas_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_gorditas_id_inventario_seq TO rol_gestor;


--
-- Name: SEQUENCE inventario_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.inventario_id_inventario_seq TO shaka;
GRANT ALL ON SEQUENCE public.inventario_id_inventario_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_id_inventario_seq TO rol_gestor;


--
-- Name: TABLE inventario_pizza; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.inventario_pizza TO gestoru;
GRANT SELECT ON TABLE public.inventario_pizza TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario_pizza TO rol_gestor;
GRANT SELECT ON TABLE public.inventario_pizza TO rol_consulta;


--
-- Name: SEQUENCE inventario_pizza_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventario_pizza_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_pizza_id_inventario_seq TO rol_gestor;


--
-- Name: TABLE inventario_quecas; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.inventario_quecas TO gestoru;
GRANT SELECT ON TABLE public.inventario_quecas TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario_quecas TO rol_gestor;
GRANT SELECT ON TABLE public.inventario_quecas TO rol_consulta;


--
-- Name: SEQUENCE inventario_quecas_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventario_quecas_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_quecas_id_inventario_seq TO rol_gestor;


--
-- Name: TABLE inventario_tiendita; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.inventario_tiendita TO gestoru;
GRANT SELECT ON TABLE public.inventario_tiendita TO clienteu;
GRANT SELECT,INSERT ON TABLE public.inventario_tiendita TO rol_gestor;
GRANT SELECT ON TABLE public.inventario_tiendita TO rol_consulta;


--
-- Name: SEQUENCE inventario_tiendita_id_inventario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventario_tiendita_id_inventario_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.inventario_tiendita_id_inventario_seq TO rol_gestor;


--
-- Name: TABLE isla; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.isla TO shaka;
GRANT ALL ON TABLE public.isla TO admin;
GRANT SELECT,INSERT ON TABLE public.isla TO gestoru;
GRANT SELECT ON TABLE public.isla TO clienteu;
GRANT SELECT,INSERT ON TABLE public.isla TO rol_gestor;
GRANT SELECT ON TABLE public.isla TO rol_consulta;


--
-- Name: SEQUENCE isla_id_isla_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.isla_id_isla_seq TO shaka;
GRANT ALL ON SEQUENCE public.isla_id_isla_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.isla_id_isla_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.isla_id_isla_seq TO rol_gestor;


--
-- Name: TABLE pedido; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.pedido TO shaka;
GRANT ALL ON TABLE public.pedido TO admin;
GRANT SELECT,INSERT ON TABLE public.pedido TO gestoru;
GRANT SELECT ON TABLE public.pedido TO clienteu;
GRANT SELECT,INSERT ON TABLE public.pedido TO rol_gestor;
GRANT SELECT ON TABLE public.pedido TO rol_consulta;


--
-- Name: SEQUENCE pedido_id_pedido_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.pedido_id_pedido_seq TO shaka;
GRANT ALL ON SEQUENCE public.pedido_id_pedido_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.pedido_id_pedido_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.pedido_id_pedido_seq TO rol_gestor;


--
-- Name: TABLE producto; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.producto TO shaka;
GRANT ALL ON TABLE public.producto TO admin;
GRANT SELECT,INSERT ON TABLE public.producto TO gestoru;
GRANT SELECT ON TABLE public.producto TO clienteu;
GRANT SELECT,INSERT ON TABLE public.producto TO rol_gestor;
GRANT SELECT ON TABLE public.producto TO rol_consulta;


--
-- Name: SEQUENCE producto_id_producto_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.producto_id_producto_seq TO shaka;
GRANT ALL ON SEQUENCE public.producto_id_producto_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.producto_id_producto_seq TO gestoru;
GRANT SELECT,USAGE ON SEQUENCE public.producto_id_producto_seq TO rol_gestor;


--
-- PostgreSQL database dump complete
--

\unrestrict kWJqOiIsMzD0TOZxYBqCjTyVrJsJsbcbu8HUulWWJeOshVmzLj1ThzfR17G238T

