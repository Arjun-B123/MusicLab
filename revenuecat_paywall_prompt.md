# RevenueCat AI Paywall Prompt — MusicLab Pro

Paste the block below into RevenueCat's AI paywall generator.

---

Create a paywall for **MusicLab**, a mobile music-learning and practice-journal app. The entitlement is **"MusicLab Pro"**.

**Brand tone:** Calm, warm, premium, personal — a "Warm Journal" aesthetic. This is not a flashy gamified app; it should feel like a well-crafted personal notebook, not a hard-sell subscription screen. Avoid aggressive urgency tactics, countdown timers, or loud "BEST VALUE!!" badges. Confidence and warmth over pressure.

**Design tokens to use:**
- Background: `#FAF3EA` (light) — warm off-white, not stark white
- Primary accent (terracotta): `#D97A4A`, pressed/dark state `#C15F30`
- Secondary accent (sage green): `#8A9A7E`
- Tertiary accent (gold, sparing use — for the recommended-plan highlight only): `#F2C94C`
- Ink/text: `#3A2B22` (primary), `#8A7A6D` (secondary), `#A3947F` (faint/caption)
- Card surfaces: white `#FFFFFF` with a soft `#ECDFC9` border, 16–20px corner radius
- Headline font: a warm handwritten/script style (we use Kalam) for the hero headline and section titles only — never for body text or pricing numbers
- Body font: Inter (clean humanist sans-serif), regular/medium/semibold weights
- Buttons: pill-shaped (fully rounded), terracotta fill with white text for the primary CTA

**Page structure, top to bottom:**

1. **Hero headline** (handwritten-style font): "See how far you've come." Subhead (Inter, secondary ink color): "MusicLab Pro unlocks the full picture of your practice — not just that you practiced, but whether you actually improved."

2. **Single headline feature callout** (this is the strongest hook, give it visual prominence — its own card or highlighted row): **"Full performance analysis"** — "Bar-by-bar feedback on exactly what to fix, not just a generic score." This should be the most visually emphasized feature on the page.

3. **Feature comparison list**, Free vs. Pro, phrased as benefits:
   - Pieces in your library: Free = "Up to 3" / Pro = "Unlimited"
   - Performance feedback: Free = "Rhythm & tempo only" / Pro = "Full bar-by-bar analysis"
   - Recording history: Free = "Last 5 takes" / Pro = "Complete history & comparisons"
   - Practice coach: Free = "Basic suggestions" / Pro = "Personalized, based on your analysis"
   - Musical Journey timeline: Free = "Last 30 days" / Pro = "Your entire journey"

4. **Pricing tiers** — three options, all with a **7-day free trial**:
   - **Monthly**: $6.99/month, 7-day free trial
   - **Yearly**: $39.99/year (work out and display the % savings vs. monthly — roughly 52%), 7-day free trial. This is the **recommended/default-selected** plan — give it a subtle gold-bordered highlight and a small "Most popular" label, not a loud banner.
   - **Lifetime**: $79.99 one-time purchase, no trial (it's a single payment, not a subscription) — position this as "Own it forever, no subscription" for people who dislike recurring billing.
   
   Each plan's trial should read clearly, e.g. "7 days free, then $39.99/year."

5. **Trust/reassurance row** below the pricing cards, small text: "Cancel anytime · Restore purchases · No hidden charges"

6. **Primary CTA button**: "Start my free trial" (pill-shaped, terracotta fill, white text)

7. **Secondary dismiss**: a plain text link (not a button), muted color: "Maybe later"

**Product/entitlement mapping:** map to the existing RevenueCat products already configured under the "MusicLab Pro" entitlement — identify them by package type Monthly, Annual/Yearly, and Lifetime (there are exactly 3 products already set up; don't create new ones).

**What to avoid:** no stock photography of unrelated people, no countdown timers, no "limited time" false urgency, no red/alarming colors anywhere, no dense legal text dominating the layout (keep restore/terms as small unobtrusive links at the very bottom).
