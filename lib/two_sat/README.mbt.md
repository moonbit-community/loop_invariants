# 2-SAT (Beginner-Friendly Guide)

2-SAT solves boolean formulas where **each clause has exactly two literals**.
Unlike general SAT, 2-SAT can be solved in **linear time** using graphs.

This package includes an internal solver (`TwoSat`), demonstrated in tests.
All code snippets here are `mbt nocheck` because the type is private.

---

## 1) What is a 2-SAT clause?

A literal is either:

- `x` (variable is true), or
- `¬x` (variable is false).

A clause is a pair joined by OR:

```
(x ∨ y)
(¬x ∨ y)
(x ∨ ¬y)
(¬x ∨ ¬y)
```

The full formula is an AND of clauses:

```
 (x0 ∨ x1) ∧ (¬x0 ∨ x2) ∧ (¬x1 ∨ ¬x2)
```

---

## 2) Key trick: turn a clause into implications

The most important identity:

```
(a ∨ b)  is equivalent to  (¬a → b) AND (¬b → a)
```

Why?

- If `a` is false, then `b` must be true.
- If `b` is false, then `a` must be true.

This lets us build a directed graph of implications.

---

## 3) Implication graph

For each variable `x`, we create two nodes:

```
x   and   ¬x
```

Each clause adds **two directed edges**:

```
(a ∨ b) -> edges: (¬a -> b) and (¬b -> a)
```

Example: (x ∨ ¬y)

```
¬x -> ¬y
y  -> x
```

---

## 4) Step-by-step worked example

Formula: `(x0 ∨ x1) ∧ (¬x0 ∨ x1)`

### Step 1 — List the clauses

```
Clause 1:  x0 ∨  x1
Clause 2: ¬x0 ∨  x1
```

### Step 2 — Expand each clause into two implications

```
Clause 1:  x0 ∨  x1  ->  ¬x0 -> x1   and   ¬x1 -> x0
Clause 2: ¬x0 ∨  x1  ->   x0 -> x1   and   ¬x1 -> ¬x0
```

Full list of implications:

```
¬x0 -> x1
¬x1 -> x0
 x0 -> x1
¬x1 -> ¬x0
```

### Step 3 — Draw the implication graph

Nodes: `x0`, `¬x0`, `x1`, `¬x1`

```
        +---------+
        |         v
       ¬x0 -----> x1
        ^
        |
       ¬x1 -----> ¬x0
        |
        v
        x0 ------> x1
```

A cleaner ASCII layout:

```
 ¬x1 ----> x0
  |         |
  |         v
  +-------> x1
  |
  v
 ¬x0 ----> x1
```

Or, showing all four edges at once:

```
Nodes:  x0   ¬x0   x1   ¬x1

Edges:
  ¬x0  ->  x1
  ¬x1  ->  x0
   x0  ->  x1
  ¬x1  -> ¬x0
```

### Step 4 — Find strongly connected components (SCCs)

Run Kosaraju (or Tarjan) on the graph above.

```
Post-order finish (first DFS pass, one possible order):
  x1, x0, ¬x0, ¬x1

Second DFS pass on reversed graph (reverse finish order):
  Start from ¬x1: reaches ¬x1 alone  -> SCC 0 = {¬x1}
  Start from ¬x0: reaches ¬x0 alone  -> SCC 1 = {¬x0}
  Start from  x0: reaches x0 alone   -> SCC 2 = {x0}
  Start from  x1: reaches x1 alone   -> SCC 3 = {x1}
```

All four nodes are in separate SCCs (no variable shares an SCC with its
negation), so the formula is **satisfiable**.

```
SCC decomposition (higher number = later in reverse-topo order):

  SCC 0: { ¬x1 }
  SCC 1: { ¬x0 }
  SCC 2: {  x0 }
  SCC 3: {  x1 }

Condensation DAG (directed from lower to higher SCC):

  [¬x1] --> [x0] --> [x1]
    |
    +--> [¬x0] --> [x1]
```

### Step 5 — Read off the assignment

For each variable, compare the SCC index of its positive and negative literals:

```
Variable x0:  SCC(x0) = 2,  SCC(¬x0) = 1   ->  2 > 1  ->  x0 = true
Variable x1:  SCC(x1) = 3,  SCC(¬x1) = 0   ->  3 > 0  ->  x1 = true
```

**Solution: x0 = true, x1 = true.**

Verify clause 1: `true ∨ true = true`.
Verify clause 2: `false ∨ true = true`.
Both satisfied.

---

## 5) How SCC decomposition determines satisfiability

