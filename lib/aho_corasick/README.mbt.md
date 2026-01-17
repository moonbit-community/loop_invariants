# Aho-Corasick (Multi-Pattern Search)

## Problem

You have **many patterns** and one long text. You want *all* matches in one pass.

Example:

- Patterns: `he`, `she`, `his`, `hers`
- Text: `ushers`
- Matches: `she`, `he`, `hers`

Naively running KMP for each pattern is slow. We want **one scan** of the text.

## Easy Idea

1. Put all patterns into a **trie**.
2. Add **failure links** so we can fall back on mismatches.
3. Scan the text once, following trie edges or failure links.
4. Every time we land on a state, we output the patterns ending there.

This turns "many searches" into **one automaton walk**.

## Step-by-Step Solution

### 1. Build the trie
Each node is a prefix of some pattern.

### 2. Build failure links (BFS)
Failure link = "longest proper suffix that is also a trie prefix".

**Why BFS?**
If a node is deeper, its failure link points to a shallower node. BFS guarantees that target is already built.

### 3. Search the text
For each character:

- If there is an edge, take it.
- Otherwise, follow failure links until an edge exists (or reach root).
- Output all patterns that end at this state.

## A Tiny Walkthrough

Text: `ushers`

- `u`: no edge → stay at root
- `s`: go to `s`
- `h`: go to `sh`
- `e`: go to `she` → match `she`, also match `he` (via failure)
- `r`: follow failure links as needed
- `s`: match `hers`

## Complexity

- Build: O(total pattern length × alphabet)
- Search: O(text length + matches)
- Space: O(total pattern length × alphabet)

## Example

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

## When to Use It

Use Aho-Corasick when:

- You have **multiple patterns**
- You need **all** matches
- You want **one pass** over the text

If you only have one pattern, KMP is simpler.
