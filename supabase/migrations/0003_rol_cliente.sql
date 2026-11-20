-- ORVEXA · rol de cliente (contratante). Va en su propia migración: un valor nuevo de enum
-- no se puede usar en la misma transacción en la que se agrega.
alter type public.user_role add value if not exists 'cliente';
