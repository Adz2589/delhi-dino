# Delhi Dino

A spoof of the Chrome offline dinosaur game. Your runner jumps Delhi Police barricades while Modi and Shah run ahead; points count up to 1000, the gap closes as you go, and at 1000 your runner catches up.

Like chromedino.com, you can swap the dinosaur for other runners: Neha Bora (special power **SANGATHAN** — three rallies that continue the run from a barricade, plus a cape), Rahul Gandhi, Abhijeet Dipke, Saurav Das, Ashutosh Ranka, Ratna Singh, and a journalists' bench of KK, Samdish Bhatia, Peek TV, Rana Ayyub and Peeing Human. The sprites are 16-pixel stick figures with name tags, not likenesses; nobody named here endorsed the game. A FAQ under the game explains the satire.

![demo](delhi-dino.gif)

**Neha Bora:** each SANGATHAN rally brings supporters with AISF flags who run alongside her for the rest of the run, and her runs play a 14-second theme (`audio/neha-theme.mp3`, cut from 1s–15s of a protest clip) with an on/off toggle.

**Leaderboard & flags:** your country flag shows in the HUD and on the leaderboard. Signed-in players (email + password) post runs to a global board, best run per player. Sign-in, the global board and the feedback form need a free Supabase project and a Web3Forms key: see [backend/SETUP.md](backend/SETUP.md). Until then the site shows local bests and the panels say they're switching on soon.

**SEO:** title/description, canonical, Open Graph + Twitter card (`og-image.png`), JSON-LD (WebSite, VideoGame, FAQPage), `robots.txt`, `sitemap.xml`, favicons.

**Play:** open `index.html`, or visit the GitHub Pages link for this repo.

**Controls:** SPACE / ↑ / tap to jump.

## Re-recording the GIF

The page has a `?capture=1` mode that plays itself and POSTs the frames to a tiny local server:

```bash
node record/server.js /tmp/frames
```

Open `http://localhost:8765/?capture=1`, wait a few seconds, then:

```bash
ffmpeg -y -framerate 20 -i /tmp/frames/%04d.png -vf "scale=1200:-1:flags=neighbor,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=none" -loop 0 delhi-dino.gif
```

Satire, obviously. Created by adz_25.
