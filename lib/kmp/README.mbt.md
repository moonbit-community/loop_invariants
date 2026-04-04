# KMP (Knuth-Morris-Pratt) String Matching

## What KMP Solves

KMP finds **all occurrences** of a pattern in a text in **O(n + m)** time:

- `n` = text length
- `m` = pattern length

It avoids re-checking characters by using a **failure function** (also called
the LPS array or prefix function).

## Why Naive Search Is Slow

Naive matching restarts at the next character every time a mismatch happens,
repeating many comparisons:

```
Text:    A A A A A A B
Pattern: A A A B

Naive attempts:
  pos 0: A A A ? -> mismatch at pos 3, restart from pos 1
  pos 1: A A A ? -> mismatch at pos 3, restart from pos 2
  pos 2: A A A ? -> mismatch at pos 3, restart from pos 3
  pos 3: A A A B -> match!

Total comparisons: 4 x 4 = 16 (though text is only 7 chars)
```

KMP avoids this by remembering which prefix characters were already matched.

---

## The Failure Function (LPS / Prefix Function)

For each position `i`, the failure value records:

```
fail[i] = length of the longest proper prefix of pattern[0..i+1)
          that is also a suffix of pattern[0..i+1)
```

A "proper" prefix excludes the full string itself.

### Step-by-Step Build for "ABACABA"

```
Step  i  prefix       border         fail[i]
----  -  ----------   ----------     -------
  0   0  "A"          (none)             0
  1   1  "AB"         (none)             0
  2   2  "ABA"        "A"                1
  3   3  "ABAC"       (none)             0
  4   4  "ABACA"      "A"                1
  5   5  "ABACAB"     "AB"               2
  6   6  "ABACABA"    "ABA"              3
```

Result: `fail = [0, 0, 1, 0, 1, 2, 3]`

At `i=6`, the longest border of `"ABACABA"` is `"ABA"` (length 3): the
first three characters equal the last three.

### Step-by-Step Build for "ABABAB"

```
Step  i  prefix         border   fail[i]
----  -  ----------     ------   -------
  0   0  "A"            (none)       0
  1   1  "AB"           (none)       0
  2   2  "ABA"          "A"          1
  3   3  "ABAB"         "AB"         2
  4   4  "ABABA"        "ABA"        3
  5   5  "ABABAB"       "ABAB"       4
```

Result: `fail = [0, 0, 1, 2, 3, 4]`

### How the Build Works (Incremental Rule)

```
fail[0] = 0 always.

To compute fail[i] (i >= 1):
  1. Start with k = fail[i-1]   (the border length of the previous prefix)
  2. While k > 0 and pattern[k] != pattern[i]:
         k = fail[k-1]           (fall back along border chain)
  3. If pattern[k] == pattern[i]:
         fail[i] = k + 1         (extend the border by one)
     Else:
         fail[i] = 0             (no border)
```

This is O(m) in total because `k` never exceeds `i` and the fallback steps
are amortised over all increments.

---

## Matching: How KMP Avoids Backtracking

Let `i` index the text and `j` index the pattern.

```
Rule:
  text[i] == pattern[j]  ->  advance both:  i++, j++
  text[i] != pattern[j]  ->  if j > 0: j = fail[j-1]
                              else:     i++
  j == m                 ->  record match at i-m, then j = fail[j-1]
```

The key property: **`i` never decreases**.  After any mismatch, instead of
moving `i` back, we move `j` back using the failure table, reusing the
characters we already know matched.

### Walkthrough: "ABABCABABAB" with pattern "ABAB"

```
Failure table for "ABAB": [0, 0, 1, 2]

Text:     A  B  A  B  C  A  B  A  B  A  B
Index:    0  1  2  3  4  5  6  7  8  9  10
          ^
i=0  j=0  A==A -> i=1, j=1
i=1  j=1  B==B -> i=2, j=2
i=2  j=2  A==A -> i=3, j=3
i=3  j=3  B==B -> i=4, j=4  ** match at 0 **
                  j = fail[3] = 2  (reuse "AB" already matched)

i=4  j=2  C!=A -> j = fail[1] = 0
i=4  j=0  C!=A -> i=5, j=0

i=5  j=0  A==A -> i=6, j=1
i=6  j=1  B==B -> i=7, j=2
i=7  j=2  A==A -> i=8, j=3
i=8  j=3  B==B -> i=9, j=4  ** match at 5 **
                  j = fail[3] = 2

i=9  j=2  A==A -> i=10, j=3
i=10 j=3  B==B -> i=11, j=4 ** match at 7 **
                  j = fail[3] = 2

End of text.  Matches at: [0, 5, 7]
```

Notice that `i` moved strictly forward from 0 to 11.  No character in the
text was examined more than twice.

---

## Overlapping Matches

```
Text:    A A A A
Pattern: A A

 pos 0: AA  match
 pos 1:  AA match
 pos 2:   AA match

Matches: [0, 1, 2]
```

