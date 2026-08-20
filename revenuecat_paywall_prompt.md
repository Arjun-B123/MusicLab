# RevenueCat AI Paywall Prompt — MusicLab Pro

Paste the block below into RevenueCat's AI paywall generator.

---

Create a **multi-step paywall flow** for **MusicLab**, a mobile music-learning and practice-journal app. The entitlement is **"MusicLab Pro"**. This is a sequence of full screens the user swipes/taps through, not one long scrolling page — each key feature gets its own dedicated screen, and the final screen is the pricing/purchase page.

**Responsive scaling — required on every screen:** Layouts must scale correctly across the full range of phone sizes (small phones like iPhone SE / compact Android down to large phones like Pro Max / large Android, in both portrait aspect ratios). No fixed pixel-perfect layouts that only work at one size: use flexible/proportional spacing, text that doesn't clip or overflow at smaller widths, tap targets that stay reachable and appropriately sized (minimum ~44pt) on every screen, and safe-area-aware padding so nothing sits under a notch or gets covered by system gesture bars at the bottom. Test that copy doesn't overflow at Dynamic Type / larger accessibility text sizes.

**Brand tone:** Calm, warm, premium, personal — a "Warm Journal" aesthetic. Not a flashy gamified app; it should feel like a well-crafted personal notebook, not a hard-sell subscription screen. Avoid aggressive urgency tactics, countdown timers, or loud "BEST VALUE!!" badges. Confidence and warmth over pressure.

**Design tokens to use on every screen:**
- Background: `#FAF3EA` (light) — warm off-white, not stark white
- Primary accent (terracotta): `#D97A4A`, pressed/dark state `#C15F30`
- Secondary accent (sage green): `#8A9A7E`
- Tertiary accent (gold, sparing use — recommended-plan highlight only): `#F2C94C`
- Ink/text: `#3A2B22` (primary), `#8A7A6D` (secondary), `#A3947F` (faint/caption)
- Card surfaces: white `#FFFFFF` with a soft `#ECDFC9` border, 16–20px corner radius
- Headline font: a warm handwritten/script style (we use Kalam) for headlines only — never for body text or pricing numbers
- Body font: Inter (clean humanist sans-serif), regular/medium/semibold weights
- Buttons: pill-shaped (fully rounded), terracotta fill with white text for the primary CTA
- Progress indicator (dots or thin bar) near the top of each feature screen showing position in the sequence, in the same muted tones — small, not distracting

**Screen sequence:**

**Screen 1 — Hero / opener**
Handwritten-style headline: "See how far you've come." Subhead (Inter, secondary ink color): "MusicLab Pro unlocks the full picture of your practice — not just that you practiced, but whether you actually improved." A single "Continue" button to advance. This screen sets emotional tone, doesn't sell features yet.

**Screen 2 — Full performance analysis** (the strongest hook — give this screen the most visual craft/prominence of all the feature screens)
Headline: "Know exactly what to fix." Body: "Bar-by-bar feedback on your playing — not just a score, but specifically where things went off and what to practice next." Simple supporting visual motif (e.g. a stylized waveform or bar-by-bar indicator using the accent colors) rather than a screenshot. "Continue" button.

**Screen 3 — Unlimited pieces**
Headline: "Every piece you're learning, in one place." Body: "Free is capped at 3 pieces — Pro removes the limit, so your whole repertoire lives in your library." "Continue" button.

**Screen 4 — Complete recording history & comparisons**
Headline: "Hear how far you've come." Body: "Free keeps your last 5 takes. Pro keeps everything — compare your first take to your latest and actually hear the improvement." "Continue" button.

**Screen 5 — Personalized practice coach**
Headline: "A practice plan that knows your weak spots." Body: "Pro turns your last analysis into a specific plan — which section, which hand, what tempo — instead of generic reminders." "Continue" button.

**Screen 6 — Your full Musical Journey**
Headline: "Your whole musical story, not just last month." Body: "Free shows your last 30 days. Pro keeps your entire journey — every piece, every milestone, from day one." "Continue" button.

**Screen 7 — Pricing / purchase (final screen)**
This is the "connected" screen where the actual purchase happens — map to the 3 products already configured under the "MusicLab Pro" entitlement (Monthly, Annual/Yearly, Lifetime; don't create new products).
- **Monthly**: $6.99/month, 7-day free trial
- **Yearly**: $39.99/year (display the ~52% savings vs. monthly), 7-day free trial — **recommended/default-selected**, subtle gold-bordered highlight with a small "Most popular" label (not a loud banner)
- **Lifetime**: $79.99 one-time purchase, no trial — positioned as "Own it forever, no subscription"
- Each plan's trial reads clearly, e.g. "7 days free, then $39.99/year."
- Trust row below pricing, small text: "Cancel anytime · Restore purchases · No hidden charges"
- Primary CTA: "Start my free trial" (pill-shaped, terracotta fill, white text)
- Secondary dismiss: plain text link (not a button), muted color: "Maybe later"

**Navigation:** Swipe or tap "Continue" to advance through screens 1–6; each of those screens also has a small "Skip to pricing" text link for users who don't want to see every feature. Screen 7 has no further "Continue" — it's the terminal screen (purchase or dismiss).

**What to avoid:** no stock photography of unrelated people, no countdown timers, no "limited time" false urgency, no red/alarming colors anywhere, no dense legal text dominating the layout (keep restore/terms as small unobtrusive links at the very bottom of screen 7 only).
