# Aho–Corasick (Multi‑Pattern Search)

## What It Is

**Aho–Corasick** is a string‑matching algorithm that finds **all occurrences of many patterns** in a single pass through the text. It combines a **trie** (prefix tree) with **failure links** (like KMP) to avoid backtracking.

## The Problem

You have a set of patterns and one long text. You want all matches.

Example:

- Patterns: `he`, `she`, `his`, `hers`
- Text: `ushers`
- Matches: `she`, `he`, `hers`

Running KMP once per pattern is too slow. Aho–Corasick builds one automaton and scans the text once.

## Core Idea (In Plain Words)

1. **Build a trie** of all patterns.
2. Add **failure links** so that when a character doesn’t match, we jump to the longest suffix that could still match.
3. **Scan the text once** using the trie + failure links.
4. Every time we land on a state, output all patterns that end there.

This turns many pattern searches into a **single automaton walk**.

## Example 1: Basic Walkthrough

Patterns: `he`, `she`, `his`, `hers`
Text: `ushers`

Step by step:

- `u`: no edge → stay at root
- `s`: go to state `s`
- `h`: go to state `sh`
- `e`: go to state `she`
  - output `she`
  - failure link also outputs `he`
- `r`: follow failure links as needed
- `s`: match `hers`

Matches found: `she`, `he`, `hers`.

## Example 2: Overlapping Matches

Patterns: `aba`
Text: `ababa`

Matches:

- `aba` at index 0
- `aba` at index 2 (overlapping)

Aho–Corasick handles overlaps naturally because it never skips characters.

## Example 3: Prefix Patterns

Patterns: `a`, `ab`, `abc`
Text: `abc`

All three match at position 0. The output list at that state includes every prefix pattern.

## Failure Links (Why They Matter)

Suppose we matched `she` and the next character is `x`:

```
current state: "she"
no edge for x → follow failure to "he"
still no x → follow failure to "e" or root
```

This is exactly like KMP, but for the whole trie.

## Step‑By‑Step Algorithm

### 1. Build the trie
Each node is a prefix of some pattern.

### 2. Build failure links (BFS)
We process nodes level by level so every failure target is already built.

### 3. Scan the text
For each character:

- Follow edges if possible
- Otherwise follow failure links until an edge exists
- Output all patterns ending at this state

## Complexity

Let:

- `m` = total length of patterns
- `n` = text length
- `z` = number of matches
- `σ` = alphabet size (256 bytes here)

Then:

- Build: **O(m × σ)**
- Search: **O(n + z)**
- Space: **O(m × σ)**

## Example Usage (from this package)

```mbt check
///|
test "aho corasick example" {
  let patterns : Array[String] = ["he", "she", "his", "hers"]
  let matches = @aho_corasick.find_all_matches(patterns[:], "ushers")
  inspect(matches.length(), content="3")
  let found_she = matches.filter(m => m.2 == "she").length() > 0
  let found_he = matches.filter(m => m.2 == "he").length() > 0
  let found_hers = matches.filter(m => m.2 == "hers").length() > 0
  inspect(found_she && found_he && found_hers, content="true")
  inspect(@aho_corasick.count_all_matches(patterns[:], "ushers"), content="3")
}
```

```mbt check
///|
test "aho corasick overlapping" {
  let patterns : Array[String] = ["aba"]
  let matches = @aho_corasick.find_all_matches(patterns[:], "ababa")
  inspect(matches.length(), content="2")
}
```

```mbt check
///|
test "aho corasick prefix patterns" {
  let patterns : Array[String] = ["a", "ab", "abc"]
  let matches = @aho_corasick.find_all_matches(patterns[:], "abc")
  inspect(matches.length(), content="3")
}
```

## Common Applications

- **Keyword filtering** (e.g., spam or profanity detection)
- **DNA motif search** (many patterns in a long genome)
- **Log scanning** (many error signatures)
- **Search engines** (dictionary words over large texts)

## Pitfalls

- If you use Unicode strings, be aware this implementation uses **byte values** (0–255). It works for ASCII and raw bytes. For full Unicode, you would need a different alphabet strategy.
- Output lists may contain **multiple patterns** at one position.
- Overlapping matches are expected and correct.

## When to Use It

Use Aho–Corasick when:

- You have many patterns
- You need all matches
- You want one pass over the text

If you only have one pattern, KMP is simpler and usually faster to set up.
