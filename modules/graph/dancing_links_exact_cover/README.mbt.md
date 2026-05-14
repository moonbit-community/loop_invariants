# Dancing Links (DLX)

## Overview

Knuth's "Dancing Links" exact-cover solver. Given a 0/1 matrix `M`,
find every subset of rows that covers each column exactly once. Many
famous puzzles reduce to exact cover:

- **Sudoku** — 729 rows (cell-value placements), 324 columns (cell, row, column, and box constraints).
- **N-queens** — n² rows, 4n - 2 columns.
- **Polyomino tilings** — one row per piece-placement, one column per board square + one per piece.
- **Pentominoes**, **Sokoban planning**, **set cover** instances of all sizes.

- **Time**: exponential worst case (exact cover is NP-hard)
- **Space**: O(non-zero entries) for the link structure
- **Signatures**:
  - `new(num_rows, num_cols, ones) -> DLX`
  - `solver.solve(limit) -> Array[Array[Int]]`

In practice, DLX (Knuth 2000) is the fastest known general exact-cover
solver thanks to two ideas: O(1) cover/uncover with doubly-linked
nodes, and the "S-heuristic" of always picking the column with the
smallest remaining count.

---

## The data structure

Every `1` in the matrix becomes a node with four neighbours
(up, down, left, right). Each column has a **header node** at the
top of its vertical list; the headers themselves form a horizontal
doubly-linked list. A single dummy `root` node at index 0 ties the
headers together.

```
        root <---+----------+----------+
        |        |          |          |
       col 0   col 1      col 2      ...      <-- header list
        |        |          |
    row 0 cell  ...        ...
        |
    row 3 cell
        |
    row 7 cell
```

Each row's nodes are stitched horizontally into their own cycle.
That's it — every relevant operation is a constant number of
pointer rewires.

---

## Cover / Uncover

**Cover(c)** removes column `c` from the matrix:

1. Unlink `c`'s header from the header list (`c.left.right = c.right` etc.).
2. For every row `r` in column `c`, unlink each of `r`'s *other* nodes
   from their columns — i.e. detach `r` from those columns.

**Uncover(c)** is the exact reverse, applied bottom-up and
right-to-left. The trick that gives the algorithm its name: detached
nodes still know where they came from (their pointers were not
overwritten, just bypassed), so re-attachment is a four-pointer
restore.

---

## The search

```
search(k):
  if header list empty:
    output current partial as a solution
    return
  c = column with smallest remaining count   -- S-heuristic
  if count[c] == 0:
    dead-end; return
  cover(c)
  for each row r in column c:
    push r onto partial
    for each x in r:
      cover(column of x)
    search(k + 1)
    pop r
    for each x in r reverse order:
      uncover(column of x)
  uncover(c)
```

The S-heuristic of always picking the most-constrained column first
is what gives DLX its remarkable practical speed: it prunes branches
that would never lead to a solution as early as possible.

---

## Reference implementation

```
pub struct DLX
pub fn new(num_rows : Int, num_cols : Int, ones : ArrayView[(Int, Int)]) -> DLX
pub fn DLX::solve(self : DLX, limit : Int) -> Array[Array[Int]]
```

Pass `limit = -1` to enumerate every exact cover, or `limit = k` to
stop after the first `k`.

---

## Tests and examples

```mbt check
///|
test "dlx 2x2 identity" {
  let solver = @dancing_links_exact_cover.new(2, 2, [(0, 0), (1, 1)][:])
  debug_inspect(solver.solve(-1).length(), content="1")
}
```

```mbt check
///|
test "dlx single row covers all" {
  let solver = @dancing_links_exact_cover.new(1, 2, [(0, 0), (0, 1)][:])
  debug_inspect(solver.solve(-1).length(), content="1")
}
```

```mbt check
///|
test "dlx no solution" {
  let solver = @dancing_links_exact_cover.new(2, 2, [(0, 0), (1, 0)][:])
  debug_inspect(solver.solve(-1).length(), content="0")
}
```

```mbt check
///|
test "dlx limit caps output" {
  let solver = @dancing_links_exact_cover.new(
    2,
    2,
    [(0, 0), (0, 1), (1, 0), (1, 1)][:],
  )
  debug_inspect(solver.solve(1).length(), content="1")
}
```

---

## Complexity

| Phase | Cost |
|------|------|
| `new(rows, cols, ones)` | `O(rows + cols + |ones|)` to build |
| `cover(c)` / `uncover(c)` | `O((|rows in c|) · (|nodes per row|))` |
| `solve(limit)` | exponential worst case; **dramatically** faster in practice via the S-heuristic |

Sudoku puzzles typically solve in microseconds. The pentomino-on-board
problem (1568 ways to tile a 6×10 board with the 12 distinct
pentominoes) enumerates in a fraction of a second.

---

## Reducing real problems

### Sudoku

For an `n × n` puzzle with the standard `√n × √n` boxes:

- **Rows**: `n³` (one per `(cell, value)` choice).
- **Columns**:
  - One per cell (so each cell gets a value): `n²`
  - One per (row, value) (so each row contains each value once): `n²`
  - One per (col, value): `n²`
  - One per (box, value): `n²`

Total `4n²` constraints. Pre-fill known cells by deleting their
"alternative-value" rows before running DLX.

### N-queens

For an `n × n` board:

- **Rows**: `n²` (one per `(row, col)` placement).
- **Columns**:
  - One per row: `n`
  - One per column: `n`
  - One per ↗ diagonal: `2n - 1` (these are *secondary* — at most one queen)
  - One per ↘ diagonal: `2n - 1` (secondary)

Strictly, exact cover requires "exactly once". Diagonals need a
"primary/secondary" distinction (Knuth's term) where secondary
columns must be covered **at most** once. The straightforward
extension is to add a slack row per secondary column; this package
treats every column as primary.

---

## Common pitfalls

- **Secondary columns**. Pure DLX requires "exactly once." If your
  problem has at-most-once constraints (like diagonals in N-queens),
  add a slack row for each secondary column or use a more advanced
  DLX variant.
- **Memory**. Each non-zero entry in `M` is one `Node` (six fields).
  For Sudoku (`729 * 4 ≈ 3000` ones) that's ~3000 nodes; trivially
  manageable. For larger problems, count carefully.
- **Search order matters**. The S-heuristic gives consistent gains
  but is not the only choice — randomised pivots can avoid worst-case
  paths in adversarial benchmarks.

---

## Related concepts

```
Dancing Links (this)        sparse exact-cover solver
Set cover                   approximation alternative for large instances
Backtracking with bitmasks  simpler but slower on sparse instances
Integer linear programming  reduces exact cover; slower but more flexible
SAT solvers                 modern exact-cover for huge structured instances
```
