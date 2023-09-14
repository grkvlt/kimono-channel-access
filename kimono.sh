#!/opt/local/bin/bash
#
# K I M O N O . S H
# =================
#
# Version: 0.8.2
# Updated: 13 September 2023
#
# Downloads video and audio files from https://youtu.be/ using
# the yt-dlp(1) utility.
#
# USAGE
#
#     kimono.sh [ --help | -h | -? | --usage ]
#     CONFIG="options" kimono.sh ids...
#     kimono.sh [ options ] ids...
#
# ABOUT
#
# This script can be called with different names to perform particular
# functions. To download files using configuration values that are optimised
# for specific types of content, the following script names have been
# defined:
#
#     youtube
#         Download videos as MP4 with qualty audio at up to 1080p
#     podcast
#         Download a podcast with low quality video and decent audio
#     audio
#         Download the audio only as best quality MP3
#     video
#         Download videos with best overall quality
#
# Alternative functions can also be performed using the following names:
#
#     format
#         List available formats for a video id
#     playlist
#         Generate the JS code to create a playlist file from a YouTube mix
#     movies
#         Check if files are already downloaded
#
# Note that the `SCRIPT` variable or `--script` option can also be used to
# access these functions.
#
# CONFIG
# 
# The following environment variables can be used to apply or override
# configuration:
#
#     FORMAT
#         Configure the format to download directly, using the `yt-dlp`
#         format specifications. Use `--format-list` to get a list of the
#         available formats, and check the manual page and documentation
#         for `yt-dlp` itself for more in-depth information about creating
#         custom specifications
#     SCRIPT
#         Enable different script functionality
#     FRAGMENTS
#         Enable downloading multiple fragments in parallel
#     PLAYLIST
#         Set the name of the file containing ids or urls
#     TARGET
#         Set the target folder to save files to
#     CONFIG
#         Additional configuration options for `yt-dlp`
#
# These variables can be set in the global shell environment to set
# the base folder used for all file downloads of specific types:
#
#     MOVIES
#         Sets the main `Movies` target folder base
#     MUSIC
#         Sets the main `Music` target folder base
#
# These variables can be set to configure output logging:
# 
#     DRYRUN
#         Display `yt-dlp` command without executing
#     DEBUG
#         Enable script debug output
#         Set to 'trace' for full command logging
#     QUIET
#         Only show progress of downloads
#     VERBOSE
#         Verbose logging for `yt-dlp` process
#
# OPTIONS
#
# The following command-line options can be used in combination with the
# environment variables above to configure operation:
#
#     --format | -F format ; see `FORMAT`
#     --script | -s script ; see `SCRIPT`
#     --playlist | -P | -p filename ; see `PLAYLIST`
#     --fragments n ; see `FRAGMENTS`
#     --target | -T | -t folder ; see `TARGET`
#     --debug | -D ; see `DEBUG`
#     --trace ; see `DEBUG`
#     --dryrun ; see `DRYRUN`
#     --quiet | -q ; see `QUIET`
#     --verbose | -V ; see `VERBOSE`
#
# These command-line options are equivalent to the given scripts:
#
#     --format-list ; see `format.sh`
#     --javascript ; see `playlist.sh`
#
# These options display help, version and usage information:
#
#     --usage | --help | -h | -?
#     --version
#
# The configuration values set using environment variables will be overridden
# by values set using the command-line options. So, the following command will
# download the video into the `${MOVIES}/Lectures/MIT-1001/` target folder:
#
#     TARGET=Courses/MIT-1001 kimono.sh --target Lectures/MIT-1001 XxxxxXXX
#
# EXAMPLES
#
#     PLAYLIST=url.lst playlist.sh
#     kimono.sh --format 18 -T Interesting/Science XxxxxXXX XxxxxXYY XxxxxXZZ
#     FORMAT=139+340 FRAGMENTS=2 PLAYLIST=catalog.out kimono.sh
#     audio.sh -P mixtape.txt
#     podcast.sh XxxxxXXX
#     cut -d, -f2 videos.csv | video.sh 
#     DEBUG=y SCRIPT=video kimono.sh XxxxxXXX
#     movies.sh XxxxxXXX XxxxxXYY
# 
# Copyright: 2023 by Andrew Donald Kennedy
# License: CC BY-SA 4.0
# Author: mailto:andrew.international@gmail.com
# Source: https://github.com/grkvlt/

# output help text
function help() {
    sed -e "/^$/q" \
        -e "s/^# //g" \
        -e "s/^#//g" < $0 |
        grep -v "^!"
}

# keyword detection
function keyword() {
    keyword="$1"
    grep "^# [A-Za-z]*:" < $0 |
        sed -e "s/^# //g" |
        grep "^${keyword}:"
}

# output version
function version() {
    keyword "Version"
}

# parse command-line arguments
short="F:P:p:T:t:s:DqVh"
long="format:,playlist:,fragments:,target:,script:,debug,trace,dryrun,quiet,verbose,version,help,usage"
arguments=$(getopt -o ${short} --long ${long} -- "$@")
if [[ $? -ne 0 ]]; then
    help
    exit 1
fi
eval set -- "$arguments"
while [ : ] ; do
    case "$1" in
        -F | --format)
            FORMAT="$2"
            shift 2 ;;
        --format-list)
            SCRIPT="format"
            shift ;;
        --javascript)
            SCRIPT="playlist"
            shift ;;
        -P | -p | --playlist)
            PLAYLIST="$2"
            shift 2 ;;
        -T | -t | --target)
            TARGET="$2"
            shift 2 ;;
        -s | --script)
            SCRIPT="$2"
            shift 2 ;;
        --fragments)
            FRAGMENTS="$2"
            shift 2 ;;
        -D | --debug)
            DEBUG="y"
            shift ;;
        --trace)
            DEBUG="trace"
            shift ;;
        -q | --quiet)
            QUIET="y"
            shift ;;
        -V | --verbose)
            VERBOSE="y"
            shift ;;
        --dryrun)
            DRYRUN="y"
            shift ;;
        --version)
            version
            exit 0 ;;
        -h | --help | --usage)
            help
            exit 0 ;;
        --) shift
            break ;;
        *)
            help
            exit 1 ;;
    esac
