# Solo Testing Guide - LifeManager
## Testing Without a Partner

This guide walks you through testing all Phase 1 features solo before inviting your partner.

---

## 🚀 Quick Start Checklist

- [ ] App installed on Android device
- [ ] `.env` file configured with Supabase credentials
- [ ] Edge Functions deployed
- [ ] Cron jobs scheduled
- [ ] Test account created

---

## Test 1: Authentication & Setup (5 min)

### 1.1 Sign Up Flow
```
1. Launch app
2. Tap "Sign up"
3. Enter:
   - Display name: "Luke" (or your name)
   - Email: your test email
   - Password: test123456
4. Submit

✅ Expected: Redirected to Couple Setup screen
```

### 1.2 Couple Setup Flow
```
1. Enter household name: "Luke's Household"
2. Leave partner email blank (testing solo)
3. Tap "Let's go!"

✅ Expected: Redirected to Task List screen (empty state)
```

### 1.3 Logout & Login
```
1. From Task List, tap profile icon → Sign out
2. Re-launch app
3. Tap "Log in"
4. Enter same credentials

✅ Expected: Logged back in, see Task List screen
```

---

## Test 2: Task Management (10 min)

### 2.1 Create Basic Task
```
1. Tap FAB (+) button
2. Enter:
   - Title: "Give dog Heartgard"
   - Description: "Monthly medication for Buddy"
   - Category: Pets 🐾
   - Due date: Tomorrow
   - Leave recurrence blank
3. Tap "Create task"

✅ Expected:
   - Task appears in "Today" or "Upcoming" section
   - Shows category emoji 🐾
   - Shows due date
```

### 2.2 Create Recurring Task
```
1. Tap FAB (+)
2. Enter:
   - Title: "Clean cat fountain"
   - Category: Pets 🐾
   - Due date: Today
   - Recurrence: Weekly
3. Tap "Create task"

✅ Expected:
   - Task appears in "Today" section
   - Shows "Weekly" badge
```

### 2.3 Create Task with No Due Date
```
1. Tap FAB (+)
2. Enter:
   - Title: "Research vacation spots"
   - Category: Planning 📋
   - Leave due date blank
3. Tap "Create task"

✅ Expected:
   - Task appears in "When you get to it" section
```

### 2.4 Task Sections Verification
```
After creating 3+ tasks, verify sections appear:
- Overdue (if you have overdue tasks)
- Today (tasks due today)
- Upcoming (future due dates)
- When you get to it (no due date)

✅ Expected: Clean visual separation between sections
```

---

## Test 3: Task Interactions (10 min)

### 3.1 Complete a Task
```
1. Find "Give dog Heartgard" task
2. Tap the checkbox

✅ Expected:
   - Checkmark animates in (400ms)
   - Text strikes through
   - Task card fades slightly
   - Task moves to "Recently completed" (collapsed section at bottom)
```

### 3.2 Complete Recurring Task
```
1. Find "Clean cat fountain" (weekly recurring)
2. Tap checkbox to complete

✅ Expected:
   - Task completes
   - NEW instance of same task auto-created with next week's due date
   - Check database: task_completions table has new record
```

### 3.3 View Task Details
```
1. Tap any task card
2. Review details screen

✅ Expected:
   - Shows title, description, category, due date
   - If recurring: shows "Repeats: Weekly"
   - Shows Edit and Delete icons in app bar
```

### 3.4 Edit Task
```
1. From Task Detail screen, tap Edit icon
2. Change title to "Give dog Heartgard (Buddy)"
3. Change due date to 2 days from now
4. Tap "Save"

✅ Expected:
   - Changes saved
   - Task updated in list
   - Task moved to correct section (Upcoming)
```

### 3.5 Delete Task
```
1. From Task Detail, tap Delete icon
2. Confirm deletion

✅ Expected:
   - Task removed from list
   - Database record deleted
```

### 3.6 Mark Task Incomplete
```
1. Tap a completed task to view details
2. Tap "Mark as incomplete" button

✅ Expected:
   - Task becomes active again
   - Strikethrough removed
   - Task returns to appropriate section
```

