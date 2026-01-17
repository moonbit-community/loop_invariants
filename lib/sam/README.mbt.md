# Suffix Automaton (SAM)

This package provides a **suffix automaton**, a compact DFA that recognizes
**all substrings** of a string. It is one of the most powerful linear‑time
string structures.

---

## 1. What problem does SAM solve?

Given a text `S`, we often need to answer:

- Is `P` a substring of `S`?
- How many distinct substrings does `S` have?
- What is the longest common substring between two strings?

SAM answers these in **O(n)** build time and **O(m)** query time.

---

## 2. Intuition: states = groups of substrings

SAM groups substrings that have the **same set of ending positions** (endpos).

Example with `"abab"`:

```
Substring "ab" appears ending at positions {1, 3}
Substring "b"  appears ending at positions {1, 3}

These share the same endpos set => same SAM state.
```

This is why SAM can represent all substrings in only **O(n)** states.

---

## 3. Structure of a SAM state

Each state stores:

```
len    = length of the longest string in the state
link   = suffix link (largest proper suffix class)
next   = transitions by character
```

Key rule:

```
Strings in state q have lengths in:
(len[link[q]] + 1) .. len[q]
```

---

## 4. Visual overview (small automaton)

For S = "abab":

```
init --a--> [a] --b--> [ab] --a--> [aba] --b--> [abab]
  \                         ^
   \--b--> [b] --a----------|

Suffix links (dotted):
[abab] ..> [bab] ..> [ab] ..> [b] ..> init
[a] ..> init
```

The automaton recognizes **every substring** of "abab".

---

## 5. Building SAM (high level)

Process the string one character at a time:

1. Create a new state for the extended prefix.
2. Add transitions from the last state.
3. Follow suffix links and add missing transitions.
4. If a transition would break the "len" rule, **clone** a state.

The cloning step is the only tricky part, but it preserves minimality.

---

## 6. Why cloning is needed (tiny example)

When adding a new character, sometimes a state would need **two different**
length ranges. This violates the rule above, so we split it:

```
Original state Q
  len = 5, link = ...

We need:
  one state with max len = 3
  one state with max len = 5

We "clone" Q into Q', redirect some links, and keep both valid.
```

This ensures SAM stays minimal.

---

## 7. Example usage (public API)

```mbt check
///|
test "sam example" {
  inspect(@sam.contains_substring("abab", "aba"), content="true")
  inspect(@sam.contains_substring("abab", "ac"), content="false")
  inspect(@sam.distinct_substrings_count("abab"), content="7")
}
```

---

## 8. Distinct substring count

For each state q:

```
new_substrings = len[q] - len[link[q]]
```

Sum this over all states (except init) to get the number of **distinct
substrings**.

Example `"abab"`:

```
Distinct substrings:
  a, b, ab, ba, aba, bab, abab  -> 7
```

---

## 9. Substring check (how it works)

To check if pattern P is a substring:

```
start at init
for each char c in P:
  if no transition on c -> false
  else follow transition
if all chars consumed -> true
```

This is O(|P|).

---

## 10. Example: longest common substring (idea)

Build SAM for S, then walk T:

```
current state = init
current length = 0

for each char c in T:
  while no transition and state != init:
    state = link[state]
    current length = len[state]
  if transition exists:
    state = next[state][c]
    current length++
  else:
    current length = 0
  update best answer
```

Total time O(|S| + |T|).

---

## 11. Complexity

```
Build: O(n)
Substring check: O(m)
Distinct substrings: O(n)
```

States are at most `2n - 1`.

---

## 12. Beginner checklist

1. SAM works for **substrings**, not only suffixes.
2. It uses **suffix links** similar to suffix trees.
3. Cloning is required to keep the automaton minimal.
4. Total states ≤ 2n - 1, so memory is linear.

---

## 13. Summary

Suffix automaton is a compact representation of all substrings:

- build in linear time,
- query substrings in linear time,
- count distinct substrings easily,
- highly practical for string algorithms.
