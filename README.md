
# wasm-minimal-protocol for :crown:

A minimal protocol to write [typst plugins](https://typst.app/docs/reference/foundations/plugin/).

## You want to write a plugin
[Nim]: https://nim-lang.org/

> For other languages like Rust, ref <https://github.com/astrale-sharp/wasm-minimal-protocol> 

[Nim][] plugins can use this repo to automatically implement the protocol with a macro:

```Nim
# Nim file
# /path/to/plugin.nim
import pkg/wasm_minmal_protocol
proc hello(): string{.export_typst_bytes.} =
  "hello from Nim"

import std/math
proc cbrt(x: float): float{.export_typst.} = math.cbrt(x)
```

compile using the binary this package provide, `nim-typst-plugin` (available if install via `nimble install`,
or after `nimble build`, it'll be in `./bin/` directory)


```shell
nim-typst-plugin /path/to/plugin.nim
```

> Note this reply on your [Nim][] installation and `wasi-stub` (see below)

Then write:

```typst
// Typst file
#let p = plugin("/path/to/plugin.wasm")
#let _ = p.wasm_minimal_protocol_NimMain()  // current needed

#assert(str(p.hello()) == "hello from Nim")
// use cbor for non-bytes argument
#assert(2.0 == cbor(p.cbrt(cbor.encode(8.0))))
```

ref <https://typst.app/docs/reference/foundations/plugin/> for details.
You should also take a look at this repository's [examples](./tests/).

## wasi-stub

The runtime used by typst do not allow the plugin to import any function (beside the ones used by the protocol). In particular, if your plugin is compiled for WASI, it will not be able to be loaded by typst.

To get around that, you can use wasi-stub. It will detect all WASI-related imports, and replace them by stubs that do nothing.

Install it from <https://github.com/astrale-sharp/wasm-minimal-protocol>

