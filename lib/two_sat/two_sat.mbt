// ============================================================================
// 2-SAT - Boolean Satisfiability with 2 Literals per Clause
// ============================================================================
//
// 2-SAT solves boolean satisfiability where each clause has exactly 2 literals.
// Unlike general SAT (NP-complete), 2-SAT is solvable in linear time O(n + m).
//
// KEY INSIGHT: Each clause (a ∨ b) is equivalent to two implications:
// (¬a → b) and (¬b → a)
//
// IMPLICATION GRAPH:
// - 2n nodes: for each variable x, we have nodes x and ¬x
// - For clause (a ∨ b), add edges (¬a → b) and (¬b → a)
//
// ALGORITHM:
// 1. Build implication graph from clauses
// 2. Find strongly connected components (SCCs) using Kosaraju or Tarjan
// 3. If any variable x and ¬x are in the same SCC, unsatisfiable
// 4. Otherwise, assign values based on topological order of SCCs:
//    - Process SCCs in reverse topological order
//    - For each unassigned variable, assign true if x's SCC comes after ¬x's SCC
//
// WHY IT WORKS:
// - If x and ¬x are in same SCC: x → ... → ¬x → ... → x, contradiction
// - Topological assignment: if (a → b) and a is true, then b must be true
//   Since we process in reverse topo order, we assign b before a, ensuring consistency
//
// EXAMPLE: (x₁ ∨ x₂) ∧ (¬x₁ ∨ x₃) ∧ (¬x₂ ∨ ¬x₃)
// Implications:
// ¬x₁ → x₂, ¬x₂ → x₁
// x₁ → x₃, ¬x₃ → ¬x₁
// x₂ → ¬x₃, x₃ → ¬x₂
//
// INVARIANTS:
// 1. Implication graph encodes all logical constraints
// 2. Variables in same SCC must have same truth value
// 3. If SCC(x) comes before SCC(¬x) in topo order, x should be false
//
// TIME COMPLEXITY: O(n + m) where n = variables, m = clauses
// SPACE COMPLEXITY: O(n + m)

///|
/// A 2-SAT problem instance.
///
/// Internally stores the implication graph and its reverse (for Kosaraju's
/// algorithm). Each boolean variable `x_i` is encoded as two nodes in the
/// graph: node `2*i` represents `x_i` (positive literal) and node `2*i+1`
/// represents `¬x_i` (negative literal).
///
/// Use `TwoSat::new` to construct, `add_clause` / `add_implication` /
/// `set_value` to add constraints, and `solve` to find a satisfying
/// assignment.
priv struct TwoSat {
  n : Int // Number of variables (0 to n-1)
  adj : Array[Array[Int]] // Implication graph: adj[node] = list of implied nodes
  radj : Array[Array[Int]] // Reverse graph for Kosaraju
}

///|
/// Create a new 2-SAT instance with `n` boolean variables.
///
/// Variables are indexed from `0` to `n-1`. Each variable `x_i` is
/// represented by two nodes in the implication graph: the positive literal
/// `x_i` (node `2*i`) and the negative literal `¬x_i` (node `2*i+1`).
///
/// After construction, use `add_clause`, `add_implication`, or `set_value`
/// to add constraints, then call `solve` to obtain an assignment.
fn TwoSat::TwoSat(n : Int) -> TwoSat {
  let adj : Array[Array[Int]] = [ for _ in 0..<(2 * n) => [] ]
  let radj : Array[Array[Int]] = [ for _ in 0..<(2 * n) => [] ]
  { n, adj, radj }
}

///|
/// Convert a literal `(variable, negated)` to its node index in the
/// implication graph.
///
/// The encoding is:
/// - positive literal `x_v`  ->  node `2*v`
/// - negative literal `¬x_v` ->  node `2*v + 1`
///
/// The last bit therefore acts as the negation flag, which allows `negate_node`
/// to flip it with a single XOR.
fn literal_to_node(v : Int, negated : Bool) -> Int {
  2 * v + (if negated { 1 } else { 0 })
}

