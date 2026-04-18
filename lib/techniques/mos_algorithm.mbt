// Mo's Algorithm and Square Root Decomposition Techniques
// with rigorous loop invariants and mathematical reasoning

///|
/// Compute integer square root for Mo's algorithm
fn mo_isqrt(n : Int) -> Int {
  if n <= 0 {
    return 1
  }
  for x = n {
    let next = (x + n / x) / 2
    if next >= x {
      break x
    }
    continue next
  } where {
    proof_invariant: x > 0,
    proof_reasoning: (
      #|INVARIANT (integer sqrt):
      #|x is a positive estimate for sqrt(n); the sequence stays positive and
      #|moves toward a fixed point.
      #|MAINTENANCE:
      #|next = (x + n / x) / 2 shrinks the estimate when it's above sqrt(n),
      #|so the sequence is non-increasing after a few steps.
      #|TERMINATION:
      #|When next >= x, x is the stable integer estimate and equals floor(sqrt(n)).
    ),
  }
}

///|
/// Mo's Algorithm for Range Sum Queries (Simplified)
///
/// MATHEMATICAL FOUNDATION:
/// Mo's algorithm answers range queries offline by reordering them to minimize
/// the total number of add/remove operations on endpoints.
///
/// KEY INSIGHT:
/// Divide array into √n blocks. Sort queries by:
/// 1. Block of left endpoint
/// 2. Right endpoint (within same block)
///
/// TIME COMPLEXITY: O((n + q) × √n) for q queries on array of size n
fn mos_algorithm_range_sum(
  arr : ArrayView[Int],
  queries : Array[(Int, Int)],
) -> Array[Int] {
  let n = arr.length()
  let q = queries.length()
  if n == 0 || q == 0 {
    return Array::make(q, 0)
  }
  let block_size = mo_isqrt(n)

  // Create and sort query indices using bubble sort
  let query_order = [ for i in 0..<q => i ]
  for i in 0..<(q - 1) {
    let last = q - 1 - i
    for j in 0..<last {
      let idx1 = query_order[j]
      let idx2 = query_order[j + 1]
      let (l1, r1) = queries[idx1]
      let (l2, r2) = queries[idx2]
      let block1 = l1 / block_size
      let block2 = l2 / block_size
      let should_swap = if block1 != block2 { block1 > block2 } else { r1 > r2 }
      if should_swap {
        query_order[j] = idx2
        query_order[j + 1] = idx1
      }
    }
  }
  let results : Array[Int] = Array::make(q, 0)
  for i in 0..<q; curr_l = 0, curr_r = 0, curr_sum = 0 {
    let query_idx = query_order[i]
    let (ql, qr) = queries[query_idx]

    // Expand right
    let (curr_r2, sum2) = for r = curr_r, s = curr_sum; r < qr; {
      continue r + 1, s + arr[r]
    } nobreak {
      (r, s)
    } where {
      proof_invariant: r >= curr_r && r <= qr,
      proof_reasoning: (
        #|INVARIANT (expand right):
        #|s equals sum(arr[curr_l..r)); the range grows to the right.
        #|MAINTENANCE:
        #|Add arr[r] and advance r, preserving s as the sum of the extended range.
        #|TERMINATION:
        #|At r == qr, the right boundary matches the query.
      ),
    }

    // Shrink right
    let (curr_r3, sum3) = for r = curr_r2, s = sum2; r > qr; {
      continue r - 1, s - arr[r - 1]
    } nobreak {
      (r, s)
    } where {
      proof_invariant: r >= qr && r <= curr_r2,
      proof_reasoning: (
        #|INVARIANT (shrink right):
        #|s equals sum(arr[curr_l..r)); the range shrinks from the right.
        #|MAINTENANCE:
        #|Subtract arr[r-1] and decrement r to remove the last element.
        #|TERMINATION:
        #|At r == qr, the right boundary matches the query.
      ),
    }

    // Shrink left
    let (curr_l2, sum4) = for l = curr_l, s = sum3; l < ql; {
      continue l + 1, s - arr[l]
    } nobreak {
      (l, s)
    } where {
      proof_invariant: l >= curr_l && l <= ql,
      proof_reasoning: (
        #|INVARIANT (shrink left):
        #|s equals sum(arr[l..curr_r3)); the range shrinks from the left.
        #|MAINTENANCE:
        #|Subtract arr[l] and advance l to drop the leftmost element.
        #|TERMINATION:
        #|At l == ql, the left boundary matches the query.
      ),
    }

    // Expand left
    let (curr_l3, sum5) = for l = curr_l2, s = sum4; l > ql; {
      continue l - 1, s + arr[l - 1]
    } nobreak {
      (l, s)
    } where {
      proof_invariant: l >= ql && l <= curr_l2,
      proof_reasoning: (
        #|INVARIANT (expand left):
        #|s equals sum(arr[l..curr_r3)); the range grows to the left.
        #|MAINTENANCE:
        #|Decrement l and add arr[l-1] to include the new leftmost element.
        #|TERMINATION:
        #|At l == ql, the left boundary matches the query.
      ),
    }
    results[query_idx] = sum5
    continue curr_l3, curr_r3, sum5
  } nobreak {
    ()
  } where {
    proof_invariant: curr_l >= 0 && curr_r >= 0,
    proof_reasoning: (
      #|INVARIANT (mo main loop):
      #|curr_sum = sum(arr[curr_l..curr_r)) and results are filled for all
      #|queries in query_order[0..i).
      #|MAINTENANCE:
      #|Adjust curr_l/curr_r to the next query and record the resulting sum.
      #|TERMINATION:
      #|At i == q, all queries have been answered.
    ),
  }
  results
}

