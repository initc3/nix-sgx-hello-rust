# nix-hello-sgx-rust
hello-rust sample from the rust sgx sdk codebase

## Quick demo
Clone the repo with the submodule, e.g.:

```console
git clone --recurse-submodules https://github.com/initc3/nix-sgx-hello-rust.git
```

Run the demo with docker compose:

```console
$ docker compose up
...
nix-hello-sgx-rust-aesmd-1       | system_bundle:4.0.0
nix-hello-sgx-rust-hello-rust-1  | [+] Init Enclave Successful 2!
nix-hello-sgx-rust-hello-rust-1  | This is a normal world string passed into Enclave!
nix-hello-sgx-rust-hello-rust-1  | This is a in-Enclave Rust string!
nix-hello-sgx-rust-hello-rust-1  | [+] say_something success...
nix-hello-sgx-rust-hello-rust-1 exited with code 0
```
