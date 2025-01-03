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
            src = ./src;
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
            version = "1.0.7277";
          in
          stdenv.mkDerivation {
            name = "datomic-transactor-${version}";
            src = pkgs.fetchzip {
              url = "https://datomic-pro-downloads.s3.amazonaws.com/${version}/datomic-pro-${version}.zip";
              sha256 = "sha256-fqmw+MOUWPCAhHMROjP48BwWCcRknk+KECM3WvF/Ml4=";
            };
            #            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p $out/
              cp -R $src/* $out/.
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
