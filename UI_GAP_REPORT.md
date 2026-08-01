# Karatly Flutter UI Gap Report
### Compared against reference: `C:\Users\tejas\Karatly_Mobile_NewUI` (React/Capacitor)

Scope: **UI/visual only** — colors, gradients, metal-based theming, typography, spacing, radius, shadows, animations, iconography, layout structure. No flow/logic/navigation issues are included. All findings below are drawn from a full file-by-file read of both codebases (not a sample).

---

## 1. Executive Summary

The Flutter app is a genuinely close, screen-for-screen port of the React reference — file names, route structure, and most component boundaries already mirror each other 1:1 (`BottomNav.tsx` ↔ `bottom_nav_shell.dart`, `GoldPriceCard.tsx` ↔ `gold_price_card.dart`, etc.), and the core dark theme palette (`#F7CD57` gold, `#1A1918` bg, `#242320` card) is already correctly ported into `lib/app/theme.dart`. The floating pill bottom nav is already pixel-matched, including per-metal accent color switching.

However, five systemic problems repeat across almost every screen and should be fixed first, before any one-off polish:

| # | Systemic issue | Why it matters |
|---|---|---|
| 1 | **Per-metal theming (gold/silver/diamond) is wired in the bottom nav only.** Everywhere else — buttons, spinners, icons, borders, glows — silver and diamond screens frequently fall back to hardcoded gold (`AppTheme.gold`) instead of branching like the nav does. | Breaks the "consistent metal identity" requirement across Sell/SIP/Coin flows. |
| 2 | **Border radius drift.** React's design system uses distinct radii per surface type (10px cards, 12px banners, 20px sheets, 28px success cards, 40/50px pills). Flutter very frequently normalizes everything to a flat 16px, collapsing that visual hierarchy. | Flattens the "premium" layered card look into a uniform, less refined one. |
| 3 | **Missing decorative glow/blur layers.** React leans heavily on `blur-2xl`/`blur-3xl` soft glow circles behind hero cards, badges, and success icons, plus `backdrop-blur` on modal scrims. Flutter drops nearly all of these. | These glows are a major part of the "premium fintech" visual identity in the reference. |
| 4 | **Two flows are unstyled stubs or missing outright**: the Gold/Silver **SIP flow** (`sip_screen.dart`) is a bare placeholder, and **Silver Sell / Silver SIP** dedicated screens (`sell_silver_flow/`, `silver_sip_flow/`) are empty folders — silver reuses the gold sell screen via an `isSilver` flag that isn't consistently honored. | Biggest functional-UI gap in the whole app; not a polish item. |
| 5 | **Typography scale runs consistently smaller** than React (headlines, body copy, section titles are frequently 2–8px under the reference across splash, KYC, sell, and profile screens). | Reduces the "hero" feel of key screens (splash, success, review). |

Everything below is organized by section, with exact `file:line` references and the precise value to change, as gathered by the comparison passes.

---

## 2. Global Design Tokens (apply once, fixes many screens at once)

These are cross-cutting values worth centralizing (e.g. in `AppTheme` or a new `MetalTheme` helper) rather than fixing screen-by-screen:

- **Per-metal accent/gradient system.** React's canonical 3 gradients (from `index.css`):
  - Gold: `linear-gradient(90deg, #F7CD57, #E5AF35)` — full brand CTA gradient is 3-stop: `#F7CD57 → #E5AF35 (50.96%) → #B57F23 (100%)`.
  - Silver: `linear-gradient(90deg, #FFFFFF, #999999)`.
  - Diamond: `linear-gradient(90deg, #3AC7FF, #0073CE)`.
  Currently only `bottom_nav_shell.dart:36-40` branches on `activeMetalProvider`. Recommend a shared `MetalTheme.accentFor(metal)` / `MetalTheme.gradientFor(metal)` helper and auditing every `AppTheme.gold` hardcode inside silver/diamond-context screens (see §5 for the specific list of ~7 hardcoded spots in `sell_screen.dart` alone).
