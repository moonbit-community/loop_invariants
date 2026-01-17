# Wildcard Matching (Beginner-Friendly Guide)

Match a text string against a pattern with:

- `?` = any single character
- `*` = any sequence (including empty)

This package provides:

```
@wildcard_matching.wildcard_match(text, pattern) -> Bool
```

The algorithm uses dynamic programming with **O(n × m)** time and **O(m)** space.

---

## 1) What does matching mean?

```
pattern:  a*b?c
text:     aXXbYc
```

Explanation:

- `a` matches `a`
- `*` matches `XX`
- `b` matches `b`
- `?` matches `Y`
- `c` matches `c`

So the match is **true**.

---

## 2) DP definition (the core idea)

Let:

```
dp[i][j] = does text[0..i) match pattern[0..j) ?
```

Transitions:

1) If pattern[j-1] is a normal char or `?`:

```
dp[i][j] = dp[i-1][j-1]  if chars match
```

2) If pattern[j-1] == `*`:

```
dp[i][j] = dp[i][j-1]    // '*' matches empty
        OR dp[i-1][j]    // '*' matches one more char
```

We keep only the previous row → O(m) space.

---

## 3) Visual DP table

Pattern = `"a*c"`, Text = `"abc"`

```
dp[i][j] (T = true, F = false)

        ""   "a"  "a*"  "a*c"
""      T     F     F     F
"a"     F     T     T     F
"ab"    F     F     T     F
"abc"   F     F     T     T

Answer = dp[3][3] = true
```

---

## 4) Correct DP walkthrough (example)

Pattern = `"a*b?c"`  
Text    = `"aXXbYc"`

Key moments:

```
dp after reading "a":
  "a" matches "a"
  "a*" also matches (star is empty)

dp after reading "aXX":
  "a*" keeps matching because * can stretch

dp after reading "aXXb":
  "a*b" now matches

dp after reading "aXXbY":
  "a*b?" matches

dp after reading "aXXbYc":
  "a*b?c" matches
```

---

## 5) Example usage

```mbt check
///|
test "wildcard basics" {
  inspect(@wildcard_matching.wildcard_match("aaabxc", "a*b?c"), content="true")
  inspect(@wildcard_matching.wildcard_match("abc", "a?c"), content="true")
}
```

```mbt check
///|
test "wildcard star and empty" {
  inspect(@wildcard_matching.wildcard_match("", "*"), content="true")
  inspect(@wildcard_matching.wildcard_match("hello", "h*o"), content="true")
}
```

```mbt check
///|
test "wildcard edge cases" {
  inspect(@wildcard_matching.wildcard_match("", ""), content="true")
  inspect(@wildcard_matching.wildcard_match("a", ""), content="false")
  inspect(@wildcard_matching.wildcard_match("abcde", "a*c*e"), content="true")
  inspect(@wildcard_matching.wildcard_match("abcde", "*****"), content="true")
  inspect(@wildcard_matching.wildcard_match("abc", "???"), content="true")
  inspect(@wildcard_matching.wildcard_match("ab", "???"), content="false")
}
```

---

## 6) Why `*` is tricky

`*` can match **zero** characters or **many** characters.
That is why its transition has two cases:

```
dp[i][j] = dp[i][j-1]   // ignore star
        OR dp[i-1][j]   // use star to consume one more char
```

This is the heart of wildcard matching.

---

## 7) Complexity

```
Time:  O(n × m)
Space: O(m)
```

`n` = text length, `m` = pattern length.

---

## 8) Common applications

```
File globbing: "*.txt", "test?.py"
Database LIKE patterns (SQL % and _)
Filtering logs with simple patterns
Input validation formats
```

---

## 9) Common pitfalls

- Forgetting that `*` can match empty.
- Mixing up [l, r) slicing vs inclusive indices.
- Pattern longer than text still matches if extra chars are all `*`.
- Multiple consecutive `*` are equivalent to a single `*`.
