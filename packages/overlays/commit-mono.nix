final: prev: {
  commit-mono = prev.commit-mono.overrideAttrs (cfinal: cprev: {
  installPhase = ''

    runHook preInstall
    install -Dm644 CommitMono-${version}/*.otf             -t $out/share/fonts/opentype
    runHook postInstall
  '';
  })
}
