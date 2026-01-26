import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY') ?? ''
    const today = new Date().toISOString().split('T')[0]

    console.log(`[Morning Digest] Running for date: ${today}`)

    // 1. Get all active couples with their profiles
    const { data: couples, error: couplesError } = await supabaseClient
      .from('couples')
      .select('id, household_name, profiles(id, full_name, notification_preferences)')

    if (couplesError) {
      console.error('Error fetching couples:', couplesError)
      throw couplesError
    }

    console.log(`[Morning Digest] Found ${couples?.length || 0} couples`)

    for (const couple of couples || []) {
      // 2. Get tasks that need attention:
      // - Overdue (due_date < today)
      // - Due today (due_date = today)
      // - No due date (ongoing tasks)
      const { data: tasks, error: tasksError } = await supabaseClient
        .from('tasks')
        .select('*, task_completions(completed_at, completed_by)')
        .eq('couple_id', couple.id)
        .eq('is_active', true)
        .or(`due_date.is.null,due_date.lte.${today}`)

      if (tasksError) {
        console.error(`Error fetching tasks for couple ${couple.id}:`, tasksError)
        continue
      }

      // 3. Filter uncompleted tasks (not completed today)
      const pendingTasks = tasks?.filter(task => {
        const completedToday = task.task_completions?.some((c: any) => 
          c.completed_at && c.completed_at.startsWith(today)
        )
        return !completedToday
      }) || []

      console.log(`[Morning Digest] Couple ${couple.household_name}: ${pendingTasks.length} pending tasks`)

      if (pendingTasks.length === 0) {
        console.log(`[Morning Digest] No pending tasks for ${couple.household_name}, skipping`)
        continue
      }

      // 4. Get last completion date for context
      const tasksWithContext = pendingTasks.map(task => {
        const lastCompletion = task.task_completions
          ?.sort((a: any, b: any) => new Date(b.completed_at).getTime() - new Date(a.completed_at).getTime())[0]
        
        let contextInfo = ''
        if (lastCompletion) {
          const lastDate = new Date(lastCompletion.completed_at)
          const daysSince = Math.floor((new Date().getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24))
          contextInfo = `(last done ${daysSince} days ago)`
        } else {
          contextInfo = '(never done)'
        }
        
        return `- ${task.title} ${contextInfo} [${task.category || 'general'}]`
      })

      // 5. Generate digest message using Claude
      console.log(`[Morning Digest] Calling Claude API for ${couple.household_name}`)
      
      const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'x-api-key': anthropicApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-5-20250929',
          max_tokens: 512,
          messages: [{
            role: 'user',
            content: `Generate a warm, friendly morning digest message for a couple managing their household together. 

Their pending tasks for today:
${tasksWithContext.join('\n')}

Guidelines:
- Start with "Morning ❤️" 
- Be warm and encouraging, not corporate
- Keep it concise (3-4 sentences max)
- Mention specific tasks naturally
- End with something like "Quick thumbs up when each is done? ✓"
- Never say "URGENT" or use harsh language
- Feel like a caring friend, not a task manager`
          }]
        })
      })

      if (!claudeResponse.ok) {
        const errorText = await claudeResponse.text()
        console.error(`Claude API error: ${errorText}`)
        continue
      }

      const claudeData = await claudeResponse.json()
      const digestMessage = claudeData.content[0].text

      console.log(`[Morning Digest] Generated message for ${couple.household_name}`)

      // 6. Log reminder for each partner
      for (const profile of couple.profiles || []) {
        if (profile.notification_preferences?.morning_digest !== false) {
          await supabaseClient.from('reminders_log').insert({
            couple_id: couple.id,
            sent_to: profile.id,
            message: digestMessage,
            sent_at: new Date().toISOString(),
            reminder_type: 'morning_digest'
          })
          
          console.log(`[Morning Digest] Logged reminder for ${profile.full_name}`)
        }
      }
    }

    console.log(`[Morning Digest] Completed successfully`)

    return new Response(
      JSON.stringify({ success: true, timestamp: new Date().toISOString() }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('[Morning Digest] Error:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
