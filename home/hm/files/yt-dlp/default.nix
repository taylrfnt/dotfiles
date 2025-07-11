{
  enable = true;
  extraConfig = ''
    # save files in specific directory
    -o ~/Downloads/%(title)s.%(ext)s

    # always get metadata, chapters, & thumbnail
    --add-metadata
    --embed-thumbnail
    --embed-chapters

    # show progress bar
    --progress

    # always get the highest res video and audio
    -f "bestvideo*+bestaudio/best"

    # record into mp4 once downloaded via ffmpeg
    --recode-video mp4

    # use h264 instead of vp09 or other codecs
    -S vcodec:h264
  '';
}