///|
/// Return the node index for the logical negation of `node`.
///
/// Because positive and negative literals share a consecutive pair of indices
/// (`2*v` and `2*v+1`), flipping the last bit with XOR produces the
/// complement in O(1).
fn negate_node(node : Int) -> Int {
  node ^ 1 // Flip last bit: 2k <-> 2k+1
}

///|
/// Add the clause `(a ∨ b)` to the 2-SAT instance.
///
/// A clause `(a ∨ b)` is logically equivalent to the pair of implications
/// `(¬a → b)` and `(¬b → a)`. Both directed edges (and their reverses, for
/// Kosaraju) are inserted into the implication graph.
///
/// Parameters:
/// - `var_a` / `neg_a`: index and negation flag of the first literal.
/// - `var_b` / `neg_b`: index and negation flag of the second literal.
///
/// To express a unit clause `(a)`, pass the same literal for both arguments:
/// `add_clause(i, neg, i, neg)`. This is also what `set_value` does
/// internally.
fn TwoSat::add_clause(
  self : TwoSat,
  var_a : Int,
  neg_a : Bool,
  var_b : Int,
  neg_b : Bool,
) -> Unit {
  // (a ∨ b) ≡ (¬a → b) ∧ (¬b → a)
  let node_a = literal_to_node(var_a, neg_a)
  let node_b = literal_to_node(var_b, neg_b)
  let not_a = negate_node(node_a)
  let not_b = negate_node(node_b)

  // Add implication ¬a → b
  self.adj[not_a].push(node_b)
  self.radj[node_b].push(not_a)

  // Add implication ¬b → a
  self.adj[not_b].push(node_a)
  self.radj[node_a].push(not_b)
}

///|
/// Add the implication `(a → b)` to the 2-SAT instance.
///
/// The implication `a → b` is logically equivalent to the clause `(¬a ∨ b)`,
/// so this method is a thin wrapper around `add_clause`.
///
/// Parameters:
/// - `var_a` / `neg_a`: index and negation flag of the antecedent literal.
/// - `var_b` / `neg_b`: index and negation flag of the consequent literal.
///
/// Example: to express "if `x0` is true then `x1` must also be true", call
/// `add_implication(0, false, 1, false)`.
fn TwoSat::add_implication(
  self : TwoSat,
  var_a : Int,
  neg_a : Bool,
  var_b : Int,
  neg_b : Bool,
) -> Unit {
  // a → b is equivalent to (¬a ∨ b)
  let not_neg_a = if neg_a { false } else { true }
  self.add_clause(var_a, not_neg_a, var_b, neg_b)
}

///|
/// Force variable `v` to take the given `value` in any solution.
///
/// Internally this is encoded as the unit clause `(v)` (when `value = true`)
/// or `(¬v)` (when `value = false`), expressed by adding the self-implication
/// clause `(L ∨ L)` for the corresponding literal `L`. Any solution returned
/// by `solve` will honour this constraint.
fn TwoSat::set_value(self : TwoSat, v : Int, value : Bool) -> Unit {
  // To force v = true: add clause (v ∨ v)
  // To force v = false: add clause (¬v ∨ ¬v)
  let not_value = if value { false } else { true }
  self.add_clause(v, not_value, v, not_value)
}

