{ pkgs, ... }:

let
  # The pinned Zoom build strips its signed binaries, breaking its signature.
  # Preserve the signed payload; its CLI wrapper still lives outside the app.
  zoom = pkgs.zoom-us.overrideAttrs {
    dontStrip = true;
    dontPatchShebangs = true;
  };
in
{
  imports = [
    ../home/cmux.nix
    ../home/raycast.nix
  ];

  # Restore checklist, not TCC enforcement. macOS requires device-local consent;
  # never grant access by editing its database or bypassing Home Manager checks.
  xdg.configFile."dotfiles/macos-permissions.txt".text = ''
    macOS permission policy — manual review, NOT automatically enforced
    Open System Settings > Privacy & Security on each new Mac.

    Accessibility: Codex Computer Use, OneMenu, Raycast.
    App Management: cmux; the app named ChatGPT (bundle ID com.openai.codex).
    Screen & System Audio Recording: Codex Computer Use, Discord, Zen/Twilight.
    Input Monitoring: none.
    Full Disk Access: none by default; review a demonstrated need separately.
    Passkeys Access for Web Browsers: Zen/Twilight only.
    Camera and Microphone: off for Arc and Brave; other apps only for used features.
    Local Network: review app-specific needs; repeated rows are not proof of duplicate apps.

    These are the reviewed baseline exceptions, not blanket grants to other apps.
    Names alone do not establish identity; check the actual app before approving.
    Do not reset all permissions, copy TCC databases, or install MDM to automate this.
    Camera, microphone and screen-recording grants still require user consent.
    Permission changes may require the affected app to quit and reopen.
  '';

  # These applications are intentionally macOS-only. Their configuration and
  # account state remain app-managed, while Nix owns the installation.
  home.packages = [
    pkgs.cmux
    pkgs.orbstack
    pkgs.raycast
    # Already-installed specialist apps. Keep these out of the portable base;
    # accounts, CrossOver bottles/licenses, and Zoom helpers stay app-owned.
    pkgs.crossover
    zoom
  ];
}
