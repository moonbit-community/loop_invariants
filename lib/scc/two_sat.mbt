// ============================================================================
// 2-SAT SOLVER USING SCC
// ============================================================================
//
// 2-SAT (2-Satisfiability) is a special case of boolean satisfiability
// where each clause has exactly 2 literals.
//
// REDUCTION TO SCC:
// ```
//   Each clause (a OR b) is equivalent to two implications:
//     (NOT a) => b
//     (NOT b) => a
//
//   Build an "implication graph" with 2n vertices:
//     - Vertices 0..n-1 represent x0..x(n-1)
//     - Vertices n..2n-1 represent NOT x0..NOT x(n-1)
//
//   Add edges for each implication.
// ```
//
// SATISFIABILITY CHECK:
// ```
//   The formula is satisfiable iff for all i:
//     xi and NOT xi are in different SCCs
//
//   Why? If xi and NOT xi are in the same SCC, then:
//     xi => ... => NOT xi => ... => xi
//   This creates a contradiction.
// ```
//
// FINDING ASSIGNMENT:
// ```
//   Use the SCC numbering (topological order):
//     - If SCC(xi) > SCC(NOT xi): set xi = true
//     - If SCC(xi) < SCC(NOT xi): set xi = false
//
//   Why this works:
//     If xi = true leads to contradiction, then there's a path
//     xi => ... => NOT xi, meaning SCC(xi) <= SCC(NOT xi).
//     By choosing the one with higher SCC number, we avoid the
//     implication chain leading to contradiction.
// ```
//
// EXAMPLE:
// ```
//   Formula: (x0 OR x1) AND (NOT x0 OR x1) AND (x0 OR NOT x1)
//
//   Implications:
//     NOT x0 => x1, NOT x1 => x0
//     x0 => x1, NOT x1 => NOT x0
//     NOT x0 => NOT x1, x1 => x0
//
//   Implication graph has paths:
//     NOT x0 => x1 => x0 (so NOT x0 => x0, meaning x0 must be true)
//     NOT x1 => NOT x0 => NOT x1 (cycle, same SCC)
//     x1 => x0 => ... (eventually x1)
//
//   Result: x0 = true, x1 = true (or both false depending on SCC order)
// ```

///|
/// A 2-SAT problem instance backed by an implication graph.
///
/// Variables are indexed `0` to `n - 1`. Each variable `xᵢ` is represented
/// by two vertices in the implication graph:
///
/// ```
///   vertex i       = positive literal  xᵢ
///   vertex i + n   = negative literal  NOT xᵢ
/// ```
///
/// Clauses are added via `add_clause`, which records the two corresponding
/// implication edges. Call `solve` to obtain a satisfying assignment, or
/// `None` if the formula is unsatisfiable.
///
/// Fields:
/// - `n`   : number of boolean variables.
/// - `adj` : implication graph adjacency list (length `2 * n`).
pub(all) struct TwoSAT {
  n : Int
  adj : Array[Array[Int]]
}

///|
/// Create a new 2-SAT instance with `n` boolean variables.
///
/// Allocates an implication graph with `2 * n` vertices: vertices `0..n-1`
/// represent the positive literals and vertices `n..2n-1` represent the
/// negated literals.  No clauses are added yet.
///
/// Parameter:
/// - `n` : number of boolean variables (must be >= 0).
pub fn TwoSAT::TwoSAT(n : Int) -> TwoSAT {
  // Use makei to create 2n adjacency lists (n vars + n negated vars)
  let adj : Array[Array[Int]] = [ for _ in 0..<(2 * n) => [] ]
  { n, adj }
}

