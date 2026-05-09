# Broskie AI Edge Function

This function powers the GullyScore chatbot from Supabase data and Groq.

Required Supabase secrets:

```bash
supabase secrets set GROQ_API_KEY=your_groq_key
supabase secrets set GROQ_MODEL=llama-3.3-70b-versatile
```

`GROQ_MODEL` is optional. If it is not set, the function uses
`llama-3.3-70b-versatile`.

Deploy:

```bash
supabase functions deploy gully-ai-chat
```