---

## Test 4: UI/UX Elements (5 min)

### 4.1 Theme & Design
```
Verify visual elements match brand spec:
- Background: Warm Cream (#FAF7F2) ✅
- Primary buttons: Soft Sage (#A8B5A0) ✅
- Title font: Handwritten (Caveat) ✅
- Body font: Clean sans-serif (Inter) ✅
- Card shadows: Soft, not harsh ✅
- Generous spacing between elements ✅
```

### 4.2 Empty State
```
1. Delete all tasks (or fresh account)
2. View Task List screen

✅ Expected:
   - Message: "All clear! 🌅 Tap + to add something when you're ready."
   - Warm, friendly tone
   - Not corporate or cold
```

### 4.3 Category Icons
```
Verify each category shows correct emoji:
- Household: 🏠
- Meals: 🍽️
- Errands: 🛒
- Planning: 📋
- Self-care: 💆
- Togetherness: 💑
- Pets: 🐾
- Other: 📌
```

---

## Test 5: Database Verification (5 min)

### 5.1 Check Supabase Dashboard
```
1. Open Supabase Dashboard
2. Navigate to Table Editor

Verify tables have data:
- couples: 1 row (your household)
- profiles: 1 row (your profile)
- tasks: X rows (your created tasks)
- task_completions: Y rows (completed tasks)
```

### 5.2 Verify RLS Policies
```
1. In SQL Editor, run:

SELECT * FROM tasks WHERE couple_id = 'your-couple-id';

✅ Expected: Returns only YOUR couple's tasks
```

### 5.3 Check Recurring Task Trigger
```
1. Complete a recurring task in app
2. Refresh Supabase Table Editor → tasks
3. Look for 2 tasks with same title:
   - One completed (is_completed = true)
   - One new with future due date (is_completed = false)

✅ Expected: Trigger auto-created next instance
```

---

## Test 6: Edge Functions (Manual Testing)

### 6.1 Test Morning Digest Function
```
1. Open terminal
2. Run:
   npx supabase functions invoke morning-digest --no-verify-jwt

3. Check response

✅ Expected:
   - Status 200
   - Response: {"success": true, "digestsSent": X}
   - Check reminders_log table for new entries
```

### 6.2 Test Accountability Agent
```
1. Create task with due date = today
2. Complete it (to generate reminder)
3. Wait 3 hours (or manually invoke):
   npx supabase functions invoke accountability-agent --no-verify-jwt

✅ Expected:
   - Status 200
   - Response: {"success": true, "followUpsSent": X}
```

### 6.3 Test Pattern Analyzer
```
Note: Requires 90 days of completion data to work effectively

For quick test:
1. Manually insert sample completions in database
2. Run:
   npx supabase functions invoke pattern-analyzer --no-verify-jwt

✅ Expected:
   - Status 200
   - Check task_patterns table for detected patterns
```

---

## Test 7: Cron Jobs Verification (5 min)

### 7.1 Check Scheduled Jobs
```
1. Open Supabase Dashboard → SQL Editor
2. Run:

SELECT * FROM cron.job ORDER BY jobid;

✅ Expected: 3 jobs listed:
   - morning-digest-7am (0 7 * * *)
   - accountability-agent-2h (0 */2 * * *)
   - pattern-analyzer-weekly (0 0 * * 0)
```

### 7.2 Verify Job Execution (After 7 AM Next Day)
```
1. After 7 AM the next day, check reminders_log table:

SELECT * FROM reminders_log 
WHERE reminder_type = 'morning_digest' 
ORDER BY sent_at DESC 
LIMIT 5;

✅ Expected: New entry with today's timestamp
```

---

## Test 8: Pattern Suggestions Flow (Simulated)

