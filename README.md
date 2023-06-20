# Strikeforce

A game written in Zig for the [WASM-4](https://wasm4.org) fantasy console. This
is a submission for [WASM-4 Jam #2](https://itch.io/jam/wasm4-v2) hosted at
itch.io.

[itch.io submission page](https://itch.io/jam/wasm4-v2/rate/1672633)  
[itch.io game page](https://iszn-11.itch.io/strikeforce)  
[Wasmer package](https://wasmer.io/iszn_11/strikeforce)  

![Game screenshot](./strikeforce.png)

## Building

Build and run the cart:

```shell
zig build -Drelease-small && w4 run --no-open --no-qr zig-out/lib/cart.wasm
```