///|
test "mos algorithm range sum" {
  let arr = [1, 2, 3, 4, 5]
  let queries = [(0, 3), (1, 4), (0, 5)]
  let results = mos_algorithm_range_sum(arr, queries)
  assert_eq(results[0], 6) // 1+2+3 = 6
  assert_eq(results[1], 9) // 2+3+4 = 9
  assert_eq(results[2], 15) // 1+2+3+4+5 = 15
}

///|
/// Square Root Decomposition for Range Minimum Query
///
/// MATHEMATICAL FOUNDATION:
/// Divide array into √n blocks, precompute minimum for each block.
/// Query: check partial blocks directly + full blocks from precomputed values.
///
/// TIME: O(√n) per query, O(n) preprocessing
priv struct SqrtDecomposition {
  arr : Array[Int]
  block_mins : Array[Int]
  block_size : Int
}

///|
fn SqrtDecomposition::new(arr : Array[Int]) -> SqrtDecomposition {
  let n = arr.length()
  if n == 0 {
    return { arr, block_mins: [], block_size: 1 }
  }
  let block_size = mo_isqrt(n)
  let num_blocks = (n + block_size - 1) / block_size
  let block_mins : Array[Int] = Array::make(num_blocks, 2147483647)
  for i in 0..<n {
    let block_idx = i / block_size
    if arr[i] < block_mins[block_idx] {
      block_mins[block_idx] = arr[i]
    }
  }
  { arr, block_mins, block_size }
}

///|
fn SqrtDecomposition::query_min(
  self : SqrtDecomposition,
  l : Int,
  r : Int,
) -> Int {
  if l >= r || l < 0 || r > self.arr.length() {
    return 2147483647
  }
  for i = l, result = 2147483647; i < r; {
    let block_idx = i / self.block_size
    let block_end = @cmp.minimum((block_idx + 1) * self.block_size, r)
    if i == block_idx * self.block_size &&
      block_end == (block_idx + 1) * self.block_size {
      // Full block
      let new_result = @cmp.minimum(result, self.block_mins[block_idx])
      continue block_end, new_result
    } else {
      // Partial block
      let new_result = @cmp.minimum(result, self.arr[i])
      continue i + 1, new_result
    }
  } nobreak {
    result
  } where {
    proof_invariant: i >= l && i <= r,
    proof_reasoning: (
      #|INVARIANT (range min):
      #|result = min(arr[l..i)); indices [i..r) remain to be processed.
      #|MAINTENANCE:
      #|If i aligns with a full block, use block_mins and jump; otherwise scan
      #|element-by-element and advance i.
      #|TERMINATION:
      #|At i == r, result is the minimum over arr[l..r).
    ),
  }
}

