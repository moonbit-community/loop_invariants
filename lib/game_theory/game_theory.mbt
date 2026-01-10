// ============================================================================
// SPRAGUE-GRUNDY THEOREM - Combinatorial Game Theory
// ============================================================================
//
// Analyzes impartial two-player games with perfect information.
// Each position has a Grundy number (nimber) that determines the winner.
//
// SPRAGUE-GRUNDY THEOREM:
// - Grundy(position) = mex{Grundy(reachable positions)}
// - mex (minimum excludant) is the smallest non-negative integer not in set
// - Position is losing (P-position) iff Grundy number = 0
// - For combined games: Grundy = XOR of individual Grundy numbers
//
// NIM GAME:
// - n piles with different numbers of stones
// - Players take any positive number from one pile
// - Grundy(pile of k) = k
// - XOR of all pile sizes = 0 means second player wins
//
// INVARIANTS:
// 1. mex of empty set is 0
// 2. Losing positions have Grundy = 0
// 3. From any winning position, we can reach a losing position
//
// TIME COMPLEXITY: Depends on game (often O(n²) for n positions)
// SPACE COMPLEXITY: O(n) for memoization

///|
/// Minimum excludant: smallest non-negative integer not in set
fn mex(set : Array[Int]) -> Int {
  let present : Map[Int, Bool] = {}
  for i = 0; i < set.length(); i = i + 1 {
    present[set[i]] = true
  }

  let mut result = 0
  while present.contains(result) {
    result = result + 1
  }
  result
}

///|
/// Classic Nim: Grundy number is pile size
fn nim_grundy(pile : Int) -> Int {
  pile
}

///|
/// Nim game with multiple piles
/// Returns true if first player wins (XOR != 0)
fn nim_wins(piles : Array[Int]) -> Bool {
  let mut xor_sum = 0
  for i = 0; i < piles.length(); i = i + 1 {
    xor_sum = xor_sum.lxor(piles[i])
  }
  xor_sum != 0
}

///|
/// Find winning move in Nim (returns pile index and new size)
fn nim_winning_move(piles : Array[Int]) -> (Int, Int)? {
  let mut xor_sum = 0
  for i = 0; i < piles.length(); i = i + 1 {
    xor_sum = xor_sum.lxor(piles[i])
  }

  if xor_sum == 0 {
    return None // Losing position
  }

  // Find pile to reduce
  for i = 0; i < piles.length(); i = i + 1 {
    let new_size = piles[i].lxor(xor_sum)
    if new_size < piles[i] {
      return Some((i, new_size))
    }
  }

  None
}

// ============================================================================
// SUBTRACTION GAME
// ============================================================================

///|
/// Subtraction game: can take 1 to k stones
/// Grundy(n) for this game
fn subtraction_grundy(n : Int, max_take : Int) -> Int {
  n % (max_take + 1)
}

///|
/// General subtraction game with arbitrary allowed moves
fn subtraction_game_grundy(n : Int, allowed : Array[Int], memo : Map[Int, Int]) -> Int {
  if n <= 0 {
    return 0
  }

  if memo.contains(n) {
    return memo[n]
  }

  let reachable : Array[Int] = []
  for i = 0; i < allowed.length(); i = i + 1 {
    if allowed[i] <= n {
      let next_grundy = subtraction_game_grundy(n - allowed[i], allowed, memo)
      reachable.push(next_grundy)
    }
  }

  let result = mex(reachable)
  memo[n] = result
  result
}

// ============================================================================
// WYTHOFF'S GAME
// ============================================================================

///|
/// Wythoff's game: two piles, can take from one or equal from both
/// Returns true if position (a, b) is a P-position (second player wins)
fn wythoff_p_position(a : Int, b : Int) -> Bool {
  // P-positions are (⌊nφ⌋, ⌊nφ²⌋) for n = 0, 1, 2, ...
  // where φ = (1 + √5) / 2 ≈ 1.618

  let min_val = if a < b { a } else { b }
  let max_val = if a > b { a } else { b }

  // φ ≈ 1.6180339887
  // Check if min = floor(n * phi) and max = floor(n * phi^2)
  // This is equivalent to checking diff = n and min = floor(n * phi)

  let diff = max_val - min_val
  // n should be diff
  // min should be floor(diff * phi)

  let phi = 1.6180339887
  let expected_min = (diff.to_double() * phi).to_int()

  min_val == expected_min
}