```
SATISFIABLE                      UNSATISFIABLE
-----------                      -------------

  x0 [SCC 2]                        x0
  |                                  ^
  v                                  |
 x1 [SCC 3]        vs.              v
                                    ¬x0
 ¬x0 [SCC 1]
  |                       x0 and ¬x0 both in same SCC
  v                       means x0 -> ... -> ¬x0 -> ... -> x0
 ¬x1 [SCC 0]              (cycle), which is a contradiction.

No variable shares an SCC
with its negation.
```

The rule:

```
For each variable x_i:
  if SCC(x_i) == SCC(¬x_i)  ->  UNSAT  (return None)
  if SCC(x_i)  > SCC(¬x_i)  ->  x_i = true
  if SCC(x_i)  < SCC(¬x_i)  ->  x_i = false
```

---

## 6) When is the formula impossible?

If a variable and its negation are in the **same strongly connected component**
(SCC), then:

```
x -> ... -> ¬x  and  ¬x -> ... -> x
```

So both must be true at the same time, which is impossible.

That means the formula is **unsatisfiable**.

---

## 7) How do we assign values?

If no contradictions exist, we can assign values by SCC order:

```
If SCC(x) comes AFTER SCC(¬x) in topological order,
then x = true.
Else x = false.
```

This ensures all implications are respected.

---

## 8) Visual example (unsatisfiable)

Formula:

```
(x0) ∧ (¬x0)
```

This is:

```
(x0 ∨ x0) ∧ (¬x0 ∨ ¬x0)
```

Implications:

```
¬x0 -> x0
x0  -> ¬x0
```

Implication graph:

```
 x0  <---> ¬x0
 (bidirectional cycle)
```

Both `x0` and `¬x0` are in the **same SCC** -- no solution.

```
SCC: { x0, ¬x0 }   ->  UNSAT
```

---

## 9) How to encode clauses in this implementation

Each literal is represented by:

```
(var_index, negated)
```

So:

- `x0` = `(0, false)`
- `¬x0` = `(0, true)`

Then a clause `(a ∨ b)` is:

```
add_clause(var_a, neg_a, var_b, neg_b)
```

Node encoding inside the graph:

```
positive literal x_i  ->  node  2*i
negative literal ¬x_i ->  node  2*i + 1
```

Negating a node flips its last bit: `node XOR 1`.

---

## 10) Example: basic satisfiable instance

```mbt nocheck
///|
test "two sat basic" {
  let sat = TwoSat(2)
  // (x0 ∨ x1) ∧ (¬x0 ∨ x1)
  sat.add_clause(0, false, 1, false)
  sat.add_clause(0, true, 1, false)
  match sat.solve() {
    Some(assign) => {
      // x1 must be true
      inspect(assign[1], content="true")
      inspect(sat.verify(assign), content="true")
    }
    None => fail("should be satisfiable")
  }
}
```

---

## 11) Example: unsatisfiable instance

```mbt nocheck
///|
test "two sat unsatisfiable" {
  let sat = TwoSat(1)
  // x0 and ¬x0
  sat.add_clause(0, false, 0, false) // x0
  sat.add_clause(0, true, 0, true) // ¬x0
  inspect(sat.solve() is None, content="true")
}
```

---

## 12) Example: using implications and forced values

```mbt nocheck
///|
test "two sat implication" {
  let sat = TwoSat(2)
  // x0 -> x1
  sat.add_implication(0, false, 1, false)
  // force x0 = true
  sat.set_value(0, true)
  match sat.solve() {
    Some(assign) => {
      inspect(assign[0], content="true")
      inspect(assign[1], content="true")
    }
    None => fail("should be satisfiable")
  }
}
```

---

## 13) Common modeling patterns

### A) At least one of a or b

```
a OR b
```

Add clause `(a ∨ b)`.

### B) At most one of a or b

```
¬(a AND b)  ->  (¬a ∨ ¬b)
```

Add clause `(¬a ∨ ¬b)`.

### C) Exactly one of a or b

```
(a ∨ b) AND (¬a ∨ ¬b)
```

Two clauses: one "at least one", one "at most one".

### D) Force a variable to a fixed value

```
set_value(i, true)   -- equivalent to clause (x_i ∨ x_i)
set_value(i, false)  -- equivalent to clause (¬x_i ∨ ¬x_i)
```

### E) If-then constraint (implication)

```
x0 -> x1
```

Use `add_implication(0, false, 1, false)`, which adds the clause `(¬x0 ∨ x1)`.

---

## 14) Complexity

```
Build graph: O(n + m)
SCC (Kosaraju): O(n + m)
Assignment: O(n)

Total: O(n + m)
```

`n` = number of variables, `m` = number of clauses.

---

## 15) Common pitfalls

- Forgetting that each clause adds **two** directed edges.
- Mixing up `x` and `¬x` when encoding.
- Using 2-SAT for clauses longer than 2 literals (not supported).
- Passing `neg = true` when `neg = false` was intended (off-by-one on
  negation flags is the most common source of wrong answers).
