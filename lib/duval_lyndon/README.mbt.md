# Duval's Lyndon Factorization

## Overview

**Duval's algorithm** decomposes any string into a unique sequence of **Lyndon words**
in non-increasing lexicographic order. A Lyndon word is a string that is strictly
smaller than all of its non-trivial rotations.

- **Time**: O(n)
- **Space**: O(n)
- **Output**: Unique factorization into Lyndon words

## The Key Insight

```
Problem: Decompose a string into "primitive" building blocks

What makes Lyndon words special?
  - "a" is Lyndon: smallest rotation of itself
  - "ab" is Lyndon: "ab" < "ba"
  - "abc" is Lyndon: "abc" < "bca" < "cab"
  - "ba" is NOT Lyndon: "ab" < "ba"
  - "aa" is NOT Lyndon: "aa" = "aa" (not strictly smaller)

Theorem (Chen-Fox-Lyndon):
  Every string has a UNIQUE factorization into Lyndon words
  in non-increasing lexicographic order.
```

## Understanding Lyndon Words

```
Lyndon word: Strictly smallest among all its rotations

Examples:
  "a"     → rotations: "a"           → Lyndon ✓
  "ab"    → rotations: "ab", "ba"    → "ab" < "ba" ✓
  "abc"   → rotations: "abc","bca","cab" → "abc" smallest ✓
  "aab"   → rotations: "aab","aba","baa" → "aab" smallest ✓

Non-examples:
  "ba"    → rotations: "ba", "ab"    → "ab" < "ba" ✗
  "cba"   → rotations: "cba","bac","acb" → "acb" smallest ✗
  "aa"    → rotations: "aa", "aa"    → equal, not strictly smaller ✗

Key property: Lyndon words are primitive (not a repetition of a shorter string)
```

## The Unique Factorization

```
Every string can be written as w = L1 · L2 · ... · Lk where:
  - Each Li is a Lyndon word
  - L1 ≥ L2 ≥ ... ≥ Lk (lexicographically non-increasing)

Examples:
  "banana" = "b" · "an" · "an" · "a"
             (b ≥ an ≥ an ≥ a ✓)

  "ababab" = "ab" · "ab" · "ab"
             (ab = ab = ab ✓)

  "abracadabra" = "abracadabr" · "a"
             (Check: is "abracadabr" Lyndon? Yes!)
```

## Algorithm Walkthrough

```
Duval's algorithm uses three pointers: i, j, k

i = start of current potential Lyndon factor
j = scanning position
k = comparison position within the repeating pattern

Process "banana":

Initial: i=0, j=1, k=0
         b a n a n a
         i j
         k

Step 1: Compare s[j]=a vs s[k]=b
        'a' < 'b' → current block breaks
        Output: "b" (length j-k = 1)
        i = j = 1, k = 1

Step 2: i=1, j=2, k=1
        Compare s[2]='n' vs s[1]='a'
        'n' > 'a' → extend pattern
        j = 3, k = 1

Step 3: i=1, j=3, k=2
        Compare s[3]='a' vs s[2]='n'
        'a' < 'n' → break
        Output: "an" (from i=1, length 2)
        i = j = 3, k = 3

Step 4: Similar process...
        Output: "an"

Step 5: Output: "a"

Result: ["b", "an", "an", "a"]
```

## Visual: Pattern Detection

```
Processing "ababab":

i=0, j=1: s[1]='b' > s[0]='a' → extend
i=0, j=2: s[2]='a' = s[0]='a' → continue matching
i=0, j=3: s[3]='b' = s[1]='b' → continue matching
i=0, j=4: s[4]='a' = s[0]='a' → continue matching
i=0, j=5: s[5]='b' = s[1]='b' → continue matching
End of string

We found "ab" repeated 3 times!
Output: ["ab", "ab", "ab"]

Key insight: When s[j] = s[k], we're detecting repetition.
The Lyndon word is s[i..i+period], repeated as many times as it fits.
```

## API

- `duval_factorization(s)` returns an array of factors (strings)

## Example Usage

```mbt check
///|
test "duval banana" {
  let factors = @duval_lyndon.duval_factorization("banana")
  inspect(factors, content="[\"b\", \"an\", \"an\", \"a\"]")
}
```

```mbt check
///|
test "duval ababab" {
  let factors = @duval_lyndon.duval_factorization("ababab")
  inspect(factors, content="[\"ab\", \"ab\", \"ab\"]")
}
```

## More Examples

```mbt check
///|
test "duval single char" {
  let factors = @duval_lyndon.duval_factorization("aaaa")
  inspect(factors, content="[\"a\", \"a\", \"a\", \"a\"]")
}
```

```mbt check
///|
test "duval already lyndon" {
  let factors = @duval_lyndon.duval_factorization("abcd")
  inspect(factors, content="[\"abcd\"]")
}
```

## Common Applications

### 1. Minimum Rotation
```
The minimum rotation of a string starts at the first character
of the last Lyndon factor.

For "baca": factors = ["b", "ac", "a"]
Last factor "a" starts at position 3
Minimum rotation: "abac"
```

### 2. Lexicographically Smallest Suffix
```
Related to Lyndon factorization through the "standard decomposition"
Used in suffix array construction.
```

### 3. String Periodicity
```
If the factorization is L repeated k times,
the string has period |L|.
```

### 4. Combinatorics on Words
```
Lyndon words are the "prime" building blocks of strings.
Used in bijective BWT, necklace enumeration, etc.
```

## Properties of Lyndon Factorization

```
1. Uniqueness: Every string has exactly one Lyndon factorization
   with non-increasing factors.

2. Concatenation: If u < v are Lyndon words, then uv is Lyndon.

3. Counting: There are (1/n) Σ μ(d) * k^(n/d) Lyndon words
   of length n over alphabet of size k.

4. Relation to suffix array: The Lyndon factorization can be
   computed from the suffix array, and vice versa.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Factorization | O(n) |
| Space | O(n) for output |

## Duval's Algorithm vs Other Approaches

| Method | Time | Use Case |
|--------|------|----------|
| **Duval** | O(n) | Lyndon factorization |
| Booth | O(n) | Minimum rotation only |
| Suffix Array | O(n log n) | More general queries |

**Choose Duval when**: You need the full Lyndon factorization or related string properties.

## Implementation Notes

- The algorithm is online: processes characters left to right
- Three-pointer technique: i (block start), j (scan), k (compare)
- When s[j] > s[k]: extend the current run
- When s[j] = s[k]: continue comparing within the period
- When s[j] < s[k]: output complete Lyndon words, restart
- Handle empty string and single characters as edge cases

