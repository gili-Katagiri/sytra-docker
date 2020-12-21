#!/usr/bin/env bash
#-*- coding: utf-8 -*-

function sytra_extract()
{
    volumelist=(`docker volume ls -q`)
    for vol in "${volumelist[@]}"; do
        if [[ "$vol" == "$2" ]]; then
            echo -n "Docker-Volume '$vol' will removed: Alright? (y/n): "
            read input
            if [[ $input == [yY]* ]]; then
                docker volume rm $2
            else
                echo "You can also be create backup-archive: 'sytra backup'"
                exit 0
            fi
        fi
    done

    echo "extract: $1 into $2"
    docker run --rm -v $2:/root/data -v $1:/tmp/backup.tar.gz \
        busybox tar xzf /tmp/backup.tar.gz -C /root/data 
}

function sytra_backup()
{
    if [ -f $1 ]; then
        echo "$1 is already exists." 1>&2
        exit 1
    else
        echo "backup: archive $3:$2 as $1."
    fi
    
    dname=`dirname $1`
    bname=`basename $1`
    docker run --rm -v $3:/root/data -v $dname:/backup \
        busybox tar czf /backup/$bname -C $2 .
}

function sytra_import()
{
    echo "import from $1 to $3:$2."

    docker container create \
        --name importer \
        -v $3:/root/data sytra:latest \
        > /dev/null

    docker cp $1 importer:$2/`basename $1`
    docker rm importer > /dev/null
}

VOLUMENAME="sytra-stocks"
SUBCOM=$1
shift

if [[ $SUBCOM =~ "import"|"backup"|"extract" ]]; then
    while (( $# > 0 ))
    do
        case $1 in
            -f | --file)
                if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                    echo "sytra-util option [$1] requires an argument" 1>&2
                    exit 1
                elif [[ ! "$2" =~ ^/ ]]; then
                    FILENAME=`realpath $(pwd)/$2`
                else
                    FILENAME=$2
                fi
                shift 2
                ;;
            -t | --target)
                if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                    echo "sytra-util option [$1] requires an argument" 1>&2
                    exit 1
                fi
                TARGETFILE=$2
                shift 2
                ;;
            -v | --volume)
                if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                    echo "sytra-util option [$1] requires an argument" 1>&2
                    exit 1
                fi
                VOLUMENAME=$2
                shift 2
                ;;
            -*)
                echo "sytra-util illegal option: '$1'" 1>&2
                exit 1
                ;;
            *)
                echo "sytra-util illegal argument: '$1'" 1>&2
                exit 1
                ;;
        esac
    done


    case $SUBCOM in
        import)
            sytra_import ${FILENAME:-"`pwd`/summary.csv"}\
                         ${TARGETFILE:-"/root/data"}\
                         $VOLUMENAME
            ;;
        backup)
            sytra_backup ${FILENAME:-"`pwd`/backup.tar.gz"}\
                         ${TARGETFILE:-"/root/data"}\
                         $VOLUMENAME
            ;;
        extract)
            sytra_extract ${FILENAME:-"`pwd`/backup.tar.gz"} $VOLUMENAME
            ;;
    esac
else
    docker run --rm -it -v $VOLUMENAME:/root/data sytra:latest sytra $SUBCOM "$@"
fi
