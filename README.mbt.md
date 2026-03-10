# FlyCloudC/symbol

A unique symbolic identifier providing O(1) equality, comparison, and hashing.

## Features

- `Symbol::of` creates symbols from strings 
- `Symbol::generate` creates unique new symbols
- `Symbol::to_string` returns the original string

## Example

```mbt check
///|
test {
  let names = ["a1", "a2", "", "中", "long name"]
  let symbols = names.map(Symbol::of)
  assert_eq(symbols.map(Symbol::to_string), names)

  symbols.push(Symbol::generate())
  symbols.push(Symbol::generate())

  let eq_sym = []
  for s1 in symbols {
    for s2 in symbols {
      if s1 == s2 {
        assert_eq(s1.hash(), s1.hash())
        eq_sym.push(s1)
      }
    }
  }
  inspect(
    eq_sym,
    content=(
      #|[a1, a2, , 中, long name, #{gensym 0}, #{gensym 1}]
    ),
  )
}
```