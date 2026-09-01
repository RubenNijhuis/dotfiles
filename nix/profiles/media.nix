{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    sox
    yt-dlp
  ];
}
