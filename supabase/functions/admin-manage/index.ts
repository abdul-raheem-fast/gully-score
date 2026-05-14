// Admin management edge function.
// Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in function env.
import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Action =
  | "block_user"
  | "unblock_user"
  | "delete_team"
  | "set_user_role"
  | "list_profiles";

type RequestBody = {
  action: Action;
  userId?: string;
  teamId?: string;
  role?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response("Missing Supabase env vars", {
        status: 500,
        headers: corsHeaders,
      });
    }

    if (!jwt) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });

    const { data: authData, error: authError } = await supabase.auth.getUser(
      jwt,
    );
    if (authError || !authData?.user) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", authData.user.id)
      .maybeSingle();

    if (profile?.role !== "admin") {
      return new Response("Forbidden", { status: 403, headers: corsHeaders });
    }

    const body = (await req.json()) as RequestBody;
    const audit = async (payload: {
      action: string;
      targetUserId?: string;
      targetTeamId?: string;
      details?: Record<string, unknown>;
    }) => {
      try {
        await supabase.from("admin_audit_logs").insert({
          admin_user_id: authData.user.id,
          action: payload.action,
          target_user_id: payload.targetUserId ?? null,
          target_team_id: payload.targetTeamId ?? null,
          details: payload.details ?? null,
        });
      } catch (_) {
        // Avoid failing main request if audit log fails.
      }
    };

    switch (body.action) {
      case "list_profiles": {
        const { data, error } = await supabase
          .from("profiles")
          .select("id,email,name,role,is_blocked,created_at")
          .order("created_at", { ascending: false });
        if (error) {
          return new Response(error.message, {
            status: 400,
            headers: corsHeaders,
          });
        }
        return Response.json({ profiles: data ?? [] }, { headers: corsHeaders });
      }
      case "block_user": {
        if (!body.userId) {
          return new Response("Missing userId", {
            status: 400,
            headers: corsHeaders,
          });
        }
        const { error } = await supabase
          .from("profiles")
          .update({ is_blocked: true, updated_at: new Date().toISOString() })
          .eq("id", body.userId);
        if (error) {
          return new Response(error.message, {
            status: 400,
            headers: corsHeaders,
          });
        }
        await audit({ action: "block_user", targetUserId: body.userId });
        return Response.json({ ok: true }, { headers: corsHeaders });
      }
      case "unblock_user": {
        if (!body.userId) {
          return new Response("Missing userId", {
            status: 400,
            headers: corsHeaders,
          });
        }
        const { error } = await supabase
          .from("profiles")
          .update({ is_blocked: false, updated_at: new Date().toISOString() })
          .eq("id", body.userId);
        if (error) {
          return new Response(error.message, {
            status: 400,
            headers: corsHeaders,
          });
        }
        await audit({ action: "unblock_user", targetUserId: body.userId });
        return Response.json({ ok: true }, { headers: corsHeaders });
      }
      case "set_user_role": {
        if (!body.userId || !body.role) {
          return new Response("Missing userId/role", {
            status: 400,
            headers: corsHeaders,
          });
        }
        const { error } = await supabase
          .from("profiles")
          .update({ role: body.role, updated_at: new Date().toISOString() })
          .eq("id", body.userId);
        if (error) {
          return new Response(error.message, {
            status: 400,
            headers: corsHeaders,
          });
        }
        await audit({
          action: "set_user_role",
          targetUserId: body.userId,
          details: { role: body.role },
        });
        return Response.json({ ok: true }, { headers: corsHeaders });
      }
      case "delete_team": {
        if (!body.teamId) {
          return new Response("Missing teamId", {
            status: 400,
            headers: corsHeaders,
          });
        }
        const { data: team, error: teamError } = await supabase
          .from("teams")
          .select("name")
          .eq("id", body.teamId)
          .maybeSingle();
        if (teamError) {
          return new Response(teamError.message, {
            status: 400,
            headers: corsHeaders,
          });
        }
        if (!team) {
          return new Response("Team not found", {
            status: 404,
            headers: corsHeaders,
          });
        }
        await supabase.from("team_players").delete().eq("team_name", team.name);
        const { error } = await supabase
          .from("teams")
          .delete()
          .eq("id", body.teamId);
        if (error) {
          return new Response(error.message, {
            status: 400,
            headers: corsHeaders,
          });
        }
        await audit({ action: "delete_team", targetTeamId: body.teamId });
        return Response.json({ ok: true }, { headers: corsHeaders });
      }
      default:
        return new Response("Invalid action", {
          status: 400,
          headers: corsHeaders,
        });
    }
  } catch (e) {
    return new Response("Server error", { status: 500, headers: corsHeaders });
  }
});
