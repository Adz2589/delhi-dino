# Switching on sign-in, the global leaderboard and feedback

The site works without this. These steps turn on the three features that need a server:

| Feature | Service | Cost |
|---|---|---|
| Email sign-in + global leaderboard with flags | [Supabase](https://supabase.com) | free tier |
| Feedback emailed to your inbox | [Web3Forms](https://web3forms.com) | free tier (250 emails/month) |

Both keys you end up with are **public by design**: they are meant to sit in the page source. Row-level security in `schema.sql` decides what visitors can actually read and write.

**Never** paste a Supabase `service_role` key or your database password into `index.html` or into a chat.

## 1. Supabase (about 5 minutes)

1. Go to supabase.com → **Start your project** → sign in with GitHub.
2. **New project**: name `delhi-dino`, region **South Asia (Mumbai)**, set a database password (keep it to yourself).
3. When the project is ready: **SQL Editor** → **New query** → paste all of [`schema.sql`](schema.sql) → **Run**. It should say "Success. No rows returned".
4. **Authentication → Sign In / Providers → Email**: make sure Email is enabled and turn **Confirm email** *off*.
   (Supabase's built-in mailer only delivers to your own team's addresses, so confirmation emails would never reach players. To switch confirmation back on later, first add custom SMTP under Authentication → Emails, e.g. with Resend.)
5. **Authentication → URL Configuration**: Site URL `https://delhindino.com`.
6. **Project Settings → API Keys**: copy the **Project URL** and the **anon / publishable** key.

## 2. Web3Forms (about 1 minute)

1. Go to web3forms.com → enter the inbox that should receive feedback → **Create Access Key**.
2. The access key arrives by email. Copy it.

## 3. Put the values in `index.html`

Near the bottom of `index.html`:

```js
const BACKEND = {
  supabaseUrl: 'https://YOUR-PROJECT.supabase.co',
  supabaseKey: 'YOUR-ANON-OR-PUBLISHABLE-KEY',
  web3formsKey: 'YOUR-WEB3FORMS-ACCESS-KEY',
};
```

Commit and push. Sign-in, the global leaderboard and the feedback form switch on by themselves.

## Where to see things

- **Players and scores**: Supabase → Table Editor → `profiles`, `scores`
- **Feedback**: your inbox, plus Supabase → Table Editor → `feedback`
- **Remove a bad name or score**: delete the row in the Table Editor

## What the database enforces

- Players can only post scores as themselves; everyone can read the board.
- Scores must be 0–1000, at a plausible pace (1000 points takes over 20 seconds), at most one every 10 seconds.
- Display names are 2–24 characters; countries are two-letter codes.
- Feedback can be written by anyone but read only from the dashboard.

Scores are still sent from the browser, so a determined cheater can post a fake run that passes these checks. Delete it in the Table Editor if that happens.