### 8.1 Manual Pattern Creation
```
Since pattern detection requires 90 days of data, manually insert a test pattern:

1. Open Supabase SQL Editor
2. Run:

INSERT INTO task_patterns (
  couple_id, 
  pattern_title, 
  pattern_description,
  detected_pattern,
  suggested_recurrence,
  confidence
) VALUES (
  'your-couple-id',
  'Give dog Heartgard',
  'Detected recurring pattern: completed around the 24th each month',
  '{"frequency": "monthly", "day_of_month": 24}',
  'monthly',
  0.95
);

3. Restart app
4. Check Task List for pattern suggestion badge
```

### 8.2 Accept Pattern Suggestion
```
1. Tap "Suggestions" badge/button
2. See pattern card with 💡 icon
3. Tap "Accept"

✅ Expected:
   - Pattern marked as accepted in DB
   - New recurring task created
   - Pattern removed from suggestions
```

### 8.3 Dismiss Pattern Suggestion
```
1. View pattern suggestions
2. Tap "Dismiss" on a pattern

✅ Expected:
   - Pattern marked as rejected (accepted = false)
   - Removed from suggestions view
```

---

## Test 9: Real-Time Sync (Multi-Device)

### 9.1 Same Account, Two Devices
```
If you have 2 Android devices:

1. Install app on both devices
2. Log in with same account
3. On Device A: Create a task
4. On Device B: Observe

✅ Expected:
   - Task appears on Device B within 1-2 seconds
   - No need to refresh
```

### 9.2 Complete Task Cross-Device
```
1. On Device A: Complete a task
2. On Device B: Observe

✅ Expected:
   - Task marks complete on Device B instantly
   - Strikethrough animation plays
```

---

## Test 10: Error Handling (5 min)

### 10.1 Network Offline
```
1. Turn on Airplane Mode
2. Try to create a task

✅ Expected:
   - Error message displays (warm peach background)
   - "Something went wrong" or similar
   - No crash
```

### 10.2 Invalid Input
```
1. Try to create task with empty title
2. Submit

✅ Expected:
   - Form validation error
   - "Please enter a task title"
```

### 10.3 Duplicate Completion
```
1. Complete a task
2. Immediately complete same task again (before UI updates)

✅ Expected:
   - Handled gracefully
   - No duplicate completion records
```

---

## Test 11: Performance (3 min)

### 11.1 Large Task List
```
1. Create 20+ tasks
2. Scroll through list

✅ Expected:
   - Smooth scrolling (60fps)
   - No lag or jank
   - Cards render quickly
```

### 11.2 App Startup Time
```
1. Force close app
2. Relaunch
3. Time to Task List screen

✅ Expected:
   - < 3 seconds on typical Android device
```

---

## Test 12: Notifications (Coming Soon)

*Note: Local notifications configured but not fully integrated yet*

### 12.1 Test Notification Permission
```
1. First launch should request notification permission
2. Grant permission

✅ Expected: Permission granted, FCM token generated
```

---

## 🐛 Common Issues & Fixes

### Issue: "No profile found"
**Fix:** 
- Check profiles table in Supabase
- Verify couple_setup_screen created profile
- Re-run signup flow

### Issue: Tasks not syncing in real-time
**Fix:**
- Check Supabase Realtime is enabled
- Verify RLS policies allow SELECT
- Check network connection

### Issue: Recurring task doesn't create next instance
**Fix:**
- Verify database trigger exists: `after_task_completion`
- Check trigger function: `create_next_recurring_task()`
- Look for errors in Supabase logs

### Issue: Edge Functions return 401
**Fix:**
- Verify service_role_key in pg_cron jobs
- Check function secrets are set
- Ensure Authorization header is correct

### Issue: Cron jobs not running
**Fix:**
- Verify pg_cron extension enabled
- Check job schedule syntax
- Review Supabase logs for execution errors

---

## ✅ Final Checklist

Before inviting your partner, ensure:

- [ ] Can sign up and log in
- [ ] Can create tasks (basic, recurring, no due date)
- [ ] Can complete tasks
- [ ] Can edit and delete tasks
- [ ] Recurring tasks auto-generate next instance
- [ ] UI looks warm and polished (not corporate)
- [ ] All 3 Edge Functions deployed and responding
- [ ] Cron jobs scheduled correctly
- [ ] Real-time sync working (if testing with 2 devices)
- [ ] No crashes or major bugs

