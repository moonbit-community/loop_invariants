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

## 4) When is the formula impossible?

If a variable and its negation are in the **same strongly connected component**
(SCC), then:

```
x -> ... -> ¬x  and  ¬x -> ... -> x
```

So both must be true at the same time, which is impossible.

That means the formula is **unsatisfiable**.

---

## 5) How do we assign values?

If no contradictions exist, we can assign values by SCC order:

```
If SCC(x) comes AFTER SCC(¬x) in topological order,
then x = true.
Else x = false.
```

This ensures all implications are respected.

---

## 6) Visual example (satisfiable)

Formula:

```
(x0 ∨ x1) ∧ (¬x0 ∨ x1)
```

Implications:

```
¬x0 -> x1
¬x1 -> x0
x0  -> x1
¬x1 -> ¬x0
```

A valid assignment:

```
x1 = true
x0 = either true or false
```

---

## 7) Visual example (unsatisfiable)

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

So `x0` and `¬x0` are in the same SCC → no solution.

---

## 8) How to encode clauses in this implementation

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

---

## 9) Example: basic satisfiable instance

```mbt nocheck
///|
test "two sat basic" {
  let sat = TwoSat::new(2)
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

## 10) Example: unsatisfiable instance

```mbt nocheck
///|
test "two sat unsatisfiable" {
  let sat = TwoSat::new(1)
  // x0 and ¬x0
  sat.add_clause(0, false, 0, false) // x0
  sat.add_clause(0, true, 0, true) // ¬x0
  inspect(sat.solve() is None, content="true")
}
```

---

## 11) Example: using implications and forced values

```mbt nocheck
///|
test "two sat implication" {
  let sat = TwoSat::new(2)
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

## 12) Common modeling patterns

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

---

## 13) Complexity

```
Build graph: O(n + m)
SCC (Kosaraju): O(n + m)
Assignment: O(n)

Total: O(n + m)
```

`n` = number of variables, `m` = number of clauses.

---

## 14) Common pitfalls

- Forgetting that each clause adds **two** directed edges.
- Mixing up `x` and `¬x` when encoding.
- Using 2-SAT for clauses longer than 2 literals (not supported).