done

# debug output
[ "${DEBUG}" == "trace" ] && set -x

# get our script name
script=$(basename $0 .sh | tr "A-Z" "a-z")
script=${SCRIPT:-${script}}

# make a temporary file for playlist content
temp=$(mktemp -d -t ${script})
[ "${DEBUG}" ] || trap "rm -rf ${temp}" EXIT

# output javascript for playlist file creation
playlist="${PLAYLIST:-playlist.txt}"
if [ "${script}" == "playlist" ] ; then
    cat <<EOF
// ---- copy into browser developer tools console ----
function download(filename, text) {
    var element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
    element.setAttribute('download', filename);
    element.style.display = 'none';
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
}
var urls = "";
document.querySelectorAll("ytd-playlist-panel-video-renderer").forEach(function(element) {
    urls += element.querySelector("#wc-endpoint").href.split("&")[0] + "\n";
});
download("${playlist}", urls);
// ---- press return to execute download function ----
EOF
    exit
fi

# check arguments for playlist files
if [ $# -eq 0 ] ; then
    file="-"
    for f in download.txt ${script}.txt ${playlist} ; do
        if [ -f "${f}" ] ; then
            file="${f}"
        fi
    done
    # remove comments, trim whitespace and blank lines
    cat ${file} |
        sed -e "s/#.*$//g" \
            -e "s/^[ 	]*//g" \
            -e "s/[ 	]*\$//g" |
        grep -v "^\$" > ${temp}/source
    source="--batch-file ${temp}/source"
else
    source="-- $@"
fi

# check available formats
if [[ "${script}" = "format" ]] ; then
    yt-dlp -F \
            --cookies-from-browser chrome \
            ${source}
    exit
fi

# check for different target folder
if [ "${script}" == "audio" ] ; then
    home="${MUSIC:-${HOME}/Music}"
else
    home="${MOVIES:-${HOME}/Movies}"
fi
if [ "${TARGET}" ] ; then
    if [[ "${TARGET:0:1}" != "/" &&
          "${TARGET:0:1}" != "." &&
          "${TARGET:0:1}" != "~" ]] ; then
        target="${home}/${TARGET}"
    else
        target="${TARGET}"
    fi
else
    if [[ "${PWD}" == "${home}" ||
          "${PWD}" = ${home}/* ]] ; then
        target="${PWD}"
    else
        target="${home}"
    fi
fi
paths="--paths temp:${temp} \
       --paths home:${home} \
       --paths ${target}"

# search for downloaded file ids
if [ "${script}" == "movies" ] ; then
    if [ $# -gt 0 ] ; then
        for id in $@ ; do
            find ${home} -name "*${id}*" -print ||
                find . -name "*${id}*" -print
        done
    fi
    exit
fi

# configure download file format
bestvideo="bestvideo[ext=mp4]+bestaudio[ext=m4a]"
podcast="worstvideo[ext=mp4]+bestaudio.2[ext=m4a]"
audio="bestaudio[ext=m4a]"
youtube="best[height<=1080][ext=mp4]"
case ${script} in
    podcast)
        format=${FORMAT:-${podcast}} ;;
    audio)
        format=${FORMAT:-${audio}} ;;
    video)
        format=${FORMAT:-${bestvideo}} ;;
    kimono | youtube)
        format=${FORMAT:-${youtube}} ;;
    *)
        format=${FORMAT:-best} ;;
esac

# set output level
if [[ "${QUIET}" ]] ; then
    level="--quiet"
elif [[ "${VERBOSE}" || "${DEBUG}" = "trace" ]] ; then
    level="--verbose"
fi
if [[ "${DRYRUN}" && -z "${DEBUG}" ]] ; then
    DEBUG="${DRYRUN}"
fi

# output debug information
[ "${DEBUG}" ] && (
    cat <<EOF
[debug] script = ${script}
[debug] format = ${format}
[debug] source = ${file:-$@}
[debug] target = ${target:-.}
[debug] movies = ${home}
[debug] output = $(echo ${level:-default} | tr "a-z" "A-Z" | tr -d "-")
[debug] config = ${CONFIG}
EOF
    echo "${paths}" |
        sed -e "s/--paths //g" |
        tr -s " " |
        sed -e "s/ /\n/g" |
        sed -e "s/^/[debug] /g"
)

# set options for video or audio
if [ "${script}" == "audio" ] ; then
    options="--audio-format mp3 \
             --extract-audio"
else
    options="--embed-metadata \
             --embed-thumbnail \
             --embed-chapters \
             --embed-subs \
             --write-automatic-subs \
             --sub-langs en \
             --merge-output-format mp4"
fi

# setup yt-dlp command-line options
command="yt-dlp \
             --cookies-from-browser chrome \
             --mark-watched \
             --concurrent-fragments ${FRAGMENTS:-1} \
             --progress \
             ${level} \
             --restrict-filenames \
             ${paths} \
             --no-warnings \
             --playlist-random \
             --format ${format} \
             ${options} \
             --xattrs \
             --xattr-set-filesize \
             ${CONFIG} \
             ${source}"

# download from youtube
[ "${DEBUG}" ] && echo "[debug] ${command}" | tr -s " "
[ ! "${DRYRUN}" ] && ( mkdir -p ${target} ; ${command} )
