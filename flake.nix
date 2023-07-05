{
  description = "rust sgx sdk";

  inputs = {
    nixpkgs.url = "github:sbellem/nixpkgs/20ff746c79c5f0c10b8c4aa8e0b441e0b0ebd034";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    rust-overlay,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system: let
        pname = "Helloworldsampleenclave";
        version = "1.0.0";

        src = builtins.path {
          path = ./.;
          name = "${pname}-${version}";
        };
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        
        rust_toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;
      in
        with pkgs; {

          packages.enclave = rustPlatform.buildRustPackage rec {
            inherit rust_toolchain src pname version;
            cargoLock = {
              lockFile = "${src}/enclave/Cargo.lock";
            };
            postPatch = ''
              ln -s ${./enclave/Cargo.lock} Cargo.lock
              '';

            nativeBuildInputs = [
              autoconf
              automake
              libtool
              sgx-sdk
              (rust_toolchain.override {
                extensions = [ "rust-src" "rls" "rust-analysis" "clippy" "rustfmt"];
              })
              which
            ];

            buildInputs = [
              which
            ];

            SGX_SDK = "${sgx-sdk}/sgxsdk";
            RUST_BACKTRACE = 1;

            #dontConfigure = true;

            buildPhase = ''
              runHook preBuild

              make bin/enclave.signed.so

              runHook postBuild
            '';

            doCheck = false;
            checkPhase = null;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin $out/lib
              cp -r bin/enclave.signed.so $out/bin/
              cp -r lib/libenclave.a $out/lib/

              runHook postInstall
            '';
            dontFixup = true; 
            dontStrip = true;
          };
          
          packages.app = rustPlatform.buildRustPackage rec {
            inherit rust_toolchain; 
            pname = "app";
            version = "1.0.0";

            src = builtins.path {
              path = ./.;
              name = "${pname}-${version}";
            };
        
            cargoLock = {
              lockFile = "${src}/app/Cargo.lock";
            };
            postPatch = ''
              ln -s ${./app/Cargo.lock} Cargo.lock
            '';

            nativeBuildInputs = [
              autoconf
              automake
              libtool
              sgx-sdk
              (rust_toolchain.override {
                extensions = [ "rust-src" ];
              })
              which
            ];
            
            buildInputs = [
              which
            ];

            SGX_SDK = "${sgx-sdk}/sgxsdk";

            #dontConfigure = true;

            buildPhase = ''
              runHook preBuild

              make bin/app

              runHook postBuild
            '';

            doCheck = false;
            checkPhase = null;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              cp -r bin/app $out/bin/

              runHook postInstall
            '';
            dontFixup = true; 
            dontStrip = true;
          };

          defaultPackage = self.packages.${system}.enclave;

          devShell = mkShell {
            inherit src rust_toolchain;

            XARGO_SGX = 1;

            nativeBuildInputs = [
                (rust_toolchain.override {
                  extensions = [ "rust-src" "rls" "rust-analysis" "clippy" "rustfmt"];
                })
              ];

            buildInputs = [
                autoconf
                automake
                libtool
                sgx-sdk
                exa
                fd
                unixtools.whereis
                which
                b2sum
              ];

            RUST_BACKTRACE = 1;
            SGX_SDK = "${sgx-sdk}/sgxsdk";

            shellHook = ''
              alias ls=exa
              alias find=fd
            '';
          };
        }
    );
}
