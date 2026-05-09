const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (!groqKey) {
      return json({ error: "GROQ_API_KEY is not configured." }, 500);
    }

    const { question, history, viewer_mode, client_context } = await req.json();
    const prompt = String(question ?? "").trim();
    if (!prompt) return json({ answer: "Ask me about a player, team, match, or prediction." });

    const context = await loadCricketContext(req);
    const messages = Array.isArray(history)
      ? history
          .slice(-8)
          .filter((m: ChatMessage) => m && typeof m.content === "string")
          .map((m: ChatMessage) => ({
            role: m.role === "assistant" ? "assistant" : "user",
            content: m.content.slice(0, 1200),
          }))
      : [];

    const systemPrompt = [
      "You are Broskie AI, the GullyScore cricket analytics assistant.",
      "Answer only from the supplied Supabase cricket context. If data is missing, say what needs to be scored or stored.",
      "You can summarize players, teams, matches, recent form, and make cautious future-performance predictions.",
      "Predictions must be framed as estimates, not guarantees. Keep answers under 180 words unless the user asks for detail.",
      viewer_mode === "admin"
        ? "You are speaking to an admin. Include actionable ops insights when relevant."
        : "You are speaking to a player. Prefer practical and motivational guidance.",
    ].join("\n");

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${groqKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: Deno.env.get("GROQ_MODEL") ?? "llama-3.3-70b-versatile",
        temperature: 0.35,
        max_completion_tokens: 700,
        messages: [
          { role: "system", content: systemPrompt },
          ...messages,
          {
            role: "user",
            content: `Viewer mode:\n${String(viewer_mode ?? "player")}\n\nClient context:\n${JSON.stringify(client_context ?? {})}\n\nDatabase context:\n${context}\n\nQuestion:\n${prompt}`,
          },
        ],
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      return json({ error: `Groq request failed: ${text}` }, 502);
    }

    const data = await response.json();
    return json({ answer: extractOutputText(data) });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : String(error) }, 500);
  }
});

async function loadCricketContext(req: Request): Promise<string> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const auth = req.headers.get("Authorization") ?? "";
  if (!supabaseUrl || !anonKey) return "Supabase environment is not configured.";

  const headers = {
    "apikey": anonKey,
    "Authorization": auth,
    "Content-Type": "application/json",
  };

  const [matches, teams, teamPlayers, players, innings, ballEvents, profiles] = await Promise.all([
    rest(supabaseUrl, headers, "/matches?select=id,title,team_a_name,team_b_name,venue,match_date,status,score_a,score_b,result,winner,overs_per_innings,created_at&order=created_at.desc&limit=40"),
    rest(supabaseUrl, headers, "/teams?select=id,name,abbreviation,captain_name&order=name.asc&limit=80"),
    rest(supabaseUrl, headers, "/team_players?select=team_name,player_name,is_captain&limit=300"),
    rest(supabaseUrl, headers, "/players?select=match_id,team_name,player_name,is_captain,created_at&order=created_at.desc&limit=500"),
    rest(supabaseUrl, headers, "/innings?select=id,match_id,innings_no,batting_team,bowling_team,total_runs,wickets,balls_bowled,extras,is_completed&order=innings_no.asc&limit=120"),
    rest(supabaseUrl, headers, "/ball_events?select=innings_id,over_no,ball_no,runs_off_bat,extra_runs,extra_type,striker_name,bowler_name,wicket_type,wicket_player_name,commentary,created_at&order=created_at.desc&limit=260"),
    rest(supabaseUrl, headers, "/profiles?select=id,name,role,playing_role,organization&limit=200"),
  ]);

  return JSON.stringify({
    generated_at: new Date().toISOString(),
    matches,
    teams,
    team_players: teamPlayers,
    players,
    innings,
    recent_ball_events: ballEvents,
    profiles,
  });
}

async function rest(
  supabaseUrl: string,
  headers: Record<string, string>,
  path: string,
): Promise<unknown[]> {
  try {
    const response = await fetch(`${supabaseUrl}/rest/v1${path}`, { headers });
    if (!response.ok) return [];
    const data = await response.json();
    return Array.isArray(data) ? data : [];
  } catch (_) {
    return [];
  }
}

function extractOutputText(data: any): string {
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content === "string" && content.trim()) {
    return content.trim();
  }
  return "I could not generate an answer from the available data.";
}

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