// ============================================================================
// STAIRCASE NIM
// ============================================================================

///|
/// Staircase Nim: stairs 0, 1, 2, ..., n with coins
/// Can move coins from stair i to stair i-1
/// Stair 0 coins are removed
/// Equivalent to Nim on odd-indexed stairs
fn staircase_nim_wins(stairs : Array[Int]) -> Bool {
  let mut xor_sum = 0
  for i = 1; i < stairs.length(); i = i + 2 {
    xor_sum = xor_sum.lxor(stairs[i])
  }
  xor_sum != 0
}

// ============================================================================
// GRUNDY NUMBER COMPUTATION FOR GENERAL GAMES
// ============================================================================

///|
priv struct GameState {
  id : Int
  mut grundy : Int
  moves : Array[Int] // IDs of reachable states
}

///|
priv struct Game {
  states : Array[GameState]
}

///|
fn Game::new(n : Int) -> Game {
  let states = Array::make(n, { id: 0, grundy: -1, moves: [] })
  for i = 0; i < n; i = i + 1 {
    states[i] = { id: i, grundy: -1, moves: [] }
  }
  { states }
}

///|
fn Game::add_move(self : Game, from : Int, to : Int) -> Unit {
  self.states[from].moves.push(to)
}

///|
fn Game::compute_grundy(self : Game, state : Int) -> Int {
  if self.states[state].grundy >= 0 {
    return self.states[state].grundy
  }

  let moves = self.states[state].moves
  if moves.length() == 0 {
    self.states[state].grundy = 0
    return 0
  }

  let reachable : Array[Int] = []
  for i = 0; i < moves.length(); i = i + 1 {
    reachable.push(self.compute_grundy(moves[i]))
  }

  let g = mex(reachable)
  self.states[state].grundy = g
  g
}

///|
fn Game::compute_all_grundy(self : Game) -> Unit {
  for i = 0; i < self.states.length(); i = i + 1 {
    let _ = self.compute_grundy(i)

  }
}

// ============================================================================
// KAYLES GAME
// ============================================================================

