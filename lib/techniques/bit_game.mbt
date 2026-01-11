///|
/// Bit Manipulation and Game Theory Examples
///
/// This file demonstrates algorithms that leverage bit manipulation
/// for efficiency, along with game theory algorithms like Nim and
/// Sprague-Grundy theorem applications.

///|
/// Count Set Bits (Brian Kernighan's Algorithm)
///
/// MATHEMATICAL INSIGHT:
/// n & (n-1) clears the lowest set bit.
/// Each iteration removes exactly one set bit.
///
/// INVARIANT: After k iterations, k bits have been counted and cleared.
fn count_set_bits(n : Int) -> Int {
  for num = n, count = 0; num > 0; {
    continue num & (num - 1), count + 1
  } else {
    count
  } where {
    invariant: num >= 0 && count >= 0,
    reasoning: (
      #|LOOP INVARIANT: count = number of set bits cleared so far
      #|
      #|KEY INSIGHT: n & (n-1) removes the lowest set bit
      #|Example: 1100 & 1011 = 1000
      #|
      #|Each iteration clears exactly one bit, so loop runs O(set bits) times.
    ),
  }
}

///|
test "count set bits" {
  assert_eq(count_set_bits(0), 0)
  assert_eq(count_set_bits(1), 1)
  assert_eq(count_set_bits(7), 3) // 111
  assert_eq(count_set_bits(255), 8) // 11111111
}

///|
/// Check if Power of 2
///
/// INSIGHT: A power of 2 has exactly one set bit: 2^k = 100...0
/// So n & (n-1) = 0 for powers of 2.
fn is_power_of_two(n : Int) -> Bool {
  n > 0 && (n & (n - 1)) == 0
}

///|
test "power of two" {
  assert_eq(is_power_of_two(1), true) // 2^0
  assert_eq(is_power_of_two(2), true) // 2^1
  assert_eq(is_power_of_two(3), false)
  assert_eq(is_power_of_two(16), true) // 2^4
  assert_eq(is_power_of_two(0), false)
}

///|
/// Single Number - XOR to find unique element
///
/// MATHEMATICAL FOUNDATION:
/// XOR properties: a ^ a = 0, a ^ 0 = a, associative & commutative
/// If all elements appear twice except one, XOR of all = unique element.
fn single_number(nums : ArrayView[Int]) -> Int {
  for i = 0, result = 0; i < nums.length(); i = i + 1 {
    continue i + 1, result ^ nums[i]
  } else {
    result
  } where {
    invariant: i >= 0 && i <= nums.length(),
    reasoning: (
      #|LOOP INVARIANT: result = XOR of nums[0..i)
      #|
      #|Since a ^ a = 0 and XOR is commutative/associative,
      #|pairs cancel out, leaving only the unique element.
    ),
  }
}

///|
test "single number" {
  let nums = [2, 2, 1]
  assert_eq(single_number(nums[:]), 1)
  let nums2 = [4, 1, 2, 1, 2]
  assert_eq(single_number(nums2[:]), 4)
}

///|
/// Missing Number - XOR with indices
///
/// If array contains [0, n] with one missing, XOR all values and indices.
fn missing_number(nums : ArrayView[Int]) -> Int {
  let n = nums.length()
  for i = 0, result = n; i < n; i = i + 1 {
    continue i + 1, result ^ i ^ nums[i]
  } else {
    result
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|LOOP INVARIANT: result = n ^ XOR of [0..i) ^ XOR of nums[0..i)
      #|
      #|Initialize with n (since indices are 0 to n-1).
      #|After full loop: result = XOR of {0..n} ^ XOR of nums.
      #|The missing number doesn't cancel, so it remains.
    ),
  }
}

///|
test "missing number" {
  let nums = [3, 0, 1]
  assert_eq(missing_number(nums[:]), 2)
  let nums2 = [0, 1]
  assert_eq(missing_number(nums2[:]), 2)
  let nums3 = [9, 6, 4, 2, 3, 5, 7, 0, 1]
  assert_eq(missing_number(nums3[:]), 8)
}

///|
/// Reverse Bits
///
/// Reverse the 32 bits of an unsigned integer.
fn reverse_bits(n : Int) -> Int {
  for i = 0, result = 0, num = n; i < 32; i = i + 1 {
    let bit = num & 1
    let new_result = (result << 1) | bit
    continue i + 1, new_result, num >> 1
  } else {
    result
  } where {
    invariant: i >= 0 && i <= 32,
    reasoning: (
      #|LOOP INVARIANT: result contains reversed bits of lowest i bits of original n
      #|
      #|Each iteration:
      #|  1. Extract lowest bit of num
      #|  2. Shift result left and add bit
      #|  3. Shift num right to process next bit
      #|
      #|After 32 iterations, all bits are reversed.
    ),
  }
}

