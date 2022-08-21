# Strikeforce

A game written in Zig for the [WASM-4](https://wasm4.org) fantasy console. This
is a submission for [WASM-4 Jam #2](https://itch.io/jam/wasm4-v2) hosted at
itch.io.

[Link to submission](https://itch.io/jam/wasm4-v2/rate/1672633)

![Game screenshot](./strikeforce.png)

## Building

Build and run the cart:

```shell
zig build -Drelease-small && w4 run --no-open --no-qr zig-out/lib/cart.wasm
```