///|
fn SqrtDecomposition::update_sqrt(
  self : SqrtDecomposition,
  idx : Int,
  val : Int,
) -> Unit {
  if idx < 0 || idx >= self.arr.length() {
    return
  }
  self.arr[idx] = val
  let block_idx = idx / self.block_size
  let block_start = block_idx * self.block_size
  let block_end = @cmp.minimum(block_start + self.block_size, self.arr.length())
  self.block_mins[block_idx] = 2147483647
  for i in block_start..<block_end {
    if self.arr[i] < self.block_mins[block_idx] {
      self.block_mins[block_idx] = self.arr[i]
    }
  }
}

///|
test "sqrt decomposition rmq" {
  let arr = [3, 1, 4, 1, 5, 9, 2, 6]
  let sd = SqrtDecomposition::new(arr)
  assert_eq(sd.query_min(0, 4), 1)
  assert_eq(sd.query_min(4, 8), 2)
  assert_eq(sd.query_min(2, 6), 1)
  sd.update_sqrt(1, 10)
  assert_eq(sd.query_min(0, 4), 1)
  sd.update_sqrt(3, 10)
  assert_eq(sd.query_min(0, 4), 3)
}

///|
/// Range Mode Query (Most Frequent Element)
///
/// Simplified version using direct counting per query.
fn range_mode(arr : ArrayView[Int], queries : Array[(Int, Int)]) -> Array[Int] {
  let n = arr.length()
  let q = queries.length()
  if n == 0 || q == 0 {
    return Array::make(q, 0)
  }
  let results : Array[Int] = Array::make(q, 0)
  let max_val = 1000
  let freq : Array[Int] = Array::make(max_val + 1, 0)
  for qi in 0..<q {
    let (l, r) = queries[qi]

    // Reset frequencies
    for i in 0..<=max_val {
      freq[i] = 0
    }

    // Count frequencies
    for i in l..<r {
      let val = arr[i]
      if val >= 0 && val <= max_val {
        freq[val] = freq[val] + 1
      }
    }

    // Find mode
    let mode = for i in 0..<=max_val; best = 0, best_freq = 0 {
      if freq[i] > best_freq {
        continue i, freq[i]
      }
      continue best, best_freq
    } nobreak {
      best
    } where {
      proof_invariant: best >= 0 && best_freq >= 0,
      proof_reasoning: (
        #|INVARIANT (find mode):
        #|best/best_freq is the most frequent value in [0..i).
        #|MAINTENANCE:
        #|Compare freq[i] to best_freq and update if larger.
        #|TERMINATION:
        #|At i == max_val + 1, best is the mode.
      ),
    }
    results[qi] = mode
  }
  results
}

///|
test "range mode query" {
  let arr = [1, 2, 1, 1, 2, 3, 2, 2]
  let queries = [(0, 4), (4, 8), (0, 8)]
  let results = range_mode(arr, queries)
  assert_eq(results[0], 1) // [1,2,1,1] -> mode is 1
  assert_eq(results[1], 2) // [2,3,2,2] -> mode is 2
  assert_eq(results[2], 2) // full array -> mode is 2
}

///|
/// Block Decomposition for Range Sum with Updates
///
/// O(√n) for both query and update.
priv struct BlockSum {
  arr : Array[Int]
  block_sums : Array[Int]
  block_size : Int
}

///|
fn BlockSum::new(arr : Array[Int]) -> BlockSum {
  let n = arr.length()
  if n == 0 {
    return { arr, block_sums: [], block_size: 1 }
  }
  let block_size = mo_isqrt(n)
  let num_blocks = (n + block_size - 1) / block_size
  let block_sums : Array[Int] = Array::make(num_blocks, 0)
  for i in 0..<n {
    block_sums[i / block_size] = block_sums[i / block_size] + arr[i]
  }
  { arr, block_sums, block_size }
}

