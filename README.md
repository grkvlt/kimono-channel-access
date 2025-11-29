# K I M O N O . S H

> Version: 0.8.10
> Updated: 29 November 2025

Downloads video and audio files from [YouTube](https://youtu.be/) using
the _yt-dlp(1)_ utility.

## USAGE

```shell
$ kimono.sh --help
...
$ CONFIG="options" kimono.sh ids...
...
$ kimono.sh --options ids...
...
```

## ABOUT

This script can be called with different names to perform particular
functions. To download files using configuration values that are optimised
for specific types of content, the following script names have been
defined:

- youtube.sh:
    Download videos as MP4 with qualty audio at up to 1080p resolution.
- podcast.sh:
    Download a podcast with low quality video and decent audio.
- audio.sh:
    Download the audio only as best quality MP3.
- video.sh:
    Download videos with best overall quality.

## CONFIG

The following environment variables can be used to apply or override
configuration:

- `FORMAT`:
    Configure the format to download directly, using the `yt-dlp`
    format specifications. Use `--format-list` to get a list of the
    available formats, and check the manual page and documentation
    for `yt-dlp` itself for more in-depth information about creating
    custom specifications.
- `QUALITY`:
    Set different pre-defined format specifications.
- `SCRIPT`:
    Enable different script functionality.
- `FRAGMENTS`:
    Enable downloading multiple fragments in parallel.
- `PLAYLIST`:
    Set the name of the file containing ids or urls.
- `TARGET`:
    Set the target folder to save files to.
- `ORDER`:
   Either **random** or **sequential** order for playlist downloads.
- `CONFIG`:
    Additional configuration options for `yt-dlp`.

These variables can be set in the global shell environment to set
the base folder used for all file downloads of specific types:

- `MOVIES`:
    Sets the target folder base for video files. Defaults to the
    `~/Movies` folder.
- `MUSIC`:
    Sets the target folder base for audio files. Defaults to the
    `~/Music` folder.

These variables can be set to configure output logging:

- `DRYRUN`:
    Display `yt-dlp` command without executing.
- `DEBUG`:
    Enable script debug output.  Set to _trace_ for full command logging.
- `QUIET`:
    Only show progress of downloads.
- `VERBOSE`:
    Verbose logging for `yt-dlp` process.

## OPTIONS

Various command-line options can be used in combination with the
environment variables above to configure operation. The following options
require a value to be specified:

- `--format` | `-f` _format_ ; see `FORMAT`
- `--quality` | `-q` _quality_ ; see `QUALITY`
- `--script` | `-s` _script_ ; see `SCRIPT`
- `--playlist` | `-p` _filename_ ; see `PLAYLIST`
- `--fragments` _n_ ; see `FRAGMENTS`
- `--target` | `-t` _folder_ ; see `TARGET`

- `--order` _order_
- `--random`

- `--subtitles` _languages_
- `--language` _languages_

These options for debugging and output configuration do not need a value:

- `--debug` | `-D` ; see `DEBUG`
- `--trace` | `-T` ; see `DEBUG`
- `--dryrun` ; see `DRYRUN`
- `--quiet` | `-Q` ; see `QUIET`
- `--verbose` | `-V` ; see `VERBOSE`

These options will execute portions of the script which provide additional
functionality. The script operates differently from its default behaviour,
but still uses the same shared variables and configuration:

- `-L` or `--list-formats`:
    List available formats for the video ids.
- `--javascript`:
    Generate the JS code to create a playlist file from a YouTube mix.
- `--find-ids`:
    Search for files in the target `Movies` folder by id.
- `--duplicates`:
    Search the target `Movies` folder for files with the same id.

These options display usage, help or version information:

- `--usage`
- `--help` | `-h` | `-?`
- `--version` | `-v`

The configuration values set using environment variables will be overridden
by values set using the command-line options. So, the following command will
download the video into the `${MOVIES}/Lectures/MIT-1001/` target folder:

```shell
    TARGET=Courses/MIT-1001 kimono.sh --target Lectures/MIT-1001 XXXXXXXX
```

## EXAMPLES

```shell
    kimono.sh --format 18 -t Interesting/Science XXXXXXXX YYYYYYYY ZZZZZZZZ
    FORMAT="139+340" FRAGMENTS="2" PLAYLIST="catalog.out" kimono.sh
    kimono.sh --quality "podcast" XXXXXXXX
    youtube.sh -random PPPPPPPPPPPPPPPP
    audio.sh -p mixtape.txt
    podcast.sh XXXXXXXX
    video.sh --quiet XXXXXXXX
    cut -d, -f2 videos.csv | youtube.sh 
    DEBUG=y SCRIPT=video kimono.sh XXXXXXXX
    kimono.sh --list-formats --playlist "index.txt"
    kimono.sh --find-ids XXXXXXXX YYYYYYYY
    PLAYLIST="mixtape.txt" kimono.sh --javascript
    kimono.sh --duplicates -t Recent
```

---

> Copyright: 2023-2026 by Andrew Donald Kennedy  
> License: CC BY-SA 4.0  
> Author: [andrew.international@gmail.com](mailto:andrew.international+kimono@gmail.com)  
> Source: [grkvlt/kimono-channel-access](https://github.com/grkvlt/kimono-channel-access.git)
