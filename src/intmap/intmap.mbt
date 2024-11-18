// DATE: 2024/11/12 
// create by: myfreess@github.com
// Big-endian Patricia Tree

typealias Key = Int

typealias Prefix = Int

typealias Mask = UInt // Mask must be 2 ^ n

enum IntMap[T] {
  Empty
  Leaf(key~ : Key, value~ : T)
  Branch(prefix~ : Prefix, mask~ : Mask, left~ : IntMap[T], right~ : IntMap[T])
} derive(Show)

fn to_hex_string_(n : UInt) -> String {
  let mut n = n
  let buf = @buffer.new(size_hint=8)
  for i = 0; i < 8; i = i + 1 {
    let r = n & 0x0000000F
    let r = match r {
      0 => '0'
      1 => '1'
      2 => '2'
      3 => '3'
      4 => '4'
      5 => '5'
      6 => '6'
      7 => '7'
      8 => '8'
      9 => '9'
      10 => 'A'
      11 => 'B'
      12 => 'C'
      13 => 'D'
      14 => 'E'
      15 => 'F'
      _ => abort("to_hex_string: n = \{n} r=\{r}")
    }
    buf.write_char(r)
    n = n >> 4
  } else {
    buf.to_unchecked_string().rev()
  }
}

fn to_hex_string(n : Int) -> String {
  to_hex_string_(n.reinterpret_as_uint())
}

test "int to hex string" {
  inspect!(to_hex_string(0), content="00000000")
  inspect!(to_hex_string(1), content="00000001")
  inspect!(to_hex_string(16), content="00000010")
  inspect!(to_hex_string(@int.max_value), content="7FFFFFFF")
  inspect!(to_hex_string(@int.min_value), content="80000000")
  inspect!(to_hex_string(-2), content="FFFFFFFE")
  inspect!(to_hex_string(-1), content="FFFFFFFF")
  inspect!(to_hex_string(1 << 16), content="00010000")
}

test "unsigned int to hex string" {
  inspect!(to_hex_string_(1U), content="00000001")
}

fn zero(k : Key, m : Mask) -> Bool {
  let k = k.reinterpret_as_uint()
  (k & m) == 0
}

fn get_prefix_(k : UInt, m : UInt) -> Prefix {
  k.lor(m - 1).land(m.lnot()).reinterpret_as_int()
}

test "generate prefix" {
  inspect!(to_hex_string(get_prefix_(0x00010000, 1U << 16)), content="0000FFFF")
  inspect!(to_hex_string(get_prefix_(0x00100000, 1U << 20)), content="000FFFFF")
}

fn get_prefix(k : Key, m : Mask) -> Prefix {
  get_prefix_(k.reinterpret_as_uint(), m)
}

fn match_prefix(key~ : Key, prefix~ : Prefix, mask~ : Mask) -> Bool {
  get_prefix(key, mask) == prefix
}

fn gen_mask_(p1 : UInt, p2 : UInt) -> Mask {
  let unsigned_int_width = 32
  1U << (unsigned_int_width - 1 - p1.lxor(p2).clz())
}

test "mask generation" {
  inspect!(
    to_hex_string_(gen_mask_(0x40401111, 0x40400000)),
    content="00001000",
  )
}

fn gen_mask(p1 : Prefix, p2 : Prefix) -> Mask {
  let p1 = p1.reinterpret_as_uint()
  let p2 = p2.reinterpret_as_uint()
  gen_mask_(p1, p2)
}

fn join[T](
  p1 : Prefix,
  t1 : IntMap[T],
  p2 : Prefix,
  t2 : IntMap[T]
) -> IntMap[T] {
  let mask = gen_mask(p1, p2)
  if zero(p1, mask) {
    Branch(prefix=get_prefix(p1, mask), mask~, left=t1, right=t2)
  } else {
    Branch(prefix=get_prefix(p1, mask), mask~, left=t2, right=t1)
  }
}

fn insert[T](self : IntMap[T], key : Key, value : T) -> IntMap[T] {
  match self {
    Empty => Leaf(key~, value~)
    Leaf(..) as leaf =>
      if leaf.key == key {
        Leaf(key~, value~)
      } else {
        join(key, Leaf(key~, value~), leaf.key, leaf)
      }
    Branch(..) as br_node =>
      if match_prefix(key~, prefix=br_node.prefix, mask=br_node.mask) {
        if zero(key, br_node.mask) {
          Branch(
            prefix=br_node.prefix,
            mask=br_node.mask,
            left=insert(br_node.left, key, value),
            right=br_node.right,
          )
        } else {
          Branch(
            prefix=br_node.prefix,
            mask=br_node.mask,
            left=br_node.left,
            right=insert(br_node.right, key, value),
          )
        }
      } else {
        join(key, Leaf(key~, value~), br_node.prefix, br_node)
      }
  }
}

fn get_opt[T](self : IntMap[T], k : Key) -> T? {
  match self {
    Empty => None
    Leaf(..) as leaf => if leaf.key == k { Some(leaf.value) } else { None }
    Branch(..) as br_node =>
      if k <= br_node.prefix {
        get_opt(br_node.left, k)
      } else {
        get_opt(br_node.right, k)
      }
  }
}

fn op_get[T](self : IntMap[T], key : Key) -> T {
  self.get_opt(key).unwrap()
}

test "intmap insert and lookup" {
  let mut foo = IntMap::Empty
  let lower_bound = @int.max_value / 200
  let upper_bound = @int.max_value / 100
  for i = lower_bound; i <= upper_bound; i = i + 1 {
    foo = foo.insert(i, i)
    assert_eq!(foo[i], i)
  }
  for i = lower_bound; i <= upper_bound; i = i + 1 {
    assert_eq!(foo[i], i)
  }
}

fn merge[T](combine~ : (T, T) -> T, l : IntMap[T], r : IntMap[T]) -> IntMap[T] {
  ...
}

fn IntMap::from_array[T](arr : Array[T]) -> IntMap[T] {
  panic()
}
