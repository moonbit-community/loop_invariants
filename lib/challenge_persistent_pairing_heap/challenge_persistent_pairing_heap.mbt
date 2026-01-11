// ============================================================================
// Challenge: Persistent Pairing Heap
// Pairwise merging of subheaps after delete-min
// ============================================================================

///|
enum ChildList {
  Nil
  Cons(head~ : Heap, tail~ : ChildList)
} derive(Show)

///|
pub enum Heap {
  Empty
  Node(value~ : Int, children~ : ChildList)
} derive(Show)

///|
fn heap_size(h : Heap) -> Int {
  match h {
    Heap::Empty => 0
    Heap::Node(value=_, children~) => 1 + children_size(children)
  }
}

///|
fn children_size(children : ChildList) -> Int {
  match children {
    ChildList::Nil => 0
    ChildList::Cons(head~, tail~) => heap_size(head) + children_size(tail)
  }
}

///|
fn heap_valid(h : Heap) -> Bool {
  match h {
    Heap::Empty => true
    Heap::Node(value~, children~) => children_valid(value, children)
  }
}

///|
fn children_valid(parent : Int, children : ChildList) -> Bool {
  match children {
    ChildList::Nil => true
    ChildList::Cons(head~, tail~) => {
      let head_ok = match head {
        Heap::Empty => false
        Heap::Node(value=v, children=_) => parent <= v && heap_valid(head)
      }
      head_ok && children_valid(parent, tail)
    }
  }
}

///|
pub fn empty() -> Heap {
  Heap::Empty
}

///|
pub fn size(h : Heap) -> Int {
  heap_size(h)
}

///|
pub fn merge(a : Heap, b : Heap) -> Heap {
  match (a, b) {
    (Heap::Empty, _) => b
    (_, Heap::Empty) => a
    (Heap::Node(value=va, children=ca), Heap::Node(value=vb, children=cb)) =>
      if va <= vb {
        Heap::Node(value=va, children=ChildList::Cons(head=b, tail=ca))
      } else {
        Heap::Node(value=vb, children=ChildList::Cons(head=a, tail=cb))
      }
  }
}

///|
fn singleton(value : Int) -> Heap {
  Heap::Node(value~, children=ChildList::Nil)
}

///|
pub fn insert(h : Heap, value : Int) -> Heap {
  merge(h, singleton(value))
}

///|
pub fn find_min(h : Heap) -> Int? {
  match h {
    Heap::Empty => None
    Heap::Node(value~, children=_) => Some(value)
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn merge_pairs(children : ChildList) -> Heap {
  for cur = children, acc = Heap::Empty {
    match cur {
      ChildList::Nil => break acc
      ChildList::Cons(head~, tail~) =>
        match tail {
          ChildList::Nil => break merge(acc, head)
          ChildList::Cons(head=second, tail=rest) => {
            let merged = merge(head, second)
            continue rest, merge(acc, merged)
          }
        }
    }
  } where {
    invariant: heap_valid(acc),
    invariant: heap_size(acc) + children_size(cur) == children_size(children),
    reasoning: (
      #|INVARIANT (Pairwise merge progress):
      #|acc is the merge of processed child pairs; cur holds remaining heaps.
      #|Size is preserved: acc plus remaining children cover the original list.
      #|MAINTENANCE:
      #|Merge the next two children (or one leftover) into acc.
      #|TERMINATION:
      #|When cur is Nil, acc is the full merge of all child heaps.
    ),
  }
}

///|
pub fn delete_min(h : Heap) -> Heap? {
  match h {
    Heap::Empty => None
    Heap::Node(value=_, children~) => Some(merge_pairs(children))
  }
}

///|
test "persistent_pairing_heap" {
  let h0 = Heap::Empty
  let h1 = insert(h0, 8)
  let h2 = insert(h1, 3)
  let h3 = insert(h2, 6)
  assert_eq(find_min(h3), Some(3))
  guard delete_min(h3) is Some(h4) else { fail("expected delete_min") }
  assert_eq(find_min(h4), Some(6))
}
