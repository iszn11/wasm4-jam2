# wasm4-jam2

A game written in Zig for the [WASM-4](https://wasm4.org) fantasy console.

## Building

Build the cart by running:

```shell
zig build -Drelease-small
```

Then run it with:

```shell
w4 run zig-out/lib/cart.wasm
```
