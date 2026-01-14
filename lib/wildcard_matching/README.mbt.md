# Wildcard Matching

## Overview

Match a string against a pattern containing wildcards:

- `?` matches any single character
- `*` matches any sequence of characters (including empty)

This package uses dynamic programming with space optimization.

- **Time**: O(n × m)
- **Space**: O(m)
- **Key Feature**: Handles the tricky `*` wildcard correctly

## The Key Insight

```
Problem: Does pattern "a*b?c" match text "aXXXbYc"?

The tricky part is `*` - it can match any length!

DP insight:
  dp[i][j] = does text[0..i) match pattern[0..j)?

  For pattern[j-1] == '*':
    - '*' matches empty: dp[i][j-1] (skip the star)
    - '*' matches one more char: dp[i-1][j] (consume text char, keep star)

  For pattern[j-1] == '?' or exact match:
    - Must match current chars: dp[i-1][j-1]

Space optimization: Only need previous row, so O(m) space!
```

## Visual: DP Table

```
Pattern: "a*c"
Text:    "abc"

DP table (dp[i][j] = text[0..i) matches pattern[0..j)):

         ""    "a"   "a*"   "a*c"
    ""   T     F      F       F
    "a"  F     T      T       F
    "ab" F     F      T       F
    "abc"F     F      T       T  ← Answer!

Key transitions:
  dp[1][1] = T because 'a' == 'a'
  dp[1][2] = T because '*' matches empty
  dp[2][2] = T because '*' matches 'b'
  dp[3][2] = T because '*' matches 'bc'
  dp[3][3] = T because 'c' == 'c' and dp[2][2] = T
```

## Algorithm

```
wildcard_match(text, pattern):
  m = pattern.length

  // dp[j] = does current text prefix match pattern[0..j)?
  dp = array of m+1 booleans, all false
  dp[0] = true  // Empty matches empty

  // Handle leading stars (they can match empty)
  for j = 1 to m:
    if pattern[j-1] == '*':
      dp[j] = dp[j-1]
    else:
      break

  // Process each text character
  for i = 1 to text.length:
    prev = dp[0]  // dp[i-1][0]
    dp[0] = false  // Non-empty text can't match empty pattern

    for j = 1 to m:
      temp = dp[j]  // Save dp[i-1][j] for next iteration

      if pattern[j-1] == '*':
        // Match empty (dp[j-1]) OR extend previous match (dp[j])
        dp[j] = dp[j-1] || dp[j]
      else if pattern[j-1] == '?' || pattern[j-1] == text[i-1]:
        // Single char match: diagonal
        dp[j] = prev
      else:
        dp[j] = false

      prev = temp

  return dp[m]
```

## Example Usage

```mbt check
///|
test "wildcard basic" {
  inspect(@wildcard_matching.wildcard_match("aaabxc", "a*b?c"), content="true")
  inspect(@wildcard_matching.wildcard_match("abc", "a?c"), content="true")
}
```

```mbt check
///|
test "wildcard star" {
  inspect(@wildcard_matching.wildcard_match("", "*"), content="true")
  inspect(@wildcard_matching.wildcard_match("hello", "h*o"), content="true")
}
```

## More Examples

```mbt check
///|
test "wildcard edge cases" {
  // Empty pattern only matches empty text
  inspect(@wildcard_matching.wildcard_match("", ""), content="true")
  inspect(@wildcard_matching.wildcard_match("a", ""), content="false")

  // Multiple stars
  inspect(@wildcard_matching.wildcard_match("abcde", "a*c*e"), content="true")
  inspect(@wildcard_matching.wildcard_match("abcde", "*****"), content="true")

  // Question marks
  inspect(@wildcard_matching.wildcard_match("abc", "???"), content="true")
  inspect(@wildcard_matching.wildcard_match("ab", "???"), content="false")
}
```

## Algorithm Walkthrough

```
Pattern: "a*b?c"
Text:    "aXXbYc"

Initialize dp for empty text:
  j:      0    1    2    3    4    5
  pat:    ""   "a"  "a*" "a*b" "a*b?" "a*b?c"
  dp:     T    F    F    F     F      F

Process 'a' (i=1):
  j=1: 'a'=='a', prev=T → dp[1]=T
  j=2: '*', dp[1]||dp[2] = T||F = T
  j=3: 'b'!='a' → dp[3]=F
  dp:     F    T    T    F     F      F

Process 'X' (i=2):
  j=1: 'a'!='X' → dp[1]=F
  j=2: '*', dp[1]||dp[2] = F||T = T
  j=3: 'b'!='X' → dp[3]=F
  dp:     F    F    T    F     F      F

Process 'X' (i=3):
  j=2: '*', dp[1]||dp[2] = F||T = T
  dp:     F    F    T    F     F      F

Process 'b' (i=4):
  j=2: '*', dp[1]||dp[2] = F||T = T
  j=3: 'b'=='b', prev=T → dp[3]=T
  j=4: '?', prev=T → dp[4]=T
  dp:     F    F    T    T     F      F

Wait, let me redo j=4:
  j=4: '?' matches any char, prev=dp[i-1][j-1]=dp[3][3]=F → dp[4]=F

Process 'Y' (i=5):
  j=2: '*', dp[1]||dp[2] = F||T = T
  j=3: 'b'!='Y', dp[3]=F
  j=4: '?', prev=dp[4][3]=T → dp[4]=T
  dp:     F    F    T    F     T      F

Process 'c' (i=6):
  j=2: '*', dp[1]||dp[2] = F||T = T
  j=3: 'b'!='c' → dp[3]=F
  j=4: '?', prev=F → dp[4]=F
  j=5: 'c'=='c', prev=T → dp[5]=T
  dp:     F    F    T    F     F      T  ← Match!
```

## Common Applications

### 1. File Globbing
```
Match files: *.txt, test?.py, **/*.js
Shell uses wildcards for file pattern matching.
```

### 2. Search Queries
```
Database LIKE queries: WHERE name LIKE 'J%n'
'%' in SQL = '*' here, '_' in SQL = '?' here
```

### 3. Log Analysis
```
Filter log lines matching patterns.
"ERROR: * failed at line ?" matches various error messages.
```

### 4. Input Validation
```
Check if input matches expected format.
"???-???-????" for phone number patterns.
```

## Complexity Analysis

| Operation | Time | Space |
|-----------|------|-------|
| Match | O(n × m) | O(m) |

Where n = text length, m = pattern length.

## Wildcard Matching vs Regex

```
Wildcards (this package):
  - ? = exactly one char
  - * = zero or more chars
  - Simple, O(nm) time

Regular Expressions:
  - Much more powerful (groups, alternatives, etc.)
  - Can have exponential worst case
  - More complex to implement

Choose wildcards when:
  - You only need ? and * matching
  - Performance predictability matters
```

## Implementation Notes

- Space optimization: Rolling array reduces O(nm) space to O(m)
- Handle leading `*` specially (can match empty)
- Track `prev` for diagonal access in space-optimized version
- Multiple consecutive `*` can be collapsed to single `*`

## Edge Cases

```
1. Empty pattern: Only matches empty text
2. Pattern is only stars: Matches any text
3. Pattern longer than text: Only matches if all extra chars are *
4. Consecutive stars: Equivalent to single star
5. Star at end: Matches any suffix
```

