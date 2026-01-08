#!/usr/bin/env bash
# Validate ITD structure and content quality
# Usage: validate-itd.sh <itd-file>

set -euo pipefail

ITD_FILE="${1:-}"

if [ -z "$ITD_FILE" ] || [ ! -f "$ITD_FILE" ]; then
  echo "❌ Usage: validate-itd.sh <itd-file>"
  exit 1
fi

ERRORS=0
WARNINGS=0

echo "Validating ITD: $ITD_FILE"
echo ""

# Check required sections
check_section() {
  local section="$1"
  if ! grep -q "^## $section" "$ITD_FILE"; then
    echo "❌ Missing: ## $section"
    ((ERRORS++))
    return 1
  else
    echo "✅ Found: ## $section"
    return 0
  fi
}

# Validate Problem section
echo "=== Problem Section ==="
if check_section "Problem"; then
  # Check problem doesn't contain solution keywords
  PROBLEM_TEXT=$(grep -A 10 "^## Problem" "$ITD_FILE" | head -10)
  if echo "$PROBLEM_TEXT" | grep -iE "(add|implement|use|choose).*(flag|table|api|endpoint|database|framework)" >/dev/null; then
    echo "⚠️  Problem may be phrased as solution. Review required."
    echo "   Found solution keywords in problem statement."
    ((WARNINGS++))
  fi
fi
echo ""

# Validate Options section
echo "=== Options Section ==="
if check_section "Options Considered"; then
  # Count options
  OPTION_COUNT=$(grep -c "^\s*[0-9]\." "$ITD_FILE" || echo "0")
  if [ "$OPTION_COUNT" -lt 2 ]; then
    echo "❌ Need at least 2 options. Found: $OPTION_COUNT"
    ((ERRORS++))
  else
    echo "✅ Found $OPTION_COUNT options"
  fi
  
  # Check selected option marked
  if ! grep -q "(selected)" "$ITD_FILE"; then
    echo "⚠️  No option marked as (selected)"
    ((WARNINGS++))
  else
    echo "✅ Selected option marked"
  fi
fi
echo ""

# Validate Reasoning section
echo "=== Reasoning Section ==="
if check_section "Reasoning"; then
  # Check for tradeoff keywords
  REASONING_TEXT=$(grep -A 30 "^## Reasoning" "$ITD_FILE" | head -30)
  if ! echo "$REASONING_TEXT" | grep -iE "(but|however|tradeoff|cost|limitation|rejected)" >/dev/null; then
    echo "⚠️  Reasoning may lack tradeoffs. Review required."
    echo "   Look for: advantages, tradeoffs, why alternatives rejected"
    ((WARNINGS++))
  else
    echo "✅ Contains tradeoff language"
  fi
  
  # Check for cost analysis (if tool selection)
  if echo "$REASONING_TEXT" | grep -iE "(postgres|mongodb|redis|snowflake|aws|azure)" >/dev/null; then
    if ! echo "$REASONING_TEXT" | grep -iE "(cost|price|free|paid|people cost)" >/dev/null; then
      echo "⚠️  Tool selection detected but no cost analysis found"
      ((WARNINGS++))
    else
      echo "✅ Cost analysis present"
    fi
  fi
fi
echo ""

# Check References (optional but recommended)
echo "=== References Section ==="
if grep -q "^## References" "$ITD_FILE"; then
  REF_COUNT=$(grep -A 10 "^## References" "$ITD_FILE" | grep -c "^-" || echo "0")
  if [ "$REF_COUNT" -eq 0 ]; then
    echo "⚠️  References section empty (optional but recommended)"
    ((WARNINGS++))
  else
    echo "✅ Found $REF_COUNT references"
  fi
else
  echo "⚠️  No References section (optional but recommended)"
  ((WARNINGS++))
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo "✅ Validation passed: No errors or warnings"
  exit 0
elif [ "$ERRORS" -eq 0 ]; then
  echo "⚠️  Validation passed with $WARNINGS warning(s)"
  exit 0
else
  echo "❌ Validation failed: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
fi

