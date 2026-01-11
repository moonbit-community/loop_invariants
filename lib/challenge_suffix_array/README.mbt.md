# Challenge: Suffix Array + LCP

Suffix array via prefix doubling, plus LCP via Kasai.

## Example

```mbt check
///|
test "suffix array example" {
  let sa = @challenge_suffix_array.suffix_array("banana"[:])
  let lcp = @challenge_suffix_array.lcp_array("banana"[:], sa[:])
  inspect(sa, content="[5, 3, 1, 0, 4, 2]")
  inspect(lcp, content="[0, 1, 3, 0, 0, 2]")
}
```
