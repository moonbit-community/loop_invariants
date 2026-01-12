# Trie (Prefix Tree)

## Overview

A **Trie** (pronounced "try") is a tree for storing strings where each node
represents a character. Paths from root to nodes represent prefixes.

- **Insert/Search/Delete**: O(m) where m = word length
- **Prefix queries**: O(p) where p = prefix length
- **Space**: O(ALPHABET * total characters)

## Structure Visualization

For words: "cat", "car", "card", "care":

```
           (root)
              |
             'c'
              |
             'a'
            /   \
          't'   'r' [car]
         [cat]  /|\
               'd' 'e'
            [card] [care]

[] = word end marker
```

## How It Works

### Insert "cat"

```
Step 1: Start at root
        root
         |
        'c' <- create

Step 2: Continue from 'c'
        root
         |
        'c'
         |
        'a' <- create

Step 3: Continue from 'a'
        root
         |
        'c'
         |
        'a'
         |
        't' <- create, mark as word end
```

### Search "car"

```
        root
         |
        'c' <- found
         |
        'a' <- found
         |
        'r' <- found, check is_end = true? YES!

Result: "car" exists
```

### Prefix Query "ca"

```
        root
         |
        'c' <- found
         |
        'a' <- found, this node exists!

Result: Prefix "ca" exists
All words: cat, car, card, care
```

## Common Use Cases

1. **Autocomplete**
   ```
   User types: "pro"
   Suggestions: program, project, promise, protect...
   ```

2. **Spell Checker**
   ```
   Is "teh" a word? -> No
   Did you mean: "the", "ten", "tea"?
   ```

3. **IP Routing** (Longest prefix match)
   ```
   Route 192.168.1.* -> Gateway A
   Route 192.168.* -> Gateway B
   ```

4. **Word Games**
   ```
   Scrabble: Is "QI" a valid word?
   Boggle: Find all words in grid
   ```

## Complexity Analysis

| Operation        | Time  | Space |
|------------------|-------|-------|
| Insert           | O(m)  | O(m)  |
| Search           | O(m)  | O(1)  |
| Delete           | O(m)  | O(1)  |
| Prefix exists    | O(p)  | O(1)  |
| Count with prefix| O(p)  | O(1)  |

Where m = word length, p = prefix length

## Trie vs Other Structures

| Structure   | Search    | Prefix Query | Space    |
|-------------|-----------|--------------|----------|
| **Trie**    | O(m)      | O(p)         | O(Σ*N*M) |
| Hash Set    | O(m) avg  | O(N*M)       | O(N*M)   |
| Sorted Array| O(m log N)| O(m log N)   | O(N*M)   |
| BST         | O(m log N)| O(m log N)   | O(N*M)   |

Σ = alphabet size, N = words, M = avg length

**Choose Trie when**: You need prefix operations or autocomplete.

## Variations

### Compressed Trie (Radix Tree)
Merge chains of single-child nodes:

```
Standard:          Compressed:
   c                  car
   |                 / | \
   a               d   e   t
   |
   r
  /|\
 d e t
```

### Ternary Search Trie
Each node has 3 children: less, equal, greater.
More space-efficient for sparse alphabets.

## Implementation Notes

- Children array indexed by character (a=0, b=1, ...)
- `is_end` marks complete words
- `prefix_count` tracks words sharing this prefix
- For Unicode: use hash map instead of array for children