///|
test "reverse bits" {
  // 0b00000010100101000001111010011100 = 43261596
  // reversed = 0b00111001011110000010100101000000 = 964176192
  assert_eq(reverse_bits(43261596), 964176192)
}

///|
/// Hamming Distance - Count differing bits
fn hamming_distance(x : Int, y : Int) -> Int {
  count_set_bits(x ^ y)
}

///|
test "hamming distance" {
  assert_eq(hamming_distance(1, 4), 2) // 001 vs 100
}

///|
/// Subsets using Bit Manipulation
///
/// INSIGHT: For n elements, there are 2^n subsets.
/// Each subset corresponds to a bitmask from 0 to 2^n - 1.
fn generate_subsets(elements : ArrayView[Int]) -> Array[Array[Int]] {
  let n = elements.length()
  let total = 1 << n // 2^n
  let result : Array[Array[Int]] = []
  for mask = 0; mask < total; mask = mask + 1 {
    let subset : Array[Int] = []
    for i in 0..<n {
      if ((mask >> i) & 1) == 1 {
        subset.push(elements[i])
      }
    }
    result.push(subset)
  } where {
    invariant: mask >= 0 && mask <= total,
    reasoning: (
      #|LOOP INVARIANT: result contains all subsets for masks 0 to mask-1
      #|
      #|Each bit position i in mask indicates whether elements[i] is in subset.
      #|This generates all 2^n possible combinations.
    ),
  }
  result
}

///|
test "generate subsets" {
  let elements = [1, 2, 3]
  let subsets = generate_subsets(elements[:])
  assert_eq(subsets.length(), 8) // 2^3 = 8
}

///|
/// Gray Code - Generate n-bit Gray code sequence
///
/// MATHEMATICAL FOUNDATION:
/// Gray code for i is: i ^ (i >> 1)
/// Adjacent codes differ by exactly one bit.
fn gray_code(n : Int) -> Array[Int] {
  let total = 1 << n
  let result : Array[Int] = []
  for i = 0; i < total; i = i + 1 {
    result.push(i ^ (i >> 1))
  } where {
    invariant: i >= 0 && i <= total,
    reasoning: (
      #|LOOP INVARIANT: result[0..i) contains Gray codes for 0 to i-1
      #|
      #|Gray code formula: G(i) = i XOR (i >> 1)
      #|This ensures G(i) and G(i+1) differ by exactly one bit.
      #|
      #|Proof: Consider i and i+1. The lowest differing bit at position k
      #|causes exactly one bit change in the XOR result.
    ),
  }
  result
}

///|
test "gray code" {
  let codes = gray_code(3)
  assert_eq(codes.length(), 8)
  // Verify adjacent codes differ by one bit
  for i in 0..<7 {
    assert_eq(count_set_bits(codes[i] ^ codes[i + 1]), 1)
  }
}

///|
/// Game of Nim - Determine winner
///
/// MATHEMATICAL FOUNDATION (Bouton's Theorem):
/// A position is losing (for the player to move) iff XOR of all pile sizes = 0.
/// This is because the player moving from a zero-XOR position always creates
/// a non-zero XOR position, and vice versa.
fn nim_winner(piles : ArrayView[Int]) -> String {
  let xor_sum = nim_xor(piles)
  if xor_sum == 0 {
    "Second"
  } else {
    "First"
  }
}

///|
fn nim_xor(piles : ArrayView[Int]) -> Int {
  for i = 0, result = 0; i < piles.length(); i = i + 1 {
    continue i + 1, result ^ piles[i]
  } else {
    result
  } where {
    invariant: i >= 0 && i <= piles.length(),
    reasoning: (
      #|LOOP INVARIANT: result = XOR of piles[0..i)
      #|
      #|BOUTON'S THEOREM:
      #|  - If XOR = 0: Current player loses (with perfect play)
      #|  - If XOR != 0: Current player wins (can always move to XOR = 0)
      #|
      #|BASE CASE: Empty game (all piles = 0) has XOR = 0, player to move loses.
      #|STRATEGY: From XOR != 0, find a pile p where p XOR result has high bit < p.
      #|         Reduce that pile to p XOR result, making new XOR = 0.
    ),
  }
}

///|
test "nim winner" {
  assert_eq(nim_winner([1, 2, 3][:]), "Second") // XOR = 0
  assert_eq(nim_winner([1, 2, 4][:]), "First") // XOR = 7
  assert_eq(nim_winner([3, 3][:]), "Second") // XOR = 0
}

