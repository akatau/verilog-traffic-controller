let
  pkgs = import <nixpkgs> {};
in

pkgs.mkShell {
  buildInputs = [
    pkgs.iverilog
    pkgs.gtkwave
    pkgs.verilator
    pkgs.zsh
  ];

  shellHook = ''
    export PS1="[verilog-env] \$PS1"
    export SHELL="${pkgs.zsh}/bin/zsh"
    # enter zsh
    exec zsh
  '';
}