- **Radius scale.** React effectively uses: `10px` (rate/holdings cards), `12px` (banners/badges), `16px` (standard cards — matches Flutter default, keep), `20px` (sheets, KYC info cards), `28px` (success detail cards), `40px`/`50px`/`rounded-full` (pills — CTAs, security rows, bottom sheets). Flutter collapses most of the 10/20/28/40 cases down to 16.
- **Glow/blur decoration.** Recurring React pattern: two absolutely-positioned blurred circles (`blur-2xl`/`blur-3xl`, ~10-18% opacity, primary/accent color) behind hero cards and modal icon badges. Worth a single reusable `GlowBackdrop` widget.
- **Success-state glow** should be `rgba(247,205,87,0.18)` blur 40 spread 0 — Flutter repeatedly uses a much stronger `alpha 0.4 blur 30 spread 10`, appearing across coin-flow, sell-flow, and gold-coin success screens.
- **Fake status bar row** (9:30 clock + signal/battery icons above the header) appears on several React screens (KYC, PaymentMethods, Transfer, Rewards) and is never reproduced in Flutter. Low priority (cosmetic mobile-web artifact) — confirm with design whether it's even wanted in a native app before replicating.
- **Notification bell**: React is 24×24 (`h-6 w-6`) with a small red unread dot (`5×5px, #EE0105`); Flutter renders it 28-32px with no dot, in `payment_methods_screen.dart`, `transfer_screen.dart`, `rewards_screen.dart`, `how_it_works_screen.dart`.

---

## 3. Splash / Onboarding / Auth

| Flutter | React | Gap → Fix |
|---|---|---|
| `splash_screen_1.dart:145` | `PremiumSplash.tsx:69` | Skip label color is gray `#999999` → should be translucent white `rgba(255,255,255,0.6)`. |
| `splash_screen_1.dart:206-216` | `PremiumSplash.tsx:111-114` | Liquid-fill shape has no blur; add `ImageFilter.blur(sigmaX:2, sigmaY:2)`, and use asymmetric corner radius (not uniform 45px). |
| `splash_screen_1.dart:330-334` | `PremiumSplash.tsx:190` | Headline 22px → should be 24px, tighter tracking (~-0.4px). |
| `splash_screen_1.dart:373-379` | `PremiumSplash.tsx:223` | CTA button has an added gold glow shadow not present in React (plain neutral `shadow-lg`) — remove the colored glow. |
| `splash_screen_2.dart:257-263` | `PremiumSplash2.tsx:89` | Bottom bar shadow is fully opaque black → should be `rgba(0,0,0,0.5)`. |
| `splash_screen_3.dart:264-269` | `PremiumSplash3.tsx:87-89` | Headline 36px/1.15 line-height → should be 48px/52px line-height. |
| `splash_screen_3.dart:306-309` | `PremiumSplash3.tsx:98` | Body text 16px/24px → should be 18px/26px. |
| `splash_screen_3.dart:92-106` | `PremiumSplash3.tsx:150-153` | Background radial gradient has an extra middle stop and extends to 62%; React is a clean 2-stop gradient ending at 58%. Remove the middle stop. |
| `login_screen.dart:1017` | `AuthFlow.tsx:1017` | "VAULT ACCESS" badge missing subtle inset top-edge highlight (`shadow-[0_1px_0_rgba(255,255,255,.03)_inset]`). |
| `login_screen.dart:371` | `AuthFlow.tsx:442-449` | Footer security icon is a padlock (`Icons.lock`) → should be a shield-check glyph. |
| `login_screen.dart:304` | `AuthFlow.tsx:1063` | Terms text dimmed to 0.9 opacity → React renders at full opacity. |
| `login_screen.dart:341` | `AuthFlow.tsx:1085` | Send-OTP arrow icon 20px → should be 24px. |
| `signup_screen.dart:247-257` | `AuthFlow.tsx:1543-1545` | Title 28px, accent word not italic → should be 30px/36px line-height with the gold "Golden"-style word italicized. |
| `signup_screen.dart:262,266` | `AuthFlow.tsx:1548-1552` | Divider color is dark gold-brown `#6A511C` → should match Login screen's light gray `#C7C7C7`. |
| `otp_screen.dart:441` | `AuthFlow.tsx:899` | KYC prompt backdrop has no blur → add `backdrop-blur` equivalent (`ImageFilter.blur(sigmaX:8, sigmaY:8)`). |
| `otp_screen.dart:437-484` | `AuthFlow.tsx:909` | Missing decorative glow circle behind icon (`-right-12 -top-16, 144×144, bg #F7CD57 @15%, blur-3xl`). |
| `otp_screen.dart:453` | `AuthFlow.tsx:911-914` | Icon is a plain shield (`Icons.shield`) → should be shield-with-checkmark. |

---

## 4. Home / Dashboard / Market / Orders / Profile + Shared Cards

Overall structure is a close match; gaps are mostly missing gradients/decoration and a few structural misses:

