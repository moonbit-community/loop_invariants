# Challenge: Manacher's Algorithm

Compute the longest palindromic substring length in linear time.

## Example

```mbt check
///|
test "manacher example" {
  let len = @challenge_manacher.longest_palindrome_len("abacaba"[:])
  inspect(len, content="7")
}
```
