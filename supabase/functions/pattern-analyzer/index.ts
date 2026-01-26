import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Minimum confidence threshold for pattern suggestions (hardcoded for MVP)
const MIN_CONFIDENCE = 0.80

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
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY') ?? ''

    console.log(`[Pattern Analyzer] Starting weekly pattern analysis`)

    // 1. Get all couples
    const { data: couples, error: couplesError } = await supabaseClient
      .from('couples')
      .select('id, household_name')

    if (couplesError) {
      console.error('Error fetching couples:', couplesError)
      throw couplesError
    }

    console.log(`[Pattern Analyzer] Analyzing ${couples?.length || 0} couples`)

    let totalPatternsFound = 0
    let totalEmbeddingCost = 0

    for (const couple of couples || []) {
      console.log(`[Pattern Analyzer] Analyzing couple: ${couple.household_name}`)

      // 2. Get completion history (last 90 days)
      const ninetyDaysAgo = new Date()
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)

      const { data: completions, error: completionsError } = await supabaseClient
        .from('task_completions')
        .select(`
          completed_at,
          tasks!inner(title, category, couple_id, recurrence_pattern)
        `)
        .eq('tasks.couple_id', couple.id)
        .is('tasks.recurrence_pattern', null) // Only analyze non-recurring tasks
        .gte('completed_at', ninetyDaysAgo.toISOString())
        .order('completed_at', { ascending: true })

      if (completionsError) {
        console.error(`Error fetching completions for ${couple.id}:`, completionsError)
        continue
      }

      // Need at least 3 completions to detect patterns
      if (!completions || completions.length < 3) {
        console.log(`[Pattern Analyzer] Not enough data for ${couple.household_name} (${completions?.length || 0} completions)`)
        continue
      }

      console.log(`[Pattern Analyzer] Found ${completions.length} completions to analyze`)

      // 3. Format data for Claude analysis
      const completionData = completions.map(c => ({
        task: c.tasks.title,
        category: c.tasks.category,
        date: c.completed_at
      }))

      // 4. Use Claude to detect patterns
      console.log(`[Pattern Analyzer] Calling Claude API for pattern detection`)
      
      const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'x-api-key': anthropicApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-5-20250929',
          max_tokens: 2048,
          messages: [{
            role: 'user',
            content: `Analyze these task completions and identify recurring patterns that should become recurring tasks.

Task completion history:
${completionData.map(c => `- "${c.task}" [${c.category}] on ${c.date}`).join('\n')}

Find patterns where:
- Same or very similar task is done repeatedly
- There's a detectable time interval (daily, weekly, monthly, or custom interval in days)
- The pattern appears intentional, not coincidental

Return ONLY a valid JSON array of detected patterns. No markdown, no explanation, just the JSON array.
Format:
[
  {
    "task_description": "Give dog Heartgard",
    "pattern": {"frequency": "monthly", "day_of_month": 24, "interval_days": 30},
    "confidence": 0.95,
    "reasoning": "Task completed on 24th for 3 consecutive months"
  }
]

Rules:
- Only include patterns with confidence >= ${MIN_CONFIDENCE}
- frequency can be: "daily", "weekly", "monthly", or "custom"
- For custom, include interval_days
- For monthly, include day_of_month if detectable
- Return empty array [] if no strong patterns found`
          }]
        })
      })

      if (!claudeResponse.ok) {
        const errorText = await claudeResponse.text()
        console.error(`Claude API error: ${errorText}`)
        continue
      }

      const claudeData = await claudeResponse.json()
      const patternsText = claudeData.content[0].text

      // 5. Parse patterns JSON
      let patterns = []
      try {
        // Clean up potential markdown formatting
        const cleanJson = patternsText.replace(/```json\n?|\n?```/g, '').trim()
        patterns = JSON.parse(cleanJson)
      } catch (parseError) {
        console.error(`Failed to parse Claude response: ${patternsText}`)
        continue
      }

      if (!Array.isArray(patterns) || patterns.length === 0) {
        console.log(`[Pattern Analyzer] No patterns found for ${couple.household_name}`)
        continue
      }

      console.log(`[Pattern Analyzer] Found ${patterns.length} patterns for ${couple.household_name}`)

      // 6. Generate embeddings and store patterns
      for (const pattern of patterns) {
        if (pattern.confidence < MIN_CONFIDENCE) {
          console.log(`[Pattern Analyzer] Skipping pattern with low confidence: ${pattern.confidence}`)
          continue
        }

        // Check if similar pattern already exists
        const { data: existingPatterns } = await supabaseClient
          .from('task_patterns')
          .select('id')
          .eq('couple_id', couple.id)
          .ilike('task_description', `%${pattern.task_description}%`)
          .is('accepted', null)

        if (existingPatterns && existingPatterns.length > 0) {
          console.log(`[Pattern Analyzer] Similar pending pattern already exists: ${pattern.task_description}`)
          continue
        }

        // Generate embedding for similarity search
        console.log(`[Pattern Analyzer] Generating embedding for: ${pattern.task_description}`)
        
        const embeddingResponse = await fetch('https://api.openai.com/v1/embeddings', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${openaiApiKey}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            model: 'text-embedding-3-small',
            input: pattern.task_description
          })
        })

        if (!embeddingResponse.ok) {
          const errorText = await embeddingResponse.text()
          console.error(`OpenAI embedding error: ${errorText}`)
          continue
        }

        const embeddingData = await embeddingResponse.json()
        const embedding = embeddingData.data[0].embedding

        // Cost tracking: text-embedding-3-small is ~$0.00002 per 1K tokens
        totalEmbeddingCost += 0.00002
        console.log(`[Pattern Analyzer] OpenAI embedding cost: ~$0.00002 (running total: $${totalEmbeddingCost.toFixed(5)})`)

        // Store pattern suggestion
        const { error: insertError } = await supabaseClient.from('task_patterns').insert({
          couple_id: couple.id,
          task_description: pattern.task_description,
          detected_pattern: JSON.stringify(pattern.pattern),
          embedding: embedding,
          confidence_score: pattern.confidence
        })

        if (insertError) {
          console.error(`Error inserting pattern: ${insertError.message}`)
          continue
        }

        totalPatternsFound++
        console.log(`[Pattern Analyzer] Stored pattern: "${pattern.task_description}" (${(pattern.confidence * 100).toFixed(0)}% confidence)`)
      }
    }

    console.log(`[Pattern Analyzer] Completed. Found ${totalPatternsFound} new patterns. Estimated embedding cost: $${totalEmbeddingCost.toFixed(5)}`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        patternsFound: totalPatternsFound,
        estimatedCost: totalEmbeddingCost,
        timestamp: new Date().toISOString() 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('[Pattern Analyzer] Error:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
