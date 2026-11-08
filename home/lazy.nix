# Wrap a package so it's built (or downloaded) the first time it's launched
# instead of with the rest of the config. The launcher only holds the
# package's .drv, so e.g. an unfree app that Hydra never caches doesn't hold
# up every rebuild. The result is pinned to the same nixpkgs as everything
# else, and a root in `stateDir` keeps it from being garbage collected until
# an update moves the launcher to a newer build.
#
#   lazy { pkg = pkgs.foo; desktopItem = { desktopName = "Foo"; ... }; }
{
  lib,
  writeShellScriptBin,
  symlinkJoin,
  makeDesktopItem,
  libnotify,
  stateDir,
}:

{
  pkg,
  name ? pkg.pname,
  exe ? pkg.meta.mainProgram,
  # makeDesktopItem arguments; `icon` is a path inside the built package
  desktopItem ? null,
}:

let
  # referencing these must not make the launcher depend on the build output
  drv = builtins.unsafeDiscardOutputDependency pkg.drvPath;
  out = builtins.unsafeDiscardStringContext pkg.outPath;
  root = "${stateDir}/${name}";
  log = "${stateDir}/${name}.log";
  label = if desktopItem != null then desktopItem.desktopName else name;
  notify = "${libnotify}/bin/notify-send --app-name=${lib.escapeShellArg label}";

  launcher = writeShellScriptBin exe ''
    if [ "$(readlink ${root})" != ${out} ] || [ ! -e ${out} ]; then
      mkdir -p ${stateDir}
      id=$(${notify} --print-id --icon=system-software-install \
        ${lib.escapeShellArg label} "Building on first launch, this can take a while…")
      if ! nix --extra-experimental-features nix-command \
          build --out-link ${root} '${drv}^out' >${log} 2>&1; then
        ${notify} --replace-id="$id" --urgency=critical \
          ${lib.escapeShellArg label} "Build failed, see ${log}"
        exit 1
      fi
      ${notify} --replace-id="$id" --expire-time=5000 ${lib.escapeShellArg label} "Ready"
    fi
    exec ${out}/bin/${exe} "$@"
  '';
in
symlinkJoin {
  name = "${name}-lazy";
  paths = [
    launcher
  ]
  ++ lib.optional (desktopItem != null) (
    makeDesktopItem (
      desktopItem
      // {
        inherit name;
        exec = "${launcher}/bin/${exe}";
      }
      // lib.optionalAttrs (desktopItem ? icon) { icon = "${root}/${desktopItem.icon}"; }
    )
  );
}
