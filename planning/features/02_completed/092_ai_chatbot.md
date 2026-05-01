# Feature — AI Chatbot Widget (Claude-powered)
**Created:** 2026-03-26 | **Updated:** 2026-03-26 | **Mode:** STUDIO | **Status:** COMPLETE
**Priority:** High | **Complexity:** Low-Medium
**Flag:** `CHATBOT_ENABLED=true` (dart-define in client.json)

---

## Objective

A floating chat bubble on the public site. Powered by Claude API via a Supabase Edge Function.
The bot is pre-seeded with the business's `business_config` data (name, hours, services, prices,
booking URL) so it can answer common questions without the client ever touching it.

---

## What's Already in Place

- `business_config` table — name, hours, services, address already loaded in `HomeController`.
  The Edge Function queries these directly (service_role key) — no new columns.
- `GetMaterialApp.builder` in `main.dart` already wraps the child in a `Stack` for the GDPR
  banner. Chatbot bubble slots into the same Stack — confirmed pattern.
- `AppEnv` pattern established. `chatbotEnabled` not yet in `app_env.dart` — must be added.
- Admin route pattern: routes use `/admin` prefix — `Get.currentRoute.startsWith('/admin')`
  is safe for hiding the bubble on all admin screens.
- `services` table queried in `HomeController` — Edge Function uses the same table directly.

---

## Schema Changes

None for v1. Bot reads existing `business_config` and `services` tables.

Optional v2 (do not implement now):
```sql
-- 094_chat_logs.sql (deferred)
CREATE TABLE chat_logs (id uuid, session_id text, role text, content text, created_at timestamptz);
```

---

## Edge Function

**`chat/index.ts`** — new public Edge Function (no JWT required).

Flow:
1. Accept `{ message: string, session_id: string }`.
2. Fetch `business_config` + `services` once per cold start (cache in module-level variable).
3. Build system prompt from live DB data:
   ```ts
   `You are a helpful assistant for ${config.business_name}.
   Answer questions only about this business.
   Business hours: ${JSON.stringify(hours)}
   Services: ${services.map(s => `${s.name} - $${s.price}`).join(', ')}
   Booking: ${Deno.env.get('SITE_URL')}/booking
   Keep answers to 1-3 sentences. If unsure, direct them to book or call.`
   ```
4. Call Claude API — model: `claude-haiku-4-5-20251001` (fast, cheap).
   Keep last 10 messages max to bound token cost.
5. Return `{ reply: string }`.

Rate limiting: track requests per `session_id` in a module-level Map.
Reset on cold start (sufficient for v1 — 20 req/min per session).

Secrets needed: `ANTHROPIC_API_KEY` (push via `deliver.sh`).

---

## Flutter Changes

### `app_env.dart`
```dart
static const chatbotEnabled = bool.fromEnvironment(
  'CHATBOT_ENABLED',
  defaultValue: false,
);
```
Note: use `static const`, not `static bool get` — consistent with existing flags in `app_env.dart`.

### New: `lib/modules/chatbot/`
- `chatbot_message_model.dart` — `{ role, content }` (no timestamp needed in v1)
- `chatbot_controller.dart` — `sessionId` (uuid), `messages` obs list, `isLoading` obs,
  `sendMessage(String text)` calls `chat` Edge Function via `SupabaseService.client.functions.invoke()`
- `chatbot_bubble.dart` — `FloatingActionButton`-style icon (bottom-right), opens `ChatbotSheet`
- `chatbot_sheet.dart` — `DraggableScrollableSheet` or `showModalBottomSheet` with message
  list + `TextField` + send button

`ChatbotController` uses `Get.put` inside `ChatbotBubble.onInit` (no separate binding needed).

### `main.dart` — `GetMaterialApp.builder`
Current builder wraps child in a Stack for GDPR. Extend the same Stack:
```dart
builder: (context, child) {
  Widget result = child ?? const SizedBox.shrink();
  if (AppEnv.gdprEnabled) result = Stack(children: [result, const GdprBanner()]);
  if (AppEnv.chatbotEnabled) result = Stack(children: [result, const ChatbotBubble()]);
  return result;
},
```
`ChatbotBubble.build` returns `SizedBox.shrink()` when on an admin route:
```dart
if (Get.currentRoute.startsWith('/admin')) return const SizedBox.shrink();
```

---

## client.json / deliver.sh

```json
"CHATBOT_ENABLED": "true",
"ANTHROPIC_API_KEY": "sk-ant-..."
```

`deliver.sh`: deploy `chat` Edge Function + push `ANTHROPIC_API_KEY` secret when
`CHATBOT_ENABLED=true`. Add to the module-conditional deploy block (same pattern as
`send-reminders` cron check).

---

## Delivery Guide

New section in delivery guide: enabling chatbot, API key setup, Haiku cost estimate
(~$0.001/1k tokens — negligible for most clients), system prompt customisation (see `100_ai_chatbot_full`
for the full-tier upgrade path).

---

## Acceptance Criteria

- [ ] `CHATBOT_ENABLED=false` (default) — no bubble, no import of chatbot module
- [ ] `CHATBOT_ENABLED=true` — bubble appears on all public routes
- [ ] Bubble hidden on all `/admin*` routes
- [ ] Bot answers correctly about hours, services, prices from live `business_config`
- [ ] Conversation history maintained within session (page reload resets)
- [ ] 429 returned after rate limit; Flutter shows "Try again in a moment"
- [ ] No JWT required (public endpoint)
- [ ] All files ≤ 300 lines