///|
/// Nim with Move - Find winning move
///
/// Returns (pile_index, amount_to_remove) or None if losing position.
fn nim_winning_move(piles : ArrayView[Int]) -> (Int, Int)? {
  let xor_sum = nim_xor(piles)
  if xor_sum == 0 {
    return None // Losing position
  }

  // Find a pile where pile XOR xor_sum < pile
  for i = 0; i < piles.length(); i = i + 1 {
    let target = piles[i] ^ xor_sum
    if target < piles[i] {
      return Some((i, piles[i] - target))
    }
  } where {
    invariant: i >= 0 && i <= piles.length(),
    reasoning: (
      #|Find pile where XOR reduces the pile size.
      #|Such a pile always exists when xor_sum != 0 because the highest
      #|bit of xor_sum must appear in some pile.
    ),
  }
  None
}

///|
test "nim winning move" {
  let result = nim_winning_move([1, 2, 4][:])
  assert_true(result is Some(_))
}

///|
/// Sprague-Grundy Number for a Simple Game
///
/// Game: Starting with n stones, can remove 1, 2, or 3 stones. Last to move wins.
///
/// SPRAGUE-GRUNDY THEOREM:
/// sg(n) = mex({sg(n-1), sg(n-2), sg(n-3)}) where mex = minimum excludant
fn sprague_grundy_simple(n : Int) -> Int {
  if n == 0 {
    return 0 // Losing position (can't move)
  }
  let sg = Array::make(n + 1, 0)
  for i = 1; i <= n; i = i + 1 {
    // Collect SG values of positions reachable in one move
    let reachable : Array[Int] = []
    if i >= 1 {
      reachable.push(sg[i - 1])
    }
    if i >= 2 {
      reachable.push(sg[i - 2])
    }
    if i >= 3 {
      reachable.push(sg[i - 3])
    }
    sg[i] = mex(reachable[:])
  } where {
    invariant: i >= 1 && i <= n + 1,
    reasoning: (
      #|LOOP INVARIANT: sg[0..i) contains correct Sprague-Grundy numbers
      #|
      #|SPRAGUE-GRUNDY THEOREM:
      #|  sg(position) = mex({sg(p') : p' reachable from position})
      #|
      #|A position is losing iff sg = 0.
      #|
      #|For this game (remove 1-3 stones):
      #|  sg(0) = 0 (no moves)
      #|  sg(1) = mex({0}) = 1
      #|  sg(2) = mex({0,1}) = 2
      #|  sg(3) = mex({0,1,2}) = 3
      #|  sg(4) = mex({1,2,3}) = 0
      #|  Pattern: sg(n) = n mod 4
      #|MAINTENANCE:
      #|Compute reachable SG values for position i, then set sg[i] = mex of
      #|those values, extending the prefix by one.
      #|TERMINATION:
      #|At i == n + 1, sg[0..n] is computed; return sg[n].
    ),
  }
  sg[n]
}

///|
fn mex(values : ArrayView[Int]) -> Int {
  // Find minimum excludant (smallest non-negative integer not in values)
  let present = Array::make(values.length() + 1, false)
  for i in 0..<values.length() {
    if values[i] < present.length() {
      present[values[i]] = true
    }
  }
  for i = 0; i < present.length(); i = i + 1 {
    if not(present[i]) {
      return i
    }
  } else {
    present.length()
  } where {
    invariant: i >= 0 && i <= present.length(),
    reasoning: (
      #|INVARIANT (mex):
      #|All indices in [0..i) have been checked; if present[j] is false, we
      #|would have already returned that j as the mex.
      #|MAINTENANCE:
      #|If present[i] is true, advance; otherwise return i immediately.
      #|TERMINATION:
      #|If no false entry exists, mex is present.length().
    ),
  }
}

///|
test "sprague grundy simple" {
  // Pattern: sg(n) = n mod 4
  assert_eq(sprague_grundy_simple(0), 0)
  assert_eq(sprague_grundy_simple(1), 1)
  assert_eq(sprague_grundy_simple(4), 0)
  assert_eq(sprague_grundy_simple(5), 1)
}

///|
/// Combinatorial Game - XOR of Multiple Games
///
/// SPRAGUE-GRUNDY THEOREM FOR SUM OF GAMES:
/// sg(G1 + G2 + ... + Gk) = sg(G1) XOR sg(G2) XOR ... XOR sg(Gk)
///
/// This allows solving complex games by computing SG for each independent part.
fn combined_game_winner(sg_values : ArrayView[Int]) -> String {
  let xor_sum = nim_xor(sg_values)
  if xor_sum == 0 {
    "Second"
  } else {
    "First"
  }
}

///|
test "combined game" {
  // Game 1: 3 stones (sg=3), Game 2: 5 stones (sg=1), Game 3: 4 stones (sg=0)
  let sg_values = [3, 1, 0]
  // XOR = 3 ^ 1 ^ 0 = 2 != 0, so First wins
  assert_eq(combined_game_winner(sg_values[:]), "First")
}

