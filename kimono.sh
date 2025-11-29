#!/opt/local/bin/bash
#
# K I M O N O . S H
# =================
#
# Version: 0.8.10
# Updated: 29 November 2025
#
# Downloads video and audio files from https://youtu.be/ using
# the yt-dlp(1) utility. See the README.md file on GitHub for
# more detailed information on command line options and environment
# variables.
#
# USAGE
#
#     kimono.sh [ --help | -h | -? | --usage ]
#     CONFIG="options" kimono.sh ids...
#     kimono.sh [ options ] ids...
#
# EXAMPLES
#
#     kimono.sh --format 18 -t Interesting/Science XXXXXXXX XXXXXXYY XXXXXXZZ
#     FORMAT="139+340" FRAGMENTS="2" PLAYLIST="catalog.out" kimono.sh
#     kimono.sh --quality "podcast" XXXXXXXX
#     audio.sh -p mixtape.txt
#     podcast.sh XXXXXXXX
#     video.sh --quiet XXXXXXXX
#     cut -d, -f2 videos.csv | youtube.sh 
#     DEBUG=y SCRIPT=video kimono.sh XXXXXXXX
#     kimono.sh --list-formats --playlist "index.txt"
#     kimono.sh --find-ids XXXXXXXX XXXXXXYY
#     PLAYLIST="mixtape.txt" kimono.sh --javascript
#     kimono.sh --duplicates -t Recent
#
# Copyright: 2023-2025 by Andrew Donald Kennedy
# License: CC BY-SA 4.0
# Author: mailto:andrew.international@gmail.com
# Source: https://github.com/grkvlt/kimono-channel-access

# function definitions

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

# exported variables
export DEBUG DRYRUN FORMAT FRAGMETS
export ORDER PLAYLIST QUALITY QUIET
export LANGUAGE SCRIPT SUBTITLES TARGET VERBOSE

# parse command-line arguments
short="f:q:s:p:t:LDQTvVh?"
long="format:,quality:,order:,script:,playlist:,target:,fragments:,random"
long="${long},subtitles:,language:,list-formats,duplicates,find-ids,javascript"
long="${long},debug,trace,quiet,verbose,dryrun"
long="${long},version,help,usage"
arguments=$(getopt -o ${short} --long ${long} -- "$@")
if [[ $? -ne 0 ]]; then
    help
    exit 1
fi
eval set -- "${arguments}"
while true ; do
    case "$1" in
        -f | --format)
            FORMAT="$2"
            shift 2 ;;
        -q | --quality)
            QUALITy="$2"
            shift 2 ;;
        --order)
            ORDER="$2"
            shift 2 ;;
        --random)
            ORDER="random"
            shift ;;
        -s | --script)
            SCRIPT="$2"
            shift 2 ;;
        -p | --playlist)
            PLAYLIST="$2"
            shift 2 ;;
        -t | --target)
            TARGET="$2"
            shift 2 ;;
        --fragments)
            FRAGMENTS="$2"
            shift 2 ;;
        --subtitles)
            SUBTITLES="$2"
            shift 2 ;;
        --language)
            LANGUAGE="$2"
            shift 2 ;;
        -L | --list-formats)
            SCRIPT="list-formats"
            shift ;;
        --duplicates)
            SCRIPT="duplicates"
            shift ;;
        --find-ids)
            SCRIPT="find-ids"
            shift ;;
        --javascript)
            SCRIPT="javascript"
            shift ;;
        -D | --debug)
            DEBUG="y"
            shift ;;
        -T | --trace)
            DEBUG="trace"
            shift ;;
        -Q | --quiet)
            QUIET="y"
            shift ;;
        -V | --verbose)
            VERBOSE="y"
            shift ;;
        --dryrun)
            DRYRUN="y"
            shift ;;
        -v | --version)
            version
            exit 0 ;;
        -h | --help | --usage | -\?)
            help
            exit 0 ;;
        --)
            shift
            break ;;
        *)
            help
            exit 1 ;;
    esac