///|
/// Solve the 2-SAT instance using Kosaraju's SCC algorithm.
///
/// The algorithm proceeds in three phases:
/// 1. First DFS on the implication graph to compute nodes in post-order
///    (finish time order).
/// 2. Second DFS on the reverse graph in reverse finish order, labelling each
///    DFS tree as one SCC.
/// 3. For each variable `x_i`, check that `x_i` and `¬x_i` belong to
///    different SCCs (otherwise the formula is unsatisfiable). If they do,
///    set `x_i = true` when `comp[x_i] > comp[¬x_i]` (i.e., `x_i`'s SCC
///    was discovered later in the second pass, meaning it sits higher in the
///    reverse-topological order).
///
/// Returns `Some(assignment)` where `assignment[i]` is the boolean value of
/// variable `i`, or `None` if the formula has no solution.
fn TwoSat::solve(self : TwoSat) -> Array[Bool]? {
  let num_nodes = 2 * self.n
  if num_nodes == 0 {
    return Some([])
  }

  // Kosaraju's algorithm for SCCs
  let visited = Array::make(num_nodes, false)
  let order : Array[Int] = []

  // First DFS: compute finish order
  for i in 0..<num_nodes {
    if !visited[i] {
      dfs1(self.adj, visited, order, i)
    }
  } where {
    proof_invariant: i >= 0 && i <= num_nodes,
    proof_reasoning: (
      #|INVARIANT (finish order):
      #|All nodes in [0, i) have been visited and added to order by finish time.
      #|MAINTENANCE:
      #|Run DFS from each unvisited node to append its post-order finish.
      #|TERMINATION:
      #|At i = num_nodes, order stores nodes by decreasing finish time.
    ),
  }

  // Second DFS: find SCCs in reverse finish order
  let comp = Array::make(num_nodes, -1)
  let _ = for i in num_nodes>..0; num_scc = 0 {
    let node = order[i]
    if comp[node] < 0 {
      dfs2(self.radj, comp, num_scc, node)
      continue num_scc + 1
    }
    continue num_scc
  } nobreak {
    num_scc
  }

  // Check satisfiability: x and ¬x must be in different SCCs
  let assignment = Array::make(self.n, false)
  for i in 0..<self.n {
    let node_true = 2 * i
    let node_false = 2 * i + 1
    if comp[node_true] == comp[node_false] {
      return None // Contradiction: x ↔ ¬x
    }
    // Assign based on SCC order: if comp[x] > comp[¬x], then x = true
    // Higher SCC number = earlier in reverse topo order = should be true
    assignment[i] = comp[node_true] > comp[node_false]
  } where {
    proof_invariant: i >= 0 && i <= self.n,
    proof_reasoning: (
      #|INVARIANT (assignment):
      #|All variables in [0, i) have been assigned consistently with SCC order.
      #|MAINTENANCE:
      #|If x and ¬x are in the same SCC, return None; otherwise, assign x to
      #|true if its SCC comes later in reverse topological order.
      #|TERMINATION:
      #|At i = n, a full satisfying assignment is produced.
    ),
  }
  Some(assignment)
}

///|
/// First DFS pass for Kosaraju's algorithm.
///
/// Performs a standard depth-first search from node `u` on the forward
/// implication graph `adj`. Each node is appended to `order` in post-order
/// (i.e., after all its descendants have been visited), so `order` ends up
/// sorted by increasing finish time.
fn dfs1(
  adj : Array[Array[Int]],
  visited : Array[Bool],
  order : Array[Int],
  u : Int,
) -> Unit {
  visited[u] = true
  for v in adj[u] {
    if !visited[v] {
      dfs1(adj, visited, order, v)
    }
  }
  order.push(u) // Post-order
}

///|
/// Second DFS pass for Kosaraju's algorithm.
///
/// Performs a depth-first search from node `u` on the reverse implication
/// graph `radj`, assigning `scc_id` to every reachable unassigned node.
/// Because the second pass is driven in reverse finish-time order on the
/// transposed graph, each tree of this DFS corresponds to exactly one SCC.
fn dfs2(
  radj : Array[Array[Int]],
  comp : Array[Int],
  scc_id : Int,
  u : Int,
) -> Unit {
  comp[u] = scc_id
  for v in radj[u] {
    if comp[v] < 0 {
      dfs2(radj, comp, scc_id, v)
    }
  }
}

