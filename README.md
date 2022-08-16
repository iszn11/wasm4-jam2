# wasm4-jam2

A game written in Zig for the [WASM-4](https://wasm4.org) fantasy console.

## Building

Build and run the cart:

```shell
zig build -Drelease-small && w4 run --no-open --no-qr zig-out/lib/cart.wasm
```
