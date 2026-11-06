// ORVEXA · gestión de usuarios (solo administradores)
// Acciones:
//   bootstrap  -> crea el primer administrador (solo si no existe ninguno)
//   create     -> admin crea operador / ayudante / admin
//   update     -> admin cambia nombre, rol, teléfono, activo
//   password   -> admin cambia la contraseña de un usuario
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DOMAIN = "orvexa.app";
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

function toEmail(username: string) {
  const u = username.trim().toLowerCase();
  return u.includes("@") ? u : `${u.replace(/[^a-z0-9._-]/g, "")}@${DOMAIN}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const service = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "JSON inválido" }, 400);
  }
  const action = String(body.action ?? "");

  async function createUser(username: string, password: string, fullName: string, role: string, phone?: string) {
    if (!username || !password || password.length < 6) {
      throw new Error("Usuario y contraseña (mínimo 6 caracteres) son obligatorios");
    }
    if (!["admin", "operador", "ayudante"].includes(role)) throw new Error("Rol inválido");
    const email = toEmail(username);
    // Pase de un solo uso: la base rechaza cualquier cuenta nueva sin él (no hay auto-registro).
    const { error: passErr } = await service.from("user_creation_passes").upsert({
      email,
      expires_at: new Date(Date.now() + 2 * 60 * 1000).toISOString(),
    });
    if (passErr) throw new Error(passErr.message);
    const { data, error } = await service.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName, username: username.trim().toLowerCase() },
    });
    if (error) await service.from("user_creation_passes").delete().eq("email", email);
    if (error) throw new Error(error.message.includes("already") ? "Ese usuario ya existe" : error.message);
    const { error: pErr } = await service
      .from("profiles")
      .update({ full_name: fullName, role, active: true, phone: phone ?? null, username: username.trim().toLowerCase() })
      .eq("id", data.user.id);
    if (pErr) throw new Error(pErr.message);
    return data.user.id;
  }

  try {
    if (action === "bootstrap") {
      const { count } = await service.from("profiles").select("id", { count: "exact", head: true }).eq("role", "admin");
      if ((count ?? 0) > 0) return json({ error: "Ya existe un administrador" }, 403);
      const id = await createUser(
        String(body.username ?? ""), String(body.password ?? ""), String(body.full_name ?? "Administrador"), "admin",
      );
      return json({ id });
    }

    // Todo lo demás requiere un administrador activo
    const auth = req.headers.get("Authorization") ?? "";
    const token = auth.replace(/^Bearer\s+/i, "");
    const { data: who, error: whoErr } = await service.auth.getUser(token);
    if (whoErr || !who.user) return json({ error: "No autenticado" }, 401);
    const { data: me } = await service.from("profiles").select("role, active").eq("id", who.user.id).single();
    if (!me || me.role !== "admin" || !me.active) return json({ error: "Solo administradores" }, 403);

    if (action === "create") {
      const id = await createUser(
        String(body.username ?? ""), String(body.password ?? ""), String(body.full_name ?? ""),
        String(body.role ?? "operador"), body.phone ? String(body.phone) : undefined,
      );
      return json({ id });
    }

    if (action === "update") {
      const id = String(body.id ?? "");
      if (id === who.user.id && (body.active === false || (body.role && body.role !== "admin"))) {
        return json({ error: "No puedes desactivarte ni quitarte el rol de admin a ti mismo" }, 400);
      }
      const patch: Record<string, unknown> = {};
      for (const k of ["full_name", "role", "phone", "active"]) if (k in body) patch[k] = body[k];
      const { error } = await service.from("profiles").update(patch).eq("id", id);
      if (error) throw new Error(error.message);
      return json({ ok: true });
    }

    if (action === "password") {
      const password = String(body.password ?? "");
      if (password.length < 6) return json({ error: "Mínimo 6 caracteres" }, 400);
      const { error } = await service.auth.admin.updateUserById(String(body.id ?? ""), { password });
      if (error) throw new Error(error.message);
      return json({ ok: true });
    }

    return json({ error: "Acción desconocida" }, 400);
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 400);
  }
});
