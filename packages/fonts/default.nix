{pkgs, ...}: {
  fonts = {
    # commit-mono installs very strangely on darwin, specifically ttfs
    # just install otfs :)
    packages = let
      commit-mono-otf = pkgs.commit-mono.overrideAttrs (final: prev: {
        installPhase = ''

          runHook preInstall
          install -Dm644 CommitMono-${prev.version}/*.otf             -t $out/share/fonts/opentype
          runHook postInstall
        '';
      });
      # in [/. "${commit-mono-otf}"];
    in [
      "${commit-mono-otf}"
      pkgs.nerd-fonts.symbols-only
    ];
  };
}
