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

    const now = new Date()
    const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000)

    console.log(`[Accountability Agent] Running at ${now.toISOString()}`)
    console.log(`[Accountability Agent] Checking reminders sent before ${twoHoursAgo.toISOString()}`)

    // 1. Get reminders sent 2+ hours ago without acknowledgment
    const { data: unacknowledgedReminders, error: remindersError } = await supabaseClient
      .from('reminders_log')
      .select(`
        id,
        task_id,
        sent_to,
        sent_at,
        couple_id,
        profiles!reminders_log_sent_to_fkey(full_name)
      `)
      .is('acknowledged_at', null)
      .lt('sent_at', twoHoursAgo.toISOString())
      .eq('reminder_type', 'morning_digest')

    if (remindersError) {
      console.error('Error fetching reminders:', remindersError)
      throw remindersError
    }

    console.log(`[Accountability Agent] Found ${unacknowledgedReminders?.length || 0} unacknowledged reminders`)

    let followUpsSent = 0

    for (const reminder of unacknowledgedReminders || []) {
      // Skip if no task_id (general digest without specific task)
      if (!reminder.task_id) {
        // For general digests, check if ANY tasks are still pending
        const today = new Date().toISOString().split('T')[0]
        
        const { data: pendingTasks } = await supabaseClient
          .from('tasks')
          .select('id, title')
          .eq('couple_id', reminder.couple_id)
          .eq('is_active', true)
          .or(`due_date.is.null,due_date.lte.${today}`)
          .limit(1)

        if (!pendingTasks || pendingTasks.length === 0) {
          // All tasks done, acknowledge the reminder
          await supabaseClient
            .from('reminders_log')
            .update({ acknowledged_at: now.toISOString() })
            .eq('id', reminder.id)
          
          console.log(`[Accountability Agent] Auto-acknowledged reminder ${reminder.id} - all tasks complete`)
          continue
        }

        // Send a general follow-up
        const followUpMessage = `Hey! Just checking in - how's today going? Some things are still on the list. No rush, just making sure nothing slips through! 😊`

        // Log follow-up
        await supabaseClient.from('reminders_log').insert({
          couple_id: reminder.couple_id,
          sent_to: reminder.sent_to,
          message: followUpMessage,
          sent_at: now.toISOString(),
          reminder_type: 'follow_up'
        })

        // Acknowledge original reminder so we don't keep following up
        await supabaseClient
          .from('reminders_log')
          .update({ acknowledged_at: now.toISOString() })
          .eq('id', reminder.id)

        followUpsSent++
        console.log(`[Accountability Agent] Sent general follow-up to ${reminder.profiles?.full_name}`)
        continue
      }

      // 2. Check if specific task was completed since reminder
      const { data: completions } = await supabaseClient
        .from('task_completions')
        .select('completed_at')
        .eq('task_id', reminder.task_id)
        .gte('completed_at', reminder.sent_at)

      if (completions && completions.length > 0) {
        // Task was completed, mark reminder as acknowledged
        await supabaseClient
          .from('reminders_log')
          .update({ acknowledged_at: now.toISOString() })
          .eq('id', reminder.id)
        
        console.log(`[Accountability Agent] Task ${reminder.task_id} was completed, acknowledging reminder`)
        continue
      }

      // 3. Get task details for the follow-up
      const { data: task } = await supabaseClient
        .from('tasks')
        .select('title')
        .eq('id', reminder.task_id)
        .single()

      if (!task) {
        console.log(`[Accountability Agent] Task ${reminder.task_id} not found, skipping`)
        continue
      }

      // 4. Send gentle follow-up
      const followUpMessage = `Hey! Just checking in - did "${task.title}" happen? No rush, just making sure nothing slips through! 😊`

      // Log follow-up
      await supabaseClient.from('reminders_log').insert({
        task_id: reminder.task_id,
        couple_id: reminder.couple_id,
        sent_to: reminder.sent_to,
        message: followUpMessage,
        sent_at: now.toISOString(),
        reminder_type: 'follow_up'
      })

      // Acknowledge original reminder
      await supabaseClient
        .from('reminders_log')
        .update({ acknowledged_at: now.toISOString() })
        .eq('id', reminder.id)

      followUpsSent++
      console.log(`[Accountability Agent] Sent follow-up for "${task.title}" to ${reminder.profiles?.full_name}`)
    }

    console.log(`[Accountability Agent] Completed. Sent ${followUpsSent} follow-ups.`)

    return new Response(
      JSON.stringify({ success: true, followUpsSent, timestamp: now.toISOString() }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('[Accountability Agent] Error:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
