{ pkgs, ... }:

{
  # Cross-platform asset-processing tools. Native design applications remain
  # platform catalog entries (for example, Homebrew casks on macOS).
  home.packages = with pkgs; [
    imagemagick
    oxipng
    pngquant
    svgcleaner
  ];
}
