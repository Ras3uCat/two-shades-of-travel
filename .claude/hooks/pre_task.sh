#!/usr/bin/env bash
# SessionStart hook — validates active feature file and enforces STUDIO protocol

ACTIVE_DIR="planning/features/01_active"
ACTIVE_FILE=$(ls "$ACTIVE_DIR"/*.md 2>/dev/null | head -n 1)

if [ -z "$ACTIVE_FILE" ]; then
  echo "⚠️  No active feature file found in $ACTIVE_DIR. Move a feature from 00_backlog to begin."
  exit 0
fi

# 1. Enforcement of STUDIO protocol
if grep -qi "Mode: STUDIO" "$ACTIVE_FILE"; then
  if ! grep -qi "Acceptance Criteria" "$ACTIVE_FILE"; then
    echo "❌ ARCHITECT BLOCK: STUDIO task detected but Acceptance Criteria are missing from $ACTIVE_FILE."
    echo "   Action: Complete the feature file before implementation."
    exit 1
  fi
  echo "✅ STUDIO feature file verified."
fi

# 2. Skill & Context Audit
if grep -qi "stripe\|payment" "$ACTIVE_FILE"; then
  echo "⚖️  ARCHITECT ADVISORY: Task involves Payments. Ensure .claude/skills/stripe-checkout-subscriptions/ is loaded."
fi

if grep -qi "flutter\|widget\|screen\|view" "$ACTIVE_FILE"; then
  echo "📱 ARCHITECT ADVISORY: UI Task. AntiGravity should lead implementation."
fi

if grep -qi "supabase\|migration\|rls\|repository" "$ACTIVE_FILE"; then
  echo "🗄️  ARCHITECT ADVISORY: Backend Task. Load .claude/skills/backend-dev/ before proceeding."
fi

# 3. Clean Context Signal
echo ""
echo "--- 📋 MISSION START ---"
head -n 5 "$ACTIVE_FILE"
