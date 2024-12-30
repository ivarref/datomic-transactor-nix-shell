{
  description = "flask-example";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      poetry2nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
	name = "simple";
        src = ./.;
        pkgs = import nixpkgs { inherit system; };
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
      in
      with pkgs;
      rec {
	packages.datomic-transactor =
          let
            version = "1.0.7277";
            inherit (pkgs) stdenv lib;
          in
          stdenv.mkDerivation
            {
              name = "datomic-transactor-${version}";
              src = pkgs.fetchzip {
                url = "https://datomic-pro-downloads.s3.amazonaws.com/${version}/datomic-pro-${version}.zip";
                sha256 = "sha256-fqmw+MOUWPCAhHMROjP48BwWCcRknk+KECM3WvF/Ml4=";
              };

	      nativeBuildInputs = [
    		makeWrapper
  	      ];

	      phases = [ "installPhase" "postInstall" ];
              installPhase = ''
		    mkdir -p $out/bin
		    mkdir -p $out/janei
		    cp -R $src/* $out/.
		    echo "$src" > $out/meh.txt
		  '';

	     postInstall = ''
		mkdir -p $out/bin
      		wrapProgram $out/bin/transactor --prefix PATH : $out --prefix PATH : $(pwd)
      		'';
            };
        # Development environment
        devShell = mkShell {
          buildInputs = [
	    jdk
            poetry
            python3
	    packages.datomic-transactor
          ];
        };
      }
    );
}
