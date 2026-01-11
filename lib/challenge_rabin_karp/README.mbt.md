# Challenge: Rabin-Karp String Matching

Rolling hash search with collision checks.

## Example

```mbt check
///|
test "rabin-karp example" {
  let matches = @challenge_rabin_karp.rabin_karp_search(
    "abracadabra"[:],
    "abra"[:],
  )
  inspect(matches, content="[0, 7]")
}
```