---

## 🎯 Success Criteria

**Phase 1 is working correctly if:**

1. ✅ You can manage your daily tasks solo
2. ✅ Recurring tasks work automatically
3. ✅ Morning digest would send at 7 AM (check reminders_log)
4. ✅ Accountability agent runs every 2 hours
5. ✅ Pattern analyzer is scheduled weekly
6. ✅ UI feels warm, not like a task manager

---

## 📝 Next Steps

After solo testing is complete:

1. **Invite Partner:**
   - Have partner sign up with their email
   - In couple setup, they enter YOUR email
   - Database trigger will link you automatically

2. **Test Partner Features:**
   - Task completion syncs between you
   - Morning digest sends to both
   - Accountability follows up with both
   - Partner indicator shows on assigned tasks

3. **Real-World Dogfooding:**
   - Use for 2 weeks with your partner
   - Track which AI features actually help
   - Note any rough edges or bugs
   - Iterate based on real usage

---

## 🔧 Manual Database Queries for Testing

### View Your Couple Info
```sql
SELECT c.*, p.full_name, p.email 
FROM couples c
JOIN profiles p ON c.id = p.couple_id
WHERE p.id = auth.uid();
```

### View All Your Tasks
```sql
SELECT t.*, tc.completed_at, tc.completed_by
FROM tasks t
LEFT JOIN task_completions tc ON t.id = tc.task_id
WHERE t.couple_id = (SELECT couple_id FROM profiles WHERE id = auth.uid())
ORDER BY t.due_date NULLS LAST, t.created_at DESC;
```

### View Recent Completions
```sql
SELECT 
  t.title,
  tc.completed_at,
  p.full_name as completed_by_name
FROM task_completions tc
JOIN tasks t ON tc.task_id = t.id
JOIN profiles p ON tc.completed_by = p.id
WHERE tc.couple_id = (SELECT couple_id FROM profiles WHERE id = auth.uid())
ORDER BY tc.completed_at DESC
LIMIT 10;
```

### View Pattern Suggestions
```sql
SELECT * FROM task_patterns
WHERE couple_id = (SELECT couple_id FROM profiles WHERE id = auth.uid())
  AND accepted IS NULL
ORDER BY confidence DESC;
```

### View Reminder History
```sql
SELECT 
  rl.*,
  t.title as task_title,
  p.full_name as sent_to_name
FROM reminders_log rl
LEFT JOIN tasks t ON rl.task_id = t.id
LEFT JOIN profiles p ON rl.sent_to = p.id
WHERE rl.couple_id = (SELECT couple_id FROM profiles WHERE id = auth.uid())
ORDER BY rl.sent_at DESC
LIMIT 20;
```

---

## 🎨 Design Verification

Use this checklist to ensure the app matches the brand spec:

**Colors:**
- [ ] Background is warm cream (#FAF7F2)
- [ ] Primary actions are soft sage (#A8B5A0)
- [ ] Alerts use warm peach (never harsh red)
- [ ] Completed items use gentle green (#C8D5B9)

**Typography:**
- [ ] Headers use handwritten font (Caveat)
- [ ] Body text uses clean sans-serif (Inter)
- [ ] No ALL CAPS anywhere
- [ ] Minimal use of bold

**Voice & Tone:**
- [ ] Messages feel warm, not corporate
- [ ] No harsh language ("URGENT!", "OVERDUE!")
- [ ] Friendly concern, not nagging
- [ ] Uses "you" and "both" appropriately

**Spacing:**
- [ ] Generous whitespace (24-32px margins)
- [ ] Cards have breathing room
- [ ] Not cluttered or cramped

---

## 📊 Metrics to Track (Optional)

If you want to measure Phase 1 success:

- Task completion rate (daily)
- Time between task creation and completion
- Number of recurring tasks created
- Pattern suggestions accepted vs. dismissed
- App opens per day
- Tasks created per week

---

**Happy Testing! 🎉**

Once everything checks out solo, you're ready to invite your partner and experience the real magic of couple coordination.