///|
/// Map a (variable, sign) pair to its vertex index in the implication graph.
///
/// Positive literals occupy vertices `0` to `n - 1`; negated literals occupy
/// vertices `n` to `2n - 1`.
///
/// Parameters:
/// - `n`   : total number of variables (used as offset for negated literals).
/// - `x`   : variable index (`0` to `n - 1`).
/// - `neg` : `true` if this is the negated literal (`NOT xₓ`).
///
/// Returns the vertex index for use in the implication graph.
fn var_to_vertex(n : Int, x : Int, neg : Bool) -> Int {
  if neg {
    x + n // Negated variables are in second half
  } else {
    x // Positive variables in first half
  }
}

///|
/// Add the clause `(literal_a OR literal_b)` to the 2-SAT formula.
///
/// The clause is encoded as two implication edges in the internal graph:
///
/// ```
///   (NOT a) => b      if a is false, b must be true
///   (NOT b) => a      if b is false, a must be true
/// ```
///
/// A literal is specified by its variable index and a boolean sign:
/// - `neg = false` means the positive literal `xᵢ`
/// - `neg = true`  means the negated literal `NOT xᵢ`
///
/// Parameters:
/// - `self`  : the 2-SAT instance to modify.
/// - `a`     : index of the first variable (`0` to `n - 1`).
/// - `neg_a` : `true` if the first literal is negated.
/// - `b`     : index of the second variable (`0` to `n - 1`).
/// - `neg_b` : `true` if the second literal is negated.
///
/// Example — add the clause `(x0 OR NOT x1)`:
/// ```
/// ts.add_clause(0, false, 1, true)
/// ```
pub fn TwoSAT::add_clause(
  self : TwoSAT,
  a : Int,
  neg_a : Bool,
  b : Int,
  neg_b : Bool,
) -> Unit {
  // Implication 1: (NOT a) => b
  let from_a = var_to_vertex(self.n, a, !neg_a)
  let to_b = var_to_vertex(self.n, b, neg_b)
  self.adj[from_a].push(to_b)

  // Implication 2: (NOT b) => a
  let from_b = var_to_vertex(self.n, b, !neg_b)
  let to_a = var_to_vertex(self.n, a, neg_a)
  self.adj[from_b].push(to_a)
}

///|
/// Solve the 2-SAT formula and return a satisfying assignment, if one exists.
///
/// The algorithm:
/// 1. Run Tarjan's SCC algorithm on the implication graph.
/// 2. For each variable `xᵢ`, check that `xᵢ` and `NOT xᵢ` are in
///    **different** SCCs. If they share an SCC the formula is unsatisfiable
///    (they mutually imply each other, creating a contradiction).
/// 3. Assign `xᵢ = true` if `SCC(xᵢ) > SCC(NOT xᵢ)` in Tarjan's numbering
///    (higher index = earlier in topological order = the literal that is
///    "forced" to be true by the implication structure).
///
/// Returns:
/// - `Some(assignment)` where `assignment[i]` is the value of variable `i`,
///   if the formula is satisfiable.
/// - `None` if the formula is unsatisfiable (some variable and its negation
///   are in the same SCC).
///
/// Example:
/// ```
/// let ts = TwoSAT(2)
/// ts.add_clause(0, false, 1, false)  // x0 OR x1
/// match ts.solve() {
///   Some(vals) => println(vals[0])   // true or false
///   None => println("unsat")
/// }
/// ```
pub fn TwoSAT::solve(self : TwoSAT) -> Array[Bool]? {
  let result = find_sccs(2 * self.n, self.adj)

  // Check satisfiability
  for x in 0..<self.n {
    if result.component[x] == result.component[x + self.n] {
      return None // x and NOT x in same SCC -> contradiction
    }
  }

  // Assign values based on SCC ordering
  // Tarjan numbers SCCs in reverse topological order
  // Higher SCC number = earlier in topological order = "stronger"
  let assignment = Array::make(self.n, false)
  for x in 0..<self.n {
    // If SCC(x) > SCC(NOT x), then x implies NOT x would be
    // going against topological order, so x = true is safe
    assignment[x] = result.component[x] > result.component[x + self.n]
  }
  Some(assignment)
}