- **Market — metal toggle chips** `market_screen.dart:199-252` vs `MainTabs.tsx:2339-2342,2287` — React fills the selected chip with a gradient (`linear-gradient(124.73deg,#FED55C 14.43%,#DA9500 86.04%)` gold / `linear-gradient(180deg,#FFFFFF,#999999)` silver); Flutter uses a flat solid color. Same gap on the silver CTA button (`market_screen.dart:739` uses `Colors.grey[400]`/`#BDBDBD` instead of React's exact `#999999`).
- **Market — search input border** loses a distinct gold shade (`#8E742F`) by reusing the hero-card's `#B28A3B` variable instead.
- **Brands screen — the most significant structural gap in this group.** `brands_screen.dart` is an entirely custom implementation, not a port of React's `Brands()` (`MainTabs.tsx:3024-3026` + `mockData.ts:7-12`): different brand names/data, no trust-score/progress bar, plain `Icons.verified` badge instead of a gradient logo tile with `BadgeCheck`, 18px card radius vs React's 12px, and — critically — it doesn't reuse the shared `BrandCard` widget at all.
- **`BrandCard` widget bug** `brand_card.dart:109-117` vs `BrandCard.tsx:18` — React passes a Tailwind gradient class string per brand (blue/purple/emerald/yellow); Flutter's `_parseColor()` tries to hex-parse that same string, fails silently, and every brand tile renders identical gold instead of its distinct color. Also missing the `from-black/60` overlay gradient on the logo tile.
- **`GoldPriceCard`** `gold_price_card.dart:17-31` vs `GoldPriceCard.tsx:7-9` — missing both decorative glow circles (`128×128 primary@10% blur-2xl` top-right, `96×96 accent@10% blur-xl` bottom-left). Price text also runs smaller: ₹ symbol 20px vs React 24px, price 32px vs React 36px.
- **`CategoryCard`** `category_card.dart:23-29` vs `CategoryCard.tsx:20` — missing the decorative blurred circle (`80×80 accent@5% blur-xl`); purity badge radius 8px vs React 6px.
- **`AmountSelector`** `amount_selector.dart:39,75,79` vs `AmountSelector.tsx:28,48` — preset/custom-input radius 12px vs React 8px.
- **`StepIndicator`** `step_indicator.dart:30-46` vs `StepIndicator.tsx:19-25` — React visually distinguishes *active* (accent fill + `0 0 10px rgba(212,175,55,.4)` glow) from *completed* (different `bg-primary` fill, no glow); Flutter uses one identical style for both, losing the current-vs-done distinction.
- **`SuccessAnimation`** `success_animation.dart:60-66` vs `SuccessAnimation.tsx:28-33` — React scatters 6 particles randomly (±100px, randomized scale); Flutter uses 4 fixed diagonal directions at a fixed 80px, reading as mechanical rather than an organic burst.
- **Profile screen** `profile_screen.dart` vs `MainTabs.tsx:3013-3306` — several concrete diffs:
  - Metric cards: bg `#0F1416` (React `#16181A`), no icon-circle background at all (React wraps icons in a black 24px circle), tone colors don't match (`#F7CD57`/`#90CAF9`/`#66BB6A` vs React `#E8B438`/`#6DD6FF`/`#15EE01`), value/label font sizes swapped (12/10px vs React 14/8px).
  - Avatar fallback uses a gold gradient circle with black text; React is a flat `#1A1A1A` circle with a `#E8B438` border/letter.
  - Menu rows have bare icons; React wraps each in a 40px circular badge (`#1F2124`, or `#2D2513` for KYC/Rewards rows).
  - Sign-out button is red-tinted (`#1A0A0A` bg, `#EF5350` border, no icon); React is a neutral `#0F1416` card with `#FF3700` text and a `LogOut` icon.
  - Section headings: 12px + 1.2 letter-spacing vs React 14px, no tracking.
  - Notification toggle pill: 44×24 track / 20px thumb / dark-grey off state vs React's smaller 40×20 track / 14px thumb / lighter `#A2A2A2` off state.

---

## 5. Buy / Sell Flows — Gold / Silver / Diamond Metal Theming

This is where the "consistent per-metal theme" requirement is weakest today.

### Gold
- **SIP flow is an unstyled stub.** `sip_screen.dart:3-17` is just an `AppBar` + centered "Gold SIP Step N" text — none of React's bottom-sheet shell, rate card, amount/frequency/debit-day pickers, gradient CTAs, or step rail exist (`SIPFlow.tsx`, ~700 lines). This is the single largest visual gap in the app.
- Sell flow radius/color drift throughout `sell_screen.dart` (holdings card 16px vs React 10px at :622; mode-toggle colors off-brand at :685-712; "Settled" icon wrong color/shape at :1190-1228; security row radius/icon color wrong at :1378-1402; success-circle glow too strong at :1476-1500; "Go Home" button recolored gold instead of neutral at :1524-1552).
- `rate_card.dart:58` Live Sell Rate card uses the wrong radius (16 vs React's 20), wrong background (gradient vs React's flat `#19160F`), and an oversized 60px badge vs React's small 40px cyan arrow icon.
- Gold Coin flow (`gold_coin_screen.dart`): back button is a bare icon instead of a frosted 32×32 circle (:637); rate value has no gradient-text treatment or pulse animation that React applies (:682 vs `GoldCoinFlow.tsx:579-581`); product badges use a plain 2-color circle instead of reusing the already-correct shared `KaratlyCircle`/`GoldCoinMark` widget (:769-773); success screen is missing its second CTA ("Buy/Redeem more") entirely and uses an off-brand gradient on the remaining button (:970-979).
- `sell_selection_screen.dart:110-121` — a `ShaderMask` wraps an empty string (dead code), so the gold-rate value renders as plain text instead of the intended `#F7CD57→#917833` gradient. Easy, high-value fix.

### Silver
- **`sell_silver_flow/` and `silver_sip_flow/` folders are empty.** Silver reuses `sell_flow/sell_screen.dart` via an `isSilver` boolean and the generic (unstyled) `sip_screen.dart` — meaning React's dedicated Silver SIP flow (6 distinct screens: Setup/Dashboard/Review/Mandate/Processing/Activated with pulse-ring animations) and Silver Sell flow (dedicated UPI/bank-entry and animated verification screens) have no matching Flutter UI at all.
- Where `isSilver` *is* checked, several spots still hardcode gold and ignore it: bank spinner (:1260), bank icon (:1302), processing spinner (:1413), toggle-thumb shadow (:715), success-circle shadow (:1491), "Go Home" border/text (:1532/1545) — all should switch to white/grey (`#FFFFFF→#999999`) for silver context.
- `karatly_circle.dart:44` silver badge gradient is dark blue-grey (`#5C6A7B→#151B23`) — should be light grey (`#E0E0E0→#7A7A7A`) to match React.

### Diamond (accent should be `#3AC7FF → #0073CE`)
- `diamond_card.dart:113` — plain gray border, no glow; React adds a blue border (`#0084FF`) plus a soft blue glow shadow.
- `diamond_card.dart:293` — "Add to Cart" uses generic Tailwind blue (`#2563EB→#1D4ED8`) instead of the brand diamond gradient (`#0084FF→#004F99`).
- `diamond_card.dart:194-215` — shade/luster tags colored amber/purple instead of a uniform blue pill (`#006CD2`).
- `diamond_viewer_modal.dart` — no loading spinner/progress bar while 360° frames load; React shows a gold-bordered spinner with a gradient progress fill.
- `diamond_payment_success_screen.dart` — background gradient, amount-value color, and two content cards (Invoice Info, Shipment Address) present in React are all missing or wrong-colored; button row shows 2 buttons vs React's single full-width CTA.
- Reservation countdown (`reservation_countdown.dart`) is correctly on-brand (`#3AC7FF`) already — no action needed there.

---

## 6. KYC / Payment / Certificates

- **KYC verification** (`kyc_verification_screen.dart`): status pills use opaque solid fills instead of React's translucent tints (`bg-color/15`); OCR upload box border is solid instead of dashed; the Aadhaar auto/manual chooser (gradient icon buttons + manual-OCR-upload path) is entirely missing — Flutter jumps straight to OTP. Completion modal is missing the serif headline font, the coin-burst particle animation, glow-blur decoration, and backdrop blur that React uses.
- **KYC modals** (`kyc_action_prompt_modal.dart`) are gold-only — React has 3 full color variants for gold/silver/diamond (border, gradient, icon, badge, CTA all shift per metal). Also missing: glow-blur decoration, close-X button, trailing arrow icon on the CTA, and uses bottom-sheet corners (`topLeft/topRight 50`) instead of React's uniform 26px floating-card radius. `kyc_limit_modal.dart` computes an `isSilver` flag but never applies it.
- **Payment gateway** (`payment_gateway_screen.dart`) is a plain AppBar+WebView; React presents this as a bottom-sheet card (40px top radius, drag handle, fee summary, gradient "Proceed to Pay" button, security note) — `embedded_payment_gateway.dart` is closer but still diverges: the KYC-limit error is a full-screen modal dialog in Flutter vs an inline banner in React.
- **Payment methods** (`payment_methods_screen.dart`): security footer is a rectangle (12px radius) vs React's 40px pill; bank avatar is a 36px rounded-square vs React's 40px circle; primary-border green differs (`#4CAF50` vs React `#15EE01`); submit-button gradient hex differs entirely from the brand gradient.
- **Transfer / Rewards**: Transfer's submit button isn't pill-shaped like React's; Rewards' gift icon is a flat solid circle with a Material icon instead of React's gradient circle with custom line art.
- **Certificates** (Gold/Silver/Diamond/Audit): per-metal accent colors are already correct here. Remaining gaps: the "Go Home" back button loses its text label (icon-only circle vs React's labeled pill); the zoom toolbar (Minus/Fit/Plus/Download) is reduced to pinch-zoom + Download only; loading state uses a generic spinner instead of a shaped skeleton placeholder.
- **PaymentReturn**: success icon is a static `Icons.check` instead of an animated SVG path-draw; all staggered entrance animations present in React are absent.

---

## 7. Settings / Static Pages

- **How It Works** (`how_it_works_screen.dart`): icon+text laid out as a Row vs React's vertical stack; icon color `#F7CD57` vs React `#EAB308`; step-number font 32px solid vs React 36px at 30% opacity; card gap 20px vs React 24px.
- **Terms** (`terms_screen.dart`): avatar is a flat "K" circle vs React's gold-gradient circle with full "KARATLY" wordmark; info card is solid vs React's gradient background; terms text box has no fixed height/border vs React's fixed 325px scrollable bordered box.
- **TermsOfUse / TrademarkNotice / WhyKaratly**: recurring `#F7CD57` used where React specifically uses `#FBBF24` (a slightly different yellow) for these particular pages' accent headings — worth confirming with design whether this is intentional page-level variation or should be unified.
- **Security** (`security_screen.dart`): notif-button border wrong color (`#7388A5` vs `#E8B438`); "Active Session"/"Session Policy" render as two separate cards vs React's single card with an internal divider; badge radius/size off (8px/11px vs React pill/9px).
- **Help Center**: chevron icon is `chevron_left` where React shows a `ChevronDown` (wrong glyph, not just style).
- **Footer**: copyright line is missing the "©" symbol in `home_screen.dart:1326`.

---

## 8. Prioritized Punch List

**P0 — Structural/systemic (fix first, unlocks consistency everywhere):**
1. Build a shared `MetalTheme` helper (accent color + 2-stop and 3-stop gradients for gold/silver/diamond) and replace every hardcoded `AppTheme.gold` in silver/diamond-context code paths (§5 lists ~7 in `sell_screen.dart` alone, plus `karatly_circle.dart:44`, `diamond_card.dart`).
2. Style the Gold/Silver **SIP flow** (`sip_screen.dart`) — currently a placeholder; this is the single biggest missing surface.
3. Build the dedicated **Silver Sell** and **Silver SIP** screens (currently empty folders, silently falling back to gold screens).
4. Fix the `BrandCard._parseColor()` bug so brand tiles render their intended distinct colors, and either reconcile `brands_screen.dart` with the shared `BrandCard`/mock data or confirm the divergence is intentional.

**P1 — High-visual-impact polish:**
5. Reinstate the missing glow/blur decoration (GoldPriceCard, CategoryCard, KYC modals/completion, OTP shield modal, success screens) — a `GlowBackdrop` widget covers most of these in one shot.
6. Correct the success-state glow intensity app-wide (`rgba(247,205,87,.18)` blur 40, not alpha .4/blur 30/spread 10).
7. Fix radius drift on the highest-traffic cards: sell/holdings/rate cards (10px, not 16), success detail cards (28px, not 20), security/pill rows (40-50px, not 16).
8. Fix the dead-code `ShaderMask` in `sell_selection_screen.dart:110-121` (one-line fix, restores the gold gradient text).

**P2 — Screen-level detail fixes:** everything else itemized in §3, §4, §6, §7 (typography sizes, icon glyph swaps, specific hex corrections, missing secondary CTAs on success screens, Profile screen metric-card/menu-row styling).

---

*Report generated by comparing every file in the lists above via full reads — no code changes have been made. This document is a starting point for an implementation plan; nothing in the Flutter or React source was modified.*
