FROM  nixpkgs/cachix-flakes AS build-enclave

ARG XARGO_SGX=0
ENV XARGO_SGX=${XARGO_SGX}

WORKDIR /usr/src/sgx-hello-rust

COPY .gitmodules buildenv.mk flake.lock flake.nix Makefile rust-toolchain .
COPY .git .git
COPY enclave enclave
COPY rust-sgx-sdk rust-sgx-sdk
COPY xargo xargo

RUN mkdir bin lib

RUN set -eux; \
    \
    mkdir -p ~/.config/nixpkgs; \
    echo "{ permittedInsecurePackages = [ \"openssl-1.1.1u\" ]; }" \
        >> ~/.config/nixpkgs/config.nix;

RUN cachix use gluonixpkgs
RUN nix build --impure .?submodules=1#enclave


FROM ghcr.io/initc3/sgx:2.19-buster-d271e64 as base

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

COPY --from=rust:1.70.0-buster /usr/local/rustup /usr/local/rustup
COPY --from=rust:1.70.0-buster /usr/local/cargo /usr/local/cargo


FROM base as build-app
WORKDIR /usr/src/sgx-hello-rust

COPY .gitmodules buildenv.mk Makefile rust-toolchain .
COPY .git .git
COPY app app
COPY rust-sgx-sdk rust-sgx-sdk

RUN mkdir bin lib

RUN make bin/app


FROM ghcr.io/initc3/sgx:2.19-buster-d271e64 as run-app

WORKDIR /opt/hello-rust

COPY --from=build-enclave /usr/src/sgx-hello-rust/result/bin/enclave.signed.so .
COPY --from=build-app /usr/src/sgx-hello-rust/bin/app .

CMD ["./app"]