done

# debug output
[[ "${DEBUG}" == "trace" ]] && set -x

# set output level
if [[ "${QUIET}" ]] ; then
    level="--quiet"
elif [[ "${VERBOSE}" || "${DEBUG}" = "trace" ]] ; then
    level="--verbose"
fi
if [[ "${DRYRUN}" && -z "${DEBUG}" ]] ; then
    DEBUG="${DRYRUN}"
fi

# get our script name
script=$(basename $0 .sh | tr "A-Z" "a-z")
script="${SCRIPT:-${script}}"

# make a temporary file for playlist content
temp=$(mktemp -d -t ${script})
[[ "${DEBUG}" ]] || trap "rm -rf ${temp}" EXIT

# check for different target folder
if [[ "${script}" == "audio" || "${script}" == "javascript" ]] ; then
    home="${MUSIC:-${HOME}/Music}"
else
    home="${MOVIES:-${HOME}/Movies}"
fi
if [[ "${TARGET}" ]] ; then
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

# output javascript for playlist file creation
playlist="${PLAYLIST:-playlist.txt}"
if [[ "${script}" == "javascript" ]] ; then
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
download("${target}/${playlist}", urls);
// ---- press return to execute download function ----
EOF
    exit
fi

# search for downloaded file ids
if [[ "${script}" == "find-ids" ]] ; then
    if [[ $# -gt 0 ]] ; then
        for id in $@ ; do
            find ${home} -name "*${id}*" -print ||
                find . -name "*${id}*" -print
        done
    fi
    exit
fi

# search for duplicate files by id
if [[ "${script}" == "duplicates" ]] ; then
    find ${target} -type f -name "*\[???????????\].*" |
            rev |
            cut -d. -f2 |
            cut -c2-12 |
            rev |
            sort |
            uniq -d |
            xargs $0 --find-ids
    exit
fi

# configure download file format
podcast="[height<=480][ext=mp4]+bestaudio"
youtube="best[height>=720][ext=mp4][language*=${LANGUAGE:-en}]"

case "${QUALITY:-${script}}" in
    podcast | audio)
        format="${FORMAT:-${podcast}}" ;;
    youtube)
        format="${FORMAT:-${youtube}}" ;;
    *)
        format="${FORMAT:-best}" ;;
esac

# check arguments for playlist files
if [[ $# -eq 0 ]] ; then
    file="-"
    for f in download.txt ${script}.txt ${playlist} ; do
        if [[ -f "${f}" ]] ; then
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
if [[ "${script}" == "list-formats" ]] ; then
    yt-dlp --quiet \
            --cookies-from-browser chrome \
            --list-formats \
            ${source}
    exit
fi

# output debug information
[[ "${DEBUG}" ]] && (
    cat >&2 <<EOF
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
        sed -e "s/^/[debug] /g" >&2
)

# set options for video or audio
if [[ "${script}" == "audio" ]] ; then
    options="--audio-format mp3 \
             --extract-audio"
else
    options="--embed-metadata \
             --embed-thumbnail \
             --embed-chapters \
             --merge-output-format mp4"
    if [[ "${SUBTITLES}" || "${script}" == "youtube" ]] ; then
        subs="--embed-subs \
              --write-automatic-subs \
              --sub-langs ${SUBTITLES:-en}"
        options="${options} ${subs}"
    fi
fi
order="${ORDER:-random}"
case "${order}" in
    random)
        options="${options} --playlist-random" ;;
esac

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
             --format ${format} \
             --xattrs \
             --xattr-set-filesize \
             ${options} \
             ${CONFIG} \
             ${source}"

# download from youtube
[[ "${DEBUG}" ]] && echo "[debug] ${command}" | tr -s " " >&2
[[ ! "${DRYRUN}" ]] && ( mkdir -p ${target} ; ${command} )
