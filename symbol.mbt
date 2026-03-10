// Symbol Encoding Layout (32-bit Int)
// [31..28] Tag  [27..0] Payload
//
// 1. Short String (Tag 0-4)
//    length = Tag 
//    Payload = c0 | (c1<<7) | (c2<<14) | (c3<<21)
//
// 2. Long String (Tag > 7)
//    sign bit = 1 (negative integer)
//    index = ~self (non negative integer)
//    name = id_to_name[index]
//
// 3. Generated Symbol (Tag = 5)
//    Payload = global counter
//
// 4. Unuse (Tag = 6, 7)
//
// Decode: value < 0 ? Table : (tag < 5 ? Unpack : Gensym)

///|
/// A unique symbolic identifier providing O(1) equality, comparison, and hashing.
struct Symbol(Int) derive(Eq, Hash, Compare, Default)

///|
fn Symbol::tag(self : Symbol) -> Int {
  (self.0.reinterpret_as_uint() >> 28).reinterpret_as_int()
}

///|
/// Creates a symbol from a string.
pub fn Symbol::of(name : String) -> Symbol {
  let len = name.length()
  if len > 4 {
    put_in_table(name)
  } else {
    let mut acc = 0
    for i in 0..<len {
      let c = name.unsafe_get(i)
      guard c is (_..<0x7f) else { return put_in_table(name) }
      acc = (c.to_int() << (7 * i)) | acc
    }
    Symbol((len << (7 * 4)) | acc)
  }
}

///|
let name_to_sym : @hashmap.HashMap[String, Symbol] = @hashmap.new(capacity=64)

///|
let id_to_name : Array[String] = Array::new(capacity=64)

///|
fn put_in_table(name : String) -> Symbol {
  name_to_sym.get_or_init(name, () => {
    let id = id_to_name.length()
    id_to_name.push(name)
    Symbol(id.lnot())
  })
}

///|
/// Global counter incremented to produce unique IDs for generated symbols.
pub let gen_counter : Ref[Int] = { val: -1 }

///|
/// Generates a unique symbolic identifier using a global counter.
pub fn Symbol::generate() -> Symbol {
  gen_counter.val += 1
  let id = gen_counter.val
  guard id < 0x0fff_ffff
  Symbol((5 << (7 * 4)) | gen_counter.val)
}

///|
/// if this symbol was created via `generate()` rather than from a string.
pub fn Symbol::is_generated(self : Symbol) -> Bool {
  self.tag() == 5
}

///|
pub impl Show for Symbol with output(self, logger) {
  if self.0 < 0 {
    logger.write_string(id_to_name[self.0.lnot()])
  } else {
    match self.tag() {
      _..<5 as len => {
        let mut acc = self.0
        for i in 0..<len {
          logger.write_char((acc & 0x7f).unsafe_to_char())
          acc = acc >> 7
        }
      }
      x => {
        guard x is 5
        logger.write_string("#{gensym \{self.0 & 0x0fff_ffff}}")
      }
    }
  }
}

///|
test "inner" {
  let names : Array[String] = [
    "", "a", "ab", "abc", "abcd", "abcde", "abcdef", "中",
  ]
  let ss = names.map(Symbol::of) + [Symbol::generate(), Symbol::generate()]
  inspect(
    ss.map(x => x.0.to_string(radix=16)),
    content=(
      #|["0", "10000061", "20003161", "3018f161", "4c98f161", "-1", "-2", "-3", "50000000", "50000001"]
    ),
  )
}
