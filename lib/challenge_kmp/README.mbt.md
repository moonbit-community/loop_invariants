# Challenge: KMP String Matching

Compute prefix function and search for all pattern occurrences in linear time.

## Example

```mbt check
///|
test "kmp example" {
  let matches = @challenge_kmp.kmp_search("ababcababa"[:], "aba"[:])
  inspect(matches, content="[0, 5, 7]")
}
```
