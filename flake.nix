{
  # Based on:
  # https://fasterthanli.me/series/building-a-rust-service-with-nix/part-10#a-flake-with-mkderivation
  # https://github.com/justinwoo/nix-shorts/blob/master/posts/your-first-derivation.md
  description = "datomic-transactor-example";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) stdenv lib;
      in
      with pkgs;
      rec {
        packages.default =
          let
            transactor-deps = [ packages.datomic-transactor ];
          in
          stdenv.mkDerivation {
            name = "datomic-launcher";
            src = ./transactor;
            nativeBuildInputs = [ makeWrapper ];
            buildInputs = transactor-deps;
            phases = [
              "installPhase"
              "postInstall"
            ];
            installPhase = ''
              mkdir -p $out/bin
              cp -fv $src/*.sh $out/bin/.
            '';
            postInstall = ''
              wrapProgram $out/bin/transactor.sh --prefix PATH : ${lib.makeBinPath transactor-deps}
            '';
          };

        packages.datomic-transactor =
          let
            datomic-version = "1.0.7277";
            sqllite-version = "3.47.0.0";
          in
          stdenv.mkDerivation {
            name = "datomic-transactor-${datomic-version}";
            src = pkgs.fetchzip {
              url = "https://datomic-pro-downloads.s3.amazonaws.com/${datomic-version}/datomic-pro-${datomic-version}.zip";
              sha256 = "sha256-fqmw+MOUWPCAhHMROjP48BwWCcRknk+KECM3WvF/Ml4=";
            };
            src2 = pkgs.fetchurl {
              url = "https://github.com/xerial/sqlite-jdbc/releases/download/${sqllite-version}/sqlite-jdbc-${sqllite-version}.jar";
              sha256 = "sha256-k9R8AGN3xHb497RdANIGBrd9WVFCPzRu9WtbCBNhwtM=";
            };
            installPhase = ''
              mkdir -p $out/lib
              cp -R $src/* $out/.
              cp $src2 $out/lib/sqlite-jdbc-${sqllite-version}.jar
            '';
          };

        # Development environment
        devShell = mkShell {
          buildInputs = [
            clojure
            jdk
            packages.default
          ];
        };
      }
    );
}