///|
/// Maximum XOR of Two Numbers in Array
///
/// Uses trie-based approach for O(n * 32) time.
/// INSIGHT: To maximize XOR, we want opposite bits at each position,
/// starting from the most significant bit.
fn maximum_xor_pair(nums : ArrayView[Int]) -> Int {
  let n = nums.length()
  if n < 2 {
    return 0
  }

  // Build a simple set of all numbers for lookup
  // (In production, use a trie for efficiency)
  let mut max_xor = 0
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      let xor_val = nums[i] ^ nums[j]
      if xor_val > max_xor {
        max_xor = xor_val
      }
    } where {
      invariant: j >= i + 1 && j <= n,
      reasoning: (
        #|INVARIANT (max xor inner):
        #|max_xor is the maximum XOR among pairs (i, k) for k in [i+1, j).
        #|MAINTENANCE:
        #|Compare nums[i] with nums[j] and update max_xor, then advance j.
        #|TERMINATION:
        #|At j == n, all pairs starting at i have been considered.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (max xor outer):
      #|max_xor is the maximum XOR among all pairs with first index < i.
      #|MAINTENANCE:
      #|The inner loop updates max_xor for pairs starting at i, extending the
      #|range of covered pairs.
      #|TERMINATION:
      #|At i == n, all pairs have been considered; max_xor is global.
    ),
  }
  max_xor
}

///|
test "maximum xor pair" {
  let nums = [3, 10, 5, 25, 2, 8]
  assert_eq(maximum_xor_pair(nums[:]), 28) // 25 ^ 5 = 28
}

///|
/// Divide Two Integers using Bit Manipulation
///
/// Without using multiplication, division, or mod operators.
fn divide_bit(dividend : Int, divisor : Int) -> Int {
  if divisor == 0 {
    return 2147483647 // Overflow
  }
  if dividend == 0 {
    return 0
  }
  let negative = (dividend < 0) != (divisor < 0)
  let mut dvd = if dividend < 0 { 0 - dividend } else { dividend }
  let dvs = if divisor < 0 { 0 - divisor } else { divisor }
  let mut quotient = 0
  for ; dvd >= dvs; {
    // Find the largest multiple of divisor that fits
    let mut temp = dvs
    let mut multiple = 1
    for ; temp << 1 <= dvd && temp << 1 > 0; {
      temp = temp << 1
      multiple = multiple << 1
    } where {
      invariant: multiple >= 1 && temp >= dvs,
      reasoning: (
        #|INVARIANT (doubling step):
        #|temp == dvs * multiple and temp <= dvd; multiple is a power of two.
        #|MAINTENANCE:
        #|Double temp and multiple while the next double still fits in dvd.
        #|TERMINATION:
        #|When the loop ends, temp is the largest power-of-two multiple <= dvd.
      ),
    }
    dvd = dvd - temp
    quotient = quotient + multiple
  } else {
    if negative {
      0 - quotient
    } else {
      quotient
    }
  } where {
    invariant: dvd >= 0,
    reasoning: (
      #|INVARIANT (division):
      #|quotient * dvs + dvd equals the absolute original dividend.
      #|MAINTENANCE:
      #|Subtract the largest power-of-two multiple temp from dvd and add the
      #|corresponding multiple to quotient.
      #|TERMINATION:
      #|When dvd < dvs, quotient is the final integer division result.
    ),
  }
}

///|
test "divide bit" {
  assert_eq(divide_bit(10, 3), 3)
  assert_eq(divide_bit(7, -3), -2)
}

///|
/// Lowest Set Bit
fn lowest_set_bit(n : Int) -> Int {
  n & -n
}

///|
test "lowest set bit" {
  assert_eq(lowest_set_bit(12), 4) // 1100 -> lowest is 100 = 4
  assert_eq(lowest_set_bit(10), 2) // 1010 -> lowest is 10 = 2
}

///|
/// Next Higher Number with Same Number of Set Bits
///
/// Useful for enumerating combinations in lexicographic order.
fn next_with_same_bits(n : Int) -> Int {
  let c = n & -n // Lowest set bit
  let r = n + c // Add to propagate carry
  // ((r XOR n) >> 2) / c gives the trailing bits to add
  let trailing = ((r ^ n) >> 2) / c
  r | trailing
}

///|
test "next with same bits" {
  // 0b0111 (7) -> 0b1011 (11) -> 0b1101 (13) -> 0b1110 (14)
  assert_eq(next_with_same_bits(7), 11)
  assert_eq(next_with_same_bits(11), 13)
  assert_eq(next_with_same_bits(13), 14)
}
