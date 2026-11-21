# Tony

UCI chess engine in T. The compiler is `t.lua`. It emits native code for macOS and Linux (arm64, x86_64) and Windows (x86_64).

The engine is `tony.t`: bitboards, Chess960, PVS, quiescence, transposition table, Lazy SMP, Syzygy, Polyglot, NNUE.

Estimated strength is above 3400 Elo, but has not been officially measured. 

## Download

- [Windows x86_64 AVX2](https://github.com/cturan/Tony/releases/download/1.0/tony-1.0-windows-x86_64-avx2.exe)
- [Windows x86_64 AVX](https://github.com/cturan/Tony/releases/download/1.0/tony-1.0-windows-x86_64-avx.exe)
- [macOS Apple silicon](https://github.com/cturan/Tony/releases/download/1.0/tony-1.0-macos-arm64-neon)

Other builds are on the [releases page](https://github.com/cturan/Tony/releases).

## Build

Lua 5.4 or newer.

```
lua t.lua tony.t --arch macos --cpu arm64 --instruction neon --gom netv4.tnns --output tony
lua t.lua tony.t --arch linux --cpu x86_64 --instruction avx2 --gom netv4.tnns --output tony
lua t.lua tony.t --arch windows --cpu x86_64 --instruction avx2 --gom netv4.tnns --output tony.exe
```

`--instruction` sets the instruction set. x86_64: `sse2`, `avx`, `avx2`, `avx512`, `avx512bw` (or `auto` for runtime dispatch). arm64: `neon`, `scalar`.


AVX2 Windows build:

```
lua t.lua tony.t --arch windows --cpu x86_64 --instruction avx2 --gom netv4.tnns --output tony.exe
```

All release binaries (macOS, Linux, Windows; `neon`, `sse2`, `avx`, `avx2`, `avx512`, `avx512bw`) go to `release/`:

```
./release.sh
```

## Run

`netv4.tnns` is embedded in the binaries. Another network file can be loaded with:

```
setoption name EvalFile value netv4.tnns
```

Options: `Threads`, `Hash`, `MultiPV`, `Ponder`, `EvalFile`, `SyzygyPath`, `SyzygyProbeDepth`, `Book`, `OwnBook`, `BookDepth`, `UCI_Chess960`, `UCI_ShowWDL`.

## Network

`netv4.tnns` (36 MB). Trained on [cturan/tony_nnue](https://huggingface.co/datasets/cturan/tony_nnue). The whole set was relabeled with `t1-256x10-rl-base-swa-3860000`, a small lc0 net. Most of the self-play games were generated with that same net.

The final training stage also used publicly available [Lc0 data](https://storage.lczero.org/files/): Lc0 training games and positions evaluated with an Lc0 network. That data remains under the Lc0 license terms.

## License

MIT, see [LICENSE](LICENSE).

Syzygy probing is inspired by Ronald de Man's tablebase code.