///|
fn BlockSum::query_sum(self : BlockSum, l : Int, r : Int) -> Int {
  if l >= r || l < 0 || r > self.arr.length() {
    return 0
  }
  for i = l, result = 0; i < r; {
    let block_idx = i / self.block_size
    let block_start = block_idx * self.block_size
    let block_end = @cmp.minimum(block_start + self.block_size, r)
    if i == block_start &&
      block_end == block_start + self.block_size &&
      block_end <= r {
      // Full block
      continue block_end, result + self.block_sums[block_idx]
    } else {
      // Partial
      continue i + 1, result + self.arr[i]
    }
  } nobreak {
    result
  } where {
    proof_invariant: i >= l && i <= r,
    proof_reasoning: (
      #|INVARIANT (range sum):
      #|result = sum(arr[l..i)); indices [i..r) remain.
      #|MAINTENANCE:
      #|If i aligns to a full block, add its sum and jump; otherwise add arr[i]
      #|and advance i.
      #|TERMINATION:
      #|At i == r, result equals sum(arr[l..r)).
    ),
  }
}

///|
fn BlockSum::update_block_sum(self : BlockSum, idx : Int, val : Int) -> Unit {
  if idx < 0 || idx >= self.arr.length() {
    return
  }
  let diff = val - self.arr[idx]
  self.arr[idx] = val
  self.block_sums[idx / self.block_size] = self.block_sums[idx / self.block_size] +
    diff
}

///|
test "block sum" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let bs = BlockSum::new(arr)
  assert_eq(bs.query_sum(0, 5), 15) // 1+2+3+4+5
  assert_eq(bs.query_sum(3, 7), 22) // 4+5+6+7
  bs.update_block_sum(4, 10) // Change 5 to 10
  assert_eq(bs.query_sum(0, 5), 20) // 1+2+3+4+10
}

///|
/// Union-Find with Path Compression (renamed to avoid conflict)
///
/// MATHEMATICAL FOUNDATION:
/// Amortized O(α(n)) per operation where α is inverse Ackermann function.
priv struct MoUnionFind {
  parent : Array[Int]
  rank : Array[Int]
}

///|
fn MoUnionFind::new(n : Int) -> MoUnionFind {
  let parent = [ for i in 0..<n => i ]
  let rank : Array[Int] = Array::make(n, 0)
  { parent, rank }
}

///|
fn MoUnionFind::find_mo(self : MoUnionFind, x : Int) -> Int {
  for curr = x; curr != self.parent[curr]; {
    let grandparent = self.parent[self.parent[curr]]
    self.parent[curr] = grandparent
    continue grandparent
  } nobreak {
    curr
  } where {
    proof_invariant: curr >= 0 && curr < self.parent.length(),
    proof_reasoning: (
      #|INVARIANT (find with compression):
      #|curr is on the path from x to the root; parent pointers remain valid.
      #|MAINTENANCE:
      #|Jump to grandparent and compress the path, shortening future finds.
      #|TERMINATION:
      #|When curr is a root, return it as the representative.
    ),
  }
}

///|
fn MoUnionFind::union_mo(self : MoUnionFind, x : Int, y : Int) -> Bool {
  let px = self.find_mo(x)
  let py = self.find_mo(y)
  if px == py {
    return false
  }
  if self.rank[px] < self.rank[py] {
    self.parent[px] = py
  } else if self.rank[px] > self.rank[py] {
    self.parent[py] = px
  } else {
    self.parent[py] = px
    self.rank[px] = self.rank[px] + 1
  }
  true
}

///|
test "mo union find" {
  let uf = MoUnionFind::new(5)
  assert_true(uf.union_mo(0, 1))
  assert_true(uf.union_mo(2, 3))
  assert_eq(uf.find_mo(0), uf.find_mo(1))
  assert_true(uf.find_mo(0) != uf.find_mo(2))
  assert_true(uf.union_mo(1, 3))
  assert_eq(uf.find_mo(0), uf.find_mo(3))
  assert_false(uf.union_mo(0, 2)) // Already connected
}

