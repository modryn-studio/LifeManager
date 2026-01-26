# LifeManager 💑

**Invisible magic for life together**

A couple's life management app with AI-powered agents for shared task coordination, pattern recognition, and intelligent reminders.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.16+ 
- Dart 3.2+
- Android Studio or VS Code with Flutter extension
- Supabase account (already configured)
- Physical Android device for testing

### Setup

1. **Install dependencies**
   ```bash
   cd lifemanager
   flutter pub get
   ```

2. **Environment Configuration**
   
   The `.env` file should already be configured with:
   ```
   SUPABASE_URL=https://vcbknqnrxzzfrxpjcbcl.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_...
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Build & Deploy

### Build Release APK
```bash
flutter build apk --release
```

### Install on Device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 🗄️ Supabase Setup

### Deploy Database Schema
```bash
cd supabase
supabase db push
```

### Deploy Edge Functions
```bash
supabase functions deploy morning-digest
supabase functions deploy accountability-agent
supabase functions deploy pattern-analyzer
```

### Set Secrets
```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase secrets set OPENAI_API_KEY=sk-proj-...
```

## 🧪 Dogfooding Timeline

### Week 1: Basic Usage
- [ ] Install on Luke's device
- [ ] Install on Sarah's device  
- [ ] Create accounts and pair as couple
- [ ] Add recurring tasks (Heartgard on 24th, cat fountain weekly)
- [ ] Complete tasks daily
- [ ] Verify real-time sync between devices

### Week 2: Pattern Detection
- [ ] Continue task completion
- [ ] Check for pattern suggestions after 7 days
- [ ] Accept/reject pattern recommendations
- [ ] Verify accountability follow-ups work

## ✅ Success Criteria

1. Both partners can log in and see shared tasks
2. Tasks sync in real-time between devices
3. Morning digest notification sent at 7 AM
4. Completing a task updates for both partners instantly
5. Pattern analyzer detects recurring patterns after 7 days
6. Accountability agent sends follow-up after 2 hours

## 🛠️ MVP Couple Unlinking

Manual deletion via SQL:
```sql
DELETE FROM couples WHERE id = 'couple-uuid-here';
```

---

Built with ❤️ for couples managing life together.