///|
/// Verify that `assignment` satisfies every implication in the graph.
///
/// For each node `u` whose literal evaluates to `true` under `assignment`,
/// the method checks that every node `v` directly implied by `u` also
/// evaluates to `true`. Returns `true` if all implications hold, `false`
/// otherwise.
///
/// This is useful as a post-solve sanity check: `solve` guarantees a correct
/// result, but `verify` can independently confirm it in O(n + m).
fn TwoSat::verify(self : TwoSat, assignment : Array[Bool]) -> Bool {
  for u in 0..<(2 * self.n) {
    let var_u = u / 2
    let neg_u = u % 2 == 1
    let val_u = if neg_u { !assignment[var_u] } else { assignment[var_u] }
    if val_u {
      // If u is true, all nodes reachable from u must be true
      for v in self.adj[u] {
        let var_v = v / 2
        let neg_v = v % 2 == 1
        let val_v = if neg_v { !assignment[var_v] } else { assignment[var_v] }
        if !val_v {
          return false
        }
      }
    }
  } where {
    proof_invariant: u >= 0 && u <= 2 * self.n,
    proof_reasoning: (
      #|INVARIANT (verify all nodes):
      #|All implication nodes in [0..u) have been validated against assignment.
      #|MAINTENANCE:
      #|If val_u is true, check all outgoing implications; otherwise skip.
      #|TERMINATION:
      #|At u == 2 * n, every implication is satisfied by assignment.
    ),
  }
  true
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "two sat basic satisfiable" {
  let sat = TwoSat(2)
  // (x0 ∨ x1) ∧ (¬x0 ∨ x1)
  // Solution: x1 = true
  sat.add_clause(0, false, 1, false) // x0 ∨ x1
  sat.add_clause(0, true, 1, false) // ¬x0 ∨ x1
  match sat.solve() {
    Some(assignment) => {
      inspect(assignment[1], content="true") // x1 must be true
      inspect(sat.verify(assignment), content="true")
    }
    None => inspect(false, content="true") // Should be satisfiable
  }
}

///|
test "two sat unsatisfiable" {
  let sat = TwoSat(1)
  // (x0) ∧ (¬x0)
  sat.add_clause(0, false, 0, false) // x0 ∨ x0 = x0
  sat.add_clause(0, true, 0, true) // ¬x0 ∨ ¬x0 = ¬x0
  match sat.solve() {
    Some(_) => inspect(false, content="true") // Should be unsatisfiable
    None => inspect(true, content="true")
  }
}

///|
test "two sat three variables" {
  let sat = TwoSat(3)
  // (x0 ∨ x1) ∧ (¬x1 ∨ x2) ∧ (¬x0 ∨ ¬x2)
  sat.add_clause(0, false, 1, false) // x0 ∨ x1
  sat.add_clause(1, true, 2, false) // ¬x1 ∨ x2
  sat.add_clause(0, true, 2, true) // ¬x0 ∨ ¬x2
  match sat.solve() {
    Some(assignment) => inspect(sat.verify(assignment), content="true")
    None => inspect(false, content="true")
  }
}

///|
test "two sat set value" {
  let sat = TwoSat(2)
  sat.set_value(0, true) // Force x0 = true
  sat.add_clause(0, false, 1, false) // x0 ∨ x1
  match sat.solve() {
    Some(assignment) => {
      inspect(assignment[0], content="true")
      inspect(sat.verify(assignment), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "two sat implication" {
  let sat = TwoSat(2)
  sat.add_implication(0, false, 1, false) // x0 → x1
  sat.set_value(0, true) // x0 = true
  match sat.solve() {
    Some(assignment) => {
      inspect(assignment[0], content="true")
      inspect(assignment[1], content="true") // Must be true due to implication
      inspect(sat.verify(assignment), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "two sat empty" {
  let sat = TwoSat(0)
  match sat.solve() {
    Some(assignment) => inspect(assignment.length(), content="0")
    None => inspect(false, content="true")
  }
}

///|
test "two sat complex" {
  let sat = TwoSat(4)
  // (x0 ∨ x1) ∧ (x1 ∨ x2) ∧ (x2 ∨ x3) ∧ (¬x0 ∨ ¬x3)
  sat.add_clause(0, false, 1, false)
  sat.add_clause(1, false, 2, false)
  sat.add_clause(2, false, 3, false)
  sat.add_clause(0, true, 3, true)
  match sat.solve() {
    Some(assignment) => inspect(sat.verify(assignment), content="true")
    None => inspect(false, content="true")
  }
}

///|
test "two sat chain contradiction" {
  let sat = TwoSat(3)
  // x0 → x1 → x2 → ¬x0
  sat.add_implication(0, false, 1, false) // x0 → x1
  sat.add_implication(1, false, 2, false) // x1 → x2
  sat.add_implication(2, false, 0, true) // x2 → ¬x0
  sat.set_value(0, true) // x0 = true

  // This creates x0 → x1 → x2 → ¬x0, contradiction
  match sat.solve() {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}