///|
/// Offline LCA using naive approach
///
/// Process queries offline during DFS traversal.
fn offline_lca_simple(
  adj : Array[Array[Int]],
  queries : Array[(Int, Int)],
  root : Int,
) -> Array[Int] {
  let n = adj.length()
  let q = queries.length()
  let results : Array[Int] = Array::make(q, -1)
  let parent : Array[Int] = Array::make(n, -1)
  let depth : Array[Int] = Array::make(n, 0)

  // BFS to compute parent and depth
  let queue : Array[Int] = []
  let visited : Array[Bool] = Array::make(n, false)
  queue.push(root)
  visited[root] = true
  for front = 0 {
    match queue.get(front) {
      Some(node) => {
        for child in adj[node] {
          if !visited[child] {
            visited[child] = true
            parent[child] = node
            depth[child] = depth[node] + 1
            queue.push(child)
          }
        }
        continue front + 1
      }
      None => break
    }
  }

  // Answer queries
  for qi in 0..<q {
    let (u, v) = queries[qi]
    let u_curr = for u_curr = u; depth[u_curr] > depth[v]; {
      continue parent[u_curr]
    } nobreak {
      u_curr
    }
    let v_curr = for v_curr = v; depth[v_curr] > depth[u_curr]; {
      continue parent[v_curr]
    } nobreak {
      v_curr
    }
    let u_curr = for u_curr = u_curr, v_curr = v_curr; u_curr != v_curr; {
      continue parent[u_curr], parent[v_curr]
    } nobreak {
      u_curr
    }
    results[qi] = u_curr
  }
  results
}

///|
test "offline lca simple" {
  let adj : Array[Array[Int]] = [[1, 2], [0, 3, 4], [0], [1], [1]]
  let queries = [(3, 4), (3, 2), (1, 2)]
  let results = offline_lca_simple(adj, queries, 0)
  assert_eq(results[0], 1) // LCA(3,4) = 1
  assert_eq(results[1], 0) // LCA(3,2) = 0
  assert_eq(results[2], 0) // LCA(1,2) = 0
}

///|
/// Centroid of a Tree
///
/// A centroid is a node whose removal creates subtrees each with ≤ n/2 nodes.
fn find_tree_centroid(adj : Array[Array[Int]], root : Int) -> Int {
  let n = adj.length()
  let subtree_size : Array[Int] = Array::make(n, 0)
  let parent : Array[Int] = Array::make(n, -1)
  let stack : Array[(Int, Int)] = []
  let order : Array[Int] = []
  stack.push((root, -1))
  let _ = for popped = stack.pop() {
    match popped {
      None => break ()
      Some((node, par)) => {
        parent[node] = par
        order.push(node)
        for child in adj[node] {
          if child != par {
            stack.push((child, node))
          }
        }
        continue stack.pop()
      }
    }
  }
  for i in order.length()>..0 {
    let node = order[i]
    subtree_size[node] = 1
    for child in adj[node] {
      if child != parent[node] {
        subtree_size[node] = subtree_size[node] + subtree_size[child]
      }
    }
  }
  let tree_size = subtree_size[root]
  for i = 0, centroid = root; i < n; {
    let node = order[i]
    let is_centroid = for neighbor_i in 0..<adj[node].length() {
      let neighbor = adj[node][neighbor_i]
      let subtree = if neighbor == parent[node] {
        tree_size - subtree_size[node]
      } else {
        subtree_size[neighbor]
      }
      if subtree > tree_size / 2 {
        break false
      }
    } nobreak {
      true
    }
    if is_centroid {
      continue n, node
    }
    continue i + 1, centroid
  } nobreak {
    centroid
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (find centroid):
      #|All nodes in order[0..i) have been checked; centroid holds any found.
      #|MAINTENANCE:
      #|Check order[i] and return it if all neighbor subtrees are <= n/2.
      #|TERMINATION:
      #|At i == n, a centroid has been found (tree always has one).
    ),
  }
}

///|
test "find tree centroid" {
  let adj : Array[Array[Int]] = [[1], [0, 2], [1, 3], [2, 4], [3]]
  let centroid = find_tree_centroid(adj, 0)
  assert_eq(centroid, 2) // Middle node
}

///|
/// Euler Tour for Subtree Queries
///
/// Maps tree to array: subtree[v] = arr[enter[v]..exit[v]]
priv struct EulerTour {
  enter : Array[Int]
  exit : Array[Int]
  tour : Array[Int]
}

