// Conexión a Supabase (proyecto "Orvexa Projects").
// La clave publicable es segura en la app: los permisos los controla RLS en la base de datos.
// Se puede sobrescribir al compilar: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://bvdidntnbimcpozhfkpl.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: 'sb_publishable_Wsk_XbMoGhPR6YlfWklnBg_Rw77lslh');
