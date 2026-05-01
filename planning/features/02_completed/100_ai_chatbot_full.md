# Feature — AI Chatbot Full (Upgrade from Lite)
**Created:** 2026-03-26 | **Updated:** 2026-03-26 | **Mode:** FLOW | **Status:** COMPLETE
**Priority:** Low | **Complexity:** Low (upgrade path)
**Prerequisite:** `092_ai_chatbot.md` (Lite) must be implemented first — confirmed complete.
**Flag:** `CHATBOT_MODE=full` (dart-define) + `CHATBOT_ENABLED=true` (both required for Full tier)

---

## Objective

Upgrade the Lite chatbot to a "Full" tier with a custom, business-specific system prompt editable
from the admin panel. The code delta from Lite is minimal — the value is in prompt engineering.

| | Lite | Full |
|--|------|------|
| System prompt | Auto-generated from DB | Custom prompt editable in Admin → Business Config |
| Welcome message | Hardcoded default | Editable in Admin → Business Config |
| Tone | Generic helpful | Business-specific voice |
| Fine-tuning | None | Monthly prompt review (Premium Management add-on) |
| Model | claude-haiku-4-5 | claude-haiku-4-5 (same — cost unchanged) |

---

## What's Already in Place

- `chat/index.ts` — `cachedSystemPrompt` is module-level with NO TTL. Must add TTL before
  adding admin-editable prompt or updates silently have no effect until cold start (see Gap 2).
- `business_config_view.dart` — **293 lines**. Adding even a small section exceeds 300.
  `_ChatbotSection` extraction to `chatbot_config_section.dart` is **mandatory**, not optional.
- `MasterController.saveConfig(Map<String, dynamic>)` — existing method handles any
  `business_config` update. **No new method needed** — call `saveConfig` directly from the widget.
- `HomeController.content` — generic `Map<String, dynamic>` of the full `business_config` row.
  Welcome message accessed as `Get.find<HomeController>().content['chatbot_welcome_message']`.
- `AppEnv.chatbotEnabled` — `static const bool.fromEnvironment('CHATBOT_ENABLED')`. Must NOT
  be changed (Lite clients depend on it). Full tier adds a NEW flag alongside it.

---

## Schema Changes

**Migration: `095_chatbot_full.sql`** (next after 094_stripe_invoicing.sql)

```sql
ALTER TABLE business_config ADD COLUMN chatbot_system_prompt   text;
ALTER TABLE business_config ADD COLUMN chatbot_welcome_message text
  DEFAULT 'Hi! How can I help you today?';
```

---

## Edge Function Changes

**`chat/index.ts`** — two changes:

### 1. Add TTL to system prompt cache

`cachedSystemPrompt` currently has no expiry — admin edits never take effect until cold start.
Add a timestamp:
```ts
let cachedSystemPrompt: string | null = null
let cacheExpiresAt = 0
const CACHE_TTL_MS = 10 * 60 * 1000  // 10 minutes

// in buildSystemPrompt, replace the cache check:
if (cachedSystemPrompt && Date.now() < cacheExpiresAt) return cachedSystemPrompt
// after building the prompt:
cacheExpiresAt = Date.now() + CACHE_TTL_MS
```

### 2. Include `chatbot_system_prompt` in DB query + use when set

Add `chatbot_system_prompt, chatbot_welcome_message` to the `business_config` select:
```ts
db.from('business_config').select('business_name, address, phone, chatbot_system_prompt').limit(1).single()
```

Override the auto-generated prompt when a custom one is set:
```ts
const autoPrompt = buildAutoPrompt(config, services, hours, siteUrl)
cachedSystemPrompt = config?.chatbot_system_prompt
  ? `${config.chatbot_system_prompt}\n\nBusiness context (always accurate):\n${autoPrompt}`
  : autoPrompt
```

No new Edge Function needed.

---

## Flutter Changes

### `app_env.dart` — add `chatbotFull` alongside existing `chatbotEnabled`

Do NOT modify `chatbotEnabled` — Lite clients depend on it as `static const`. Add a new flag:
```dart
// chatbotEnabled (existing, unchanged) — controls bubble visibility for both Lite and Full
static const chatbotFull = String.fromEnvironment('CHATBOT_MODE') == 'full';
```
`main.dart` needs no changes — `AppEnv.chatbotEnabled` still controls the bubble.
Full clients set BOTH `CHATBOT_ENABLED=true` AND `CHATBOT_MODE=full` in `client.json`.

### `ChatbotSheet` — welcome message when Full

When `AppEnv.chatbotFull` and messages list is empty, show welcome message from `HomeController`:
```dart
// In ChatbotSheet.build, before the message list:
final welcome = AppEnv.chatbotFull
    ? (Get.find<HomeController>().content['chatbot_welcome_message'] as String? ??
       'Hi! How can I help you today?')
    : 'Ask me anything about our services, hours, or how to book!';
// Use `welcome` in the empty-state Text widget
```

### `business_config_view.dart` — add `_ChatbotSection` (extract required)

Add to `ListView` children, gated on `AppEnv.chatbotFull`:
```dart
if (AppEnv.chatbotFull) ...[
  const SizedBox(height: ESpacing.xl),
  ChatbotConfigSection(controller: controller),
],
```

### `chatbot_config_section.dart` (new file — mandatory extract)

`StatefulWidget` with two `TextEditingController`s:
- Welcome message field (single line)
- System prompt field (multiline, 6 lines, with hint showing example prompt)
- Save button → `controller.saveConfig({'chatbot_system_prompt': prompt, 'chatbot_welcome_message': msg})`

Use `controller.config.value` (the `business_config` map from `MasterController`) to pre-fill
fields on init.

---

## client.json / deliver.sh

```json
"CHATBOT_ENABLED": "true",
"CHATBOT_MODE": "full"
```

Both flags required for Full. Lite only needs `CHATBOT_ENABLED=true`.

`deliver.sh` — update conditional deploy to cover both Lite and Full:
```bash
# Deploy chat fn for both Lite (CHATBOT_ENABLED) and Full (CHATBOT_MODE=full)
if [[ "${CHATBOT_ENABLED:-false}" == "true" || "${CHATBOT_MODE:-}" == "full" ]]; then
  deploy_fn "chat"
fi
```
Remove (or keep alongside) the existing `CHATBOT_ENABLED` block — merge into one condition.

---

## Delivery Workflow (what you actually do for Full tier)

1. Interview client: tone, common objections, top upsells, what NOT to say.
2. Write the custom system prompt (30-60 min craft work).
3. Paste into Admin → Business Config → Chatbot.
4. Test 10+ realistic queries in the live chat bubble.
5. Monthly (Premium Management $299/mo): review patterns, refine prompt.

---

## Acceptance Criteria

- [ ] `CHATBOT_ENABLED=false`, `CHATBOT_MODE` unset — no chatbot
- [ ] `CHATBOT_ENABLED=true`, `CHATBOT_MODE` unset — Lite mode (auto-generated prompt)
- [ ] `CHATBOT_ENABLED=true`, `CHATBOT_MODE=full` — Full mode, Admin chatbot section visible
- [ ] Custom system prompt used when set; auto-generated fallback when null
- [ ] Admin prompt update takes effect within 10 minutes (cache TTL)
- [ ] Welcome message shown in chat sheet before first user message (Full only)
- [ ] Saving prompt in admin persists to `business_config`
- [ ] `business_config_view.dart` ≤ 300 lines after section extraction
- [ ] All files ≤ 300 lines