///|
/// Kayles: knock down 1 or 2 adjacent pins from a row
/// Grundy numbers for rows of length n
fn kayles_grundy(n : Int, memo : Map[Int, Int]) -> Int {
  if n <= 0 {
    return 0
  }

  if memo.contains(n) {
    return memo[n]
  }

  let reachable : Array[Int] = []

  // Knock down 1 pin at position i
  for i = 0; i < n; i = i + 1 {
    // Splits into two rows of length i and n-i-1
    let g = kayles_grundy(i, memo).lxor(kayles_grundy(n - i - 1, memo))
    reachable.push(g)
  }

  // Knock down 2 adjacent pins at positions i, i+1
  for i = 0; i < n - 1; i = i + 1 {
    let g = kayles_grundy(i, memo).lxor(kayles_grundy(n - i - 2, memo))
    reachable.push(g)
  }

  let result = mex(reachable)
  memo[n] = result
  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "mex" {
  inspect(mex([]), content="0")
  inspect(mex([0]), content="1")
  inspect(mex([1]), content="0")
  inspect(mex([0, 1]), content="2")
  inspect(mex([0, 2]), content="1")
  inspect(mex([1, 2, 3]), content="0")
  inspect(mex([0, 1, 2, 4]), content="3")
}

///|
test "nim grundy" {
  for i = 0; i < 10; i = i + 1 {
    inspect(nim_grundy(i), content="\{i}")
  }
}

///|
test "nim wins" {
  // Single pile: first player wins iff pile > 0
  inspect(nim_wins([0]), content="false")
  inspect(nim_wins([1]), content="true")
  inspect(nim_wins([5]), content="true")

  // Two equal piles: second player wins (mirror strategy)
  inspect(nim_wins([3, 3]), content="false")
  inspect(nim_wins([5, 5]), content="false")

  // Classic 3-pile example
  inspect(nim_wins([1, 2, 3]), content="false") // 1 XOR 2 XOR 3 = 0
  inspect(nim_wins([1, 2, 4]), content="true")  // 1 XOR 2 XOR 4 = 7
}

///|
test "nim winning move" {
  // 1 XOR 2 XOR 4 = 7
  // To win, reduce pile 2 (size 4) to 4 XOR 7 = 3
  match nim_winning_move([1, 2, 4]) {
    Some((pile, new_size)) => {
      inspect(pile, content="2")
      inspect(new_size, content="3")
    }
    None => fail("Expected winning move")
  }

  // Losing position
  inspect(nim_winning_move([1, 2, 3]) is None, content="true")
}

///|
test "subtraction grundy" {
  // Can take 1-3: G(n) = n mod 4
  for i = 0; i < 12; i = i + 1 {
    inspect(subtraction_grundy(i, 3) == i % 4, content="true")
  }
}

///|
test "subtraction game arbitrary" {
  // Subtraction set {1, 3, 4}
  let allowed : Array[Int] = [1, 3, 4]
  let memo : Map[Int, Int] = {}

  // G(0) = 0 (no moves)
  inspect(subtraction_game_grundy(0, allowed, memo), content="0")

  // Compute first few
  let expected = [0, 1, 0, 1, 2, 3, 2, 0, 1, 0]
  for i = 0; i < expected.length(); i = i + 1 {
    let g = subtraction_game_grundy(i, allowed, memo)
    inspect(g == expected[i], content="true")
  }
}

///|
test "wythoff p positions" {
  // First few P-positions: (0,0), (1,2), (3,5), (4,7), (6,10)
  inspect(wythoff_p_position(0, 0), content="true")
  inspect(wythoff_p_position(1, 2), content="true")
  inspect(wythoff_p_position(2, 1), content="true")
  inspect(wythoff_p_position(3, 5), content="true")

  // N-positions
  inspect(wythoff_p_position(1, 1), content="false")
  inspect(wythoff_p_position(2, 2), content="false")
  inspect(wythoff_p_position(1, 3), content="false")
}

///|
test "staircase nim" {
  // Only odd stairs matter
  inspect(staircase_nim_wins([5, 0, 0]), content="false") // Only stair 0
  inspect(staircase_nim_wins([0, 5, 0]), content="true")  // Stair 1 = 5
  inspect(staircase_nim_wins([0, 3, 0, 3]), content="false") // 3 XOR 3 = 0
  inspect(staircase_nim_wins([0, 3, 0, 4]), content="true") // 3 XOR 4 = 7
}

///|
test "game compute grundy" {
  // Simple DAG: 0 -> 1 -> 2, 0 -> 2
  let game = Game::new(3)
  game.add_move(0, 1)
  game.add_move(0, 2)
  game.add_move(1, 2)
  // 2 has no moves: G(2) = 0
  // 1 can reach 2: G(1) = mex{0} = 1
  // 0 can reach 1, 2: G(0) = mex{0, 1} = 2

  game.compute_all_grundy()
  inspect(game.states[2].grundy, content="0")
  inspect(game.states[1].grundy, content="1")
  inspect(game.states[0].grundy, content="2")
}

///|
test "kayles" {
  let memo : Map[Int, Int] = {}

  // Known Grundy sequence for Kayles
  // G(0) = 0, G(1) = 1, G(2) = 2, G(3) = 3, G(4) = 1, G(5) = 4, ...
  inspect(kayles_grundy(0, memo), content="0")
  inspect(kayles_grundy(1, memo), content="1")
  inspect(kayles_grundy(2, memo), content="2")
  inspect(kayles_grundy(3, memo), content="3")
  inspect(kayles_grundy(4, memo), content="1")
}
