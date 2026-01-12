# Persistent Li Chao Tree

Line container supporting min queries over a fixed integer domain.

## Example

```mbt check
///|
test "persistent li chao" {
  let lines = [
    @challenge_persistent_li_chao_tree.Line::{ m: 1, b: 0 },
    @challenge_persistent_li_chao_tree.Line::{ m: -1, b: 10 },
    @challenge_persistent_li_chao_tree.Line::{ m: 2, b: -5 },
  ]
  let tree = @challenge_persistent_li_chao_tree.from_array(lines[:], 0, 10)
  inspect(
    @challenge_persistent_li_chao_tree.query(tree, 0, 0, 10),
    content="-5",
  )
  inspect(@challenge_persistent_li_chao_tree.query(tree, 5, 0, 10), content="5")
  inspect(@challenge_persistent_li_chao_tree.query(tree, 9, 0, 10), content="1")
  inspect(@challenge_persistent_li_chao_tree.size(tree), content="3")
}
```

## Another Example

```mbt check
///|
test "persistent li chao insert" {
  let t0 = @challenge_persistent_li_chao_tree.empty()
  let t1 = @challenge_persistent_li_chao_tree.insert(
    t0,
    @challenge_persistent_li_chao_tree.Line::{ m: 1, b: 0 },
    0,
    5,
  )
  let t2 = @challenge_persistent_li_chao_tree.insert(
    t1,
    @challenge_persistent_li_chao_tree.Line::{ m: -1, b: 4 },
    0,
    5,
  )
  let t3 = @challenge_persistent_li_chao_tree.insert(
    t2,
    @challenge_persistent_li_chao_tree.Line::{ m: 0, b: 1 },
    0,
    5,
  )
  inspect(@challenge_persistent_li_chao_tree.query(t2, 2, 0, 5), content="2")
  inspect(@challenge_persistent_li_chao_tree.query(t3, 2, 0, 5), content="1")
}
```