KMP finds them all because after each match it falls back by
`fail[m-1]` rather than resetting `j` to 0.

---

## API Summary

```
compute_failure(pattern)    -> Array[Int]   // failure table, O(m)
prefix_function(pattern)    -> Array[Int]   // alias for compute_failure
kmp_search(text, pattern)   -> Array[Int]   // all matches, O(n+m)
kmp_find_first(text, pattern) -> Int        // first match or -1
kmp_count(text, pattern)    -> Int          // number of matches
compute_z_function(s)       -> Array[Int]   // Z-array, O(n)
z_search(text, pattern)     -> Array[Int]   // all matches via Z, O(n+m)
```

```mbt check
///|
test "kmp complete example" {
  let text = "ababcababa"
  let pattern = "aba"

  // All occurrences
  inspect(@kmp.kmp_search(text, pattern), content="[0, 5, 7]")

  // First occurrence
  inspect(@kmp.kmp_find_first(text, "cab"), content="4")
  inspect(@kmp.kmp_find_first(text, "xyz"), content="-1")

  // Count occurrences
  inspect(@kmp.kmp_count(text, pattern), content="3")

  // Failure function
  let fail = @kmp.compute_failure("ABAB")
  inspect(fail, content="[0, 0, 1, 2]")

  // Prefix function alias
  let pi = @kmp.prefix_function("ababa")
  inspect(pi, content="[0, 0, 1, 2, 3]")
}
```

---

## Z-Function (Alternative Tool)

The Z-function measures, at each position `i`, how long the substring
starting at `i` matches the prefix of the whole string.

### Diagram: Z-values for "AABXAAB"

```
String:   A  A  B  X  A  A  B
Index:    0  1  2  3  4  5  6
Z-value:  7  1  0  0  3  1  0
          |        |  |
          |        |  "AAB" matches prefix "AAB" (length 3)
          |        no match
          full string (by convention)
```

### Pattern Matching with Z

Build `S = pattern + "$" + text`.  Any position `i` with `Z[i] == m` is a
match start (at index `i - m - 1` in the text).

```
P = "AB"   T = "ABABAB"   S = "AB$ABABAB"

Index:   0  1  2  3  4  5  6  7  8
Char:    A  B  $  A  B  A  B  A  B
Z:       9  0  0  2  0  2  0  2  0
                   ^     ^     ^
                   Z==2 means "AB" matched -> text positions 0, 2, 4
```

```mbt check
///|
test "z-function example" {
  let z = @kmp.compute_z_function("AABXAAB")
  inspect(z[0], content="7")
  inspect(z[1], content="1")
  inspect(z[4], content="3")
  let matches = @kmp.z_search("ABABDABACDABABCABAB", "ABAB")
  inspect(matches.length(), content="3")
}
```

---

## Diagram: Why the Failure Table Saves Work

```
Pattern:  A  B  A  B
Fail:     0  0  1  2

Text:     A  B  A  B  D  ...
          j=0,1,2,3  -> full match at text[0..3]

After match, set j = fail[3] = 2.
The two characters "AB" at j=0,1 were already matched as the
suffix of the just-found match; we reuse them without rescanning.

Next char in text is D.
  text[4]='D' vs pattern[2]='A'  -> mismatch
  j = fail[1] = 0
  text[4]='D' vs pattern[0]='A'  -> mismatch, advance i

Total: i never went backward.
```

---

## Complexity

| Step        | Time   | Space         |
|-------------|--------|---------------|
| Build fail  | O(m)   | O(m)          |
| KMP search  | O(n)   | O(1) + fail   |
| Total       | O(n+m) | O(m)          |
| Z-function  | O(n)   | O(n)          |
| Z-search    | O(n+m) | O(n+m)        |

---

## Common Pitfalls

- **Empty pattern**: this implementation returns an empty match list.
- **Unicode details**: indexing in MoonBit strings is by UTF-16 code units.
  For grapheme-level matching, preprocess into code points first.
- **Case sensitivity**: comparisons are exact; normalize the strings if
  case-insensitive matching is needed.
- **Z[0] is always n**: by convention, `compute_z_function` sets `z[0]` to
  the full string length.

---

## When to Use KMP

- You need all (possibly overlapping) occurrences of one fixed pattern.
- The text is large and you want worst-case linear time.
- You want a simple O(m) preprocessing step.

## KMP vs Alternatives

| Algorithm    | Preprocess | Search    | Notes                         |
|--------------|------------|-----------|-------------------------------|
| Naive        | O(1)       | O(nm)     | acceptable only for tiny inputs |
| **KMP**      | O(m)       | O(n)      | single pattern, linear        |
| Z-function   | O(n+m)     | O(n+m)    | alternative to KMP            |
| Rabin-Karp   | O(m)       | O(n) avg  | multiple patterns via hashing |
| Aho-Corasick | O(sum m)   | O(n+k)    | many patterns simultaneously  |

KMP is the classic choice for a single pattern with guaranteed linear time.
