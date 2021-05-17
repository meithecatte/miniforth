{ pkgs ? import <nixpkgs> {} }:

with pkgs; mkShell {
  nativeBuildInputs = [ yasm qemu ];
}