///|
fn build_euler_tour(adj : Array[Array[Int]], root : Int) -> EulerTour {
  let n = adj.length()
  let enter : Array[Int] = Array::make(n, 0)
  let exit : Array[Int] = Array::make(n, 0)
  let tour : Array[Int] = []
  let stack : Array[(Int, Int, Int)] = []
  stack.push((root, -1, 0))
  let time = Array::make(1, 0)
  let _ = for popped = stack.pop() {
    match popped {
      None => break ()
      Some((node, par, state)) => {
        if state == 0 {
          enter[node] = time[0]
          tour.push(node)
          time[0] = time[0] + 1
          stack.push((node, par, 1))
          for i in adj[node].length()>..0 {
            let child = adj[node][i]
            if child != par {
              stack.push((child, node, 0))
            }
          }
        } else {
          exit[node] = time[0]
        }
        continue stack.pop()
      }
    }
  }
  { enter, exit, tour }
}

///|
test "euler tour" {
  let adj : Array[Array[Int]] = [[1, 2], [0, 3], [0], [1]]
  let et = build_euler_tour(adj, 0)
  assert_true(et.enter[1] < et.enter[3])
  assert_true(et.enter[3] < et.exit[1])
  assert_eq(et.tour.length(), adj.length())
}

///|
/// Binary Lifting for LCA in O(log n)
///
/// Precompute 2^k ancestors for each node.
priv struct BinaryLifting {
  up : Array[Array[Int]]
  depth : Array[Int]
  log_n : Int
}

///|
fn build_binary_lifting(adj : Array[Array[Int]], root : Int) -> BinaryLifting {
  let n = adj.length()
  let log_n = 20
  let up = [ for _ in 0..<n => Array::make(log_n, -1) ]
  let depth : Array[Int] = Array::make(n, 0)
  let queue : Array[Int] = []
  let visited : Array[Bool] = Array::make(n, false)
  queue.push(root)
  visited[root] = true
  up[root][0] = root
  for front = 0 {
    match queue.get(front) {
      Some(node) => {
        for child in adj[node] {
          if !visited[child] {
            visited[child] = true
            depth[child] = depth[node] + 1
            up[child][0] = node
            queue.push(child)
          }
        }
        continue front + 1
      }
      None => break
    }
  }
  for k in 1..<log_n {
    for v in 0..<n {
      let half_ancestor = up[v][k - 1]
      if half_ancestor >= 0 {
        up[v][k] = up[half_ancestor][k - 1]
      }
    }
  }
  { up, depth, log_n }
}

///|
fn BinaryLifting::lca_binary_lifting(
  self : BinaryLifting,
  u_in : Int,
  v_in : Int,
) -> Int {
  let (u, v) = if self.depth[u_in] < self.depth[v_in] {
    (v_in, u_in)
  } else {
    (u_in, v_in)
  }
  let diff = self.depth[u] - self.depth[v]
  let u = for k in 0..<self.log_n; u = u {
    let u = if ((diff >> k) & 1) == 1 { self.up[u][k] } else { u }
    continue u
  } nobreak {
    u
  } where {
    proof_invariant: u >= 0,
    proof_reasoning: (
      #|INVARIANT (lift to depth):
      #|After processing bits < k, u has been lifted by those bits of diff.
      #|MAINTENANCE:
      #|If bit k is set, jump u to its 2^k ancestor.
      #|TERMINATION:
      #|At k == log_n, u and v are at the same depth.
    ),
  }
  if u == v {
    return u
  }
  let u = for bit in self.log_n>=..1; u = u, v = v {
    let k = bit - 1
    let (u, v) = if self.up[u][k] != self.up[v][k] {
      (self.up[u][k], self.up[v][k])
    } else {
      (u, v)
    }
    continue u, v
  } nobreak {
    u
  }
  self.up[u][0]
}

///|
test "binary lifting lca" {
  let adj : Array[Array[Int]] = [[1, 2], [0, 3, 4], [0], [1], [1]]
  let bl = build_binary_lifting(adj, 0)
  assert_eq(bl.lca_binary_lifting(3, 4), 1)
  assert_eq(bl.lca_binary_lifting(3, 2), 0)
  assert_eq(bl.lca_binary_lifting(1, 2), 0)
  assert_eq(bl.lca_binary_lifting(3, 1), 1)
}
