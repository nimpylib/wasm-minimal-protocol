
# wasm-minimal-protocol for <img alt="Nim" width="23%" src="https://nim-lang.org/assets/img/logo.svg"></img>
[![CI (Typst Compile)](https://github.com/nimpylib/wasm-minimal-protocol/actions/workflows/ci.yml/badge.svg)](https://github.com/nimpylib/wasm-minimal-protocol/actions/workflows/ci.yml)
[![nim-api-docs](https://github.com/nimpylib/wasm-minimal-protocol/actions/workflows/nim-api-docs.yml/badge.svg)][docs]

[docs]: https://wasm-minimal-potocol.nimpylib.org

A _no-longer-minimal_ protocol to write [typst plugins](https://typst.app/docs/reference/foundations/plugin/), featured with:

- auto bi-convert between typst and Nim **types** like float, string and tables
- support default arguments and `varargs`
- ability to export **existing** function to typst, via [`export_typst_from`](https://wasm-minimal-protocol.nimpylib.org/wasm_minimal_protocol/export_typst.html#export_typst_from.m%2Cproc%2Cstatic%5Bstring%5D)
- reserving **doc** from Nim to typst, means no need to write document twice (turn off via compile flag [`-d:exportNimDocToTypst=off`](https://wasm-minimal-protocol.nimpylib.org/wasm_minimal_protocol/export_typst.html#exportNimDocToTypst))
- alternative **cbor engine** to choose, via [`-d:cborious`](https://github.com/elcritch/cborious) [^cborious]
- Fine-grained control over exported **name**, serialization & deserialization (ref [datetime-parse example](https://github.com/nimpylib/wasm-minimal-protocol/blob/master/tests/t_parse_datetime_lib.nim))

[^cborious]: requires manually installation like `nimble install cborious`

## You want to write a plugin
[Nim]: https://nim-lang.org/

> For other languages like Rust, ref <https://github.com/astrale-sharp/wasm-minimal-protocol>, which is however really `minimal` (lacks features above).

[Nim][] plugins can use this repo to automatically implement the protocol with a macro:

```Nim
# Nim file
# /path/to/plugin.nim
import pkg/wasm_minmal_protocol

import std/[math, strutils]
func cbrt(x: float): float{.export_typst.} = math.cbrt(x)
func format(fmt: string, args: varargs[string]): string{.
  export_typst_as: "str-format".} = fmt % args

export_typst_from fac, "factorial"
# or `export_typst_from fac` to export as `fac`
```

compile using the binary this package provide, `nim-typst-plugin` (available if install via `nimble install`,
or after `nimble build`, it'll be in `./bin/` directory)


```shell
nim-typst-plugin -d:gen_typst /path/to/plugin.nim
```

> Note this reply on your [Nim][] installation and [`wasi-stub`][wasi-stub] (see below)

> `-d:gen_typst` to also generate .typ file for handy use, other than bare `.wasm`

Then write:

```typst
// Typst file
#import "/path/to/plugin.typ": *
// no need to call cbor
#assert(2.0 == cbrt(8.0))
#str-format("$1 $2 was somehow translated literally", "violet", "evergarden")
#str-format("$# and $# refer to each", "spice", "wolf")
#factorial(3)
```

You should also take a look at this repository's [examples](./tests/).

## wasi-stub

The runtime used by typst do not allow the plugin to import any function (beside the ones used by the protocol). In particular, if your plugin is compiled for WASI, it will not be able to be loaded by typst.

To get around that, you can use wasi-stub. It will detect all WASI-related imports, and replace them by stubs that do nothing.

Install it from [wasi-stub repo][wasi-stub],
either via cargo or `Github Release`

[wasi-stub]: https://github.com/astrale-sharp/wasm-minimal-protocol