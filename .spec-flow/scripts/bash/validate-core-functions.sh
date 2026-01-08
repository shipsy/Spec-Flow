#!/usr/bin/env bash
# Validate Core Functions structure and content quality
# Usage: validate-core-functions.sh <core-functions-file>

set -euo pipefail

CF_FILE="${1:-}"

if [ -z "$CF_FILE" ] || [ ! -f "$CF_FILE" ]; then
  echo "❌ Usage: validate-core-functions.sh <core-functions-file>"
  exit 1
fi

ERRORS=0
WARNINGS=0

echo "Validating Core Functions: $CF_FILE"
echo ""

# Check required sections
check_section() {
  local section="$1"
  if ! grep -q "^## $section" "$CF_FILE"; then
    echo "❌ Missing: ## $section"
    ((ERRORS++))
    return 1
  else
    echo "✅ Found: ## $section"
    return 0
  fi
}

# Validate document structure
echo "=== Document Structure ==="
check_section "Core Function Index"
check_section "Core Functions"
check_section "Functional Block Diagram"
check_section "Platform Integration"
echo ""

# Count Core Functions
echo "=== Core Functions Count ==="
CF_COUNT=$(grep -c "^### CF-" "$CF_FILE" || echo "0")
if [ "$CF_COUNT" -lt 1 ]; then
  echo "❌ No Core Functions defined (need at least 1)"
  ((ERRORS++))
else
  echo "✅ Found $CF_COUNT Core Functions"
fi
echo ""

# Check function name length (max 3 significant words)
echo "=== Function Name Validation ==="
while IFS= read -r line; do
  # Extract function name after "CF-XX: "
  FUNC_NAME=$(echo "$line" | sed 's/^### CF-[0-9]*: //')
  # Count significant words (exclude articles and prepositions)
  WORD_COUNT=$(echo "$FUNC_NAME" | tr ' ' '\n' | grep -ivE "^(a|an|the|of|for|to|in|on|at|by|with)$" | wc -l | xargs)
  
  if [ "$WORD_COUNT" -gt 3 ]; then
    echo "⚠️  Function name too long: '$FUNC_NAME' ($WORD_COUNT significant words, max 3)"
    ((WARNINGS++))
  else
    echo "✅ Valid: '$FUNC_NAME' ($WORD_COUNT words)"
  fi
done < <(grep "^### CF-" "$CF_FILE")
echo ""

# Check for technical jargon in descriptions
echo "=== Technical Jargon Check ==="
JARGON_PATTERNS="service|repository|middleware|factory|controller|DTO|entity|endpoint|API|database|schema|query|HTTP|REST|GraphQL|SQL|cache|queue"
JARGON_COUNT=$(grep -iE "$JARGON_PATTERNS" "$CF_FILE" | grep -v "^#" | grep -v "^|" | wc -l || echo "0")

if [ "$JARGON_COUNT" -gt 0 ]; then
  echo "⚠️  Found $JARGON_COUNT lines with potential technical jargon"
  echo "   Review these lines for user-understandable language:"
  grep -inE "$JARGON_PATTERNS" "$CF_FILE" | grep -v "^#" | head -5
  ((WARNINGS++))
else
  echo "✅ No obvious technical jargon detected"
fi
echo ""

# Check for block diagram
echo "=== Block Diagram Check ==="
if grep -q '```mermaid' "$CF_FILE"; then
  DIAGRAM_COUNT=$(grep -c '```mermaid' "$CF_FILE" || echo "0")
  echo "✅ Found $DIAGRAM_COUNT Mermaid diagram(s)"
  
  # Check if diagram references existing blocks
  if grep -A 20 '```mermaid' "$CF_FILE" | grep -q "Existing"; then
    echo "✅ Diagram shows existing platform blocks"
  else
    echo "⚠️  Diagram may not show existing platform integration"
    ((WARNINGS++))
  fi
else
  echo "❌ No Mermaid diagram found"
  ((ERRORS++))
fi
echo ""

# Check for Input/Output in each function
echo "=== Input/Output Validation ==="
INPUT_COUNT=$(grep -c "^\*\*Input\*\*:" "$CF_FILE" || echo "0")
OUTPUT_COUNT=$(grep -c "^\*\*Output\*\*:" "$CF_FILE" || echo "0")

if [ "$INPUT_COUNT" -lt "$CF_COUNT" ]; then
  echo "⚠️  Some functions missing Input section ($INPUT_COUNT found, $CF_COUNT expected)"
  ((WARNINGS++))
else
  echo "✅ All functions have Input section"
fi

if [ "$OUTPUT_COUNT" -lt "$CF_COUNT" ]; then
  echo "⚠️  Some functions missing Output section ($OUTPUT_COUNT found, $CF_COUNT expected)"
  ((WARNINGS++))
else
  echo "✅ All functions have Output section"
fi
echo ""

# Check for Non-Obvious Logic
echo "=== Non-Obvious Logic Check ==="
NON_OBVIOUS_COUNT=$(grep -c "^\*\*Non-Obvious Logic\*\*:" "$CF_FILE" || echo "0")
if [ "$NON_OBVIOUS_COUNT" -lt "$CF_COUNT" ]; then
  echo "⚠️  Some functions missing Non-Obvious Logic section ($NON_OBVIOUS_COUNT found, $CF_COUNT expected)"
  ((WARNINGS++))
else
  echo "✅ All functions have Non-Obvious Logic section"
fi
echo ""

# Check for traceability
echo "=== Traceability Check ==="
if grep -q "^\*\*Traces to\*\*:" "$CF_FILE" || grep -q "Traceability Matrix" "$CF_FILE"; then
  echo "✅ Traceability information present"
else
  echo "⚠️  No traceability to requirements found"
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

