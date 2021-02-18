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

function sytra_export()
{
    echo "export from $3:$2/`basename $1` to $1."

    docker container create \
	--name exporter \
	-v $3:/root/data sytra:latest \
	> /dev/null
    
    docker cp exporter:$2/`basename $1` $1
    docker rm exporter > /dev/null
}

function sytra_rootine()
{
    WAYPOINT="${SYTRA_WAYPOINT}"
    if [ ! -f "${WAYPOINT}"/summary.csv ]; then
	echo "ERROR: \$SYTRA_WAYPOINT/summary.csv is not found."
	exit 1
    fi
    docker container create -i \
	    --name rootine \
	    -v $1:/root/data \
	    sytra:latest sytra analyze \
	    > /dev/null
    
    # import summary.csv
    echo "sytra:import from $WAYPOINT/summary.csv to $1:/root/data/summary.csv"
    docker cp "${WAYPOINT}"/summary.csv rootine:/root/data/summary.csv
    # sytra analyze
    docker start -i rootine
    # update summarys
    if [ $? -eq 0 ]; then
	# rm host summary{,_base}.csv
        rm -f "${WAYPOINT}"/summary.csv "${WAYPOINT}"/summary_base.csv
	# export summary_base.csv
    	echo "sytra:export from $1:/root/data/summary_base.csv $WAYPOINT/summary_base.csv" 
        docker cp rootine:/root/data/summary_base.csv "${WAYPOINT}"/summary_base.csv
    fi
    docker rm rootine > /dev/null
}

VOLUMENAME="sytra-stocks"
SUBCOM=$1
shift

if [[ $SUBCOM =~ "import"|"export"|"backup"|"extract"|"rootine" ]]; then
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
        export)
            sytra_export ${FILENAME:-"`pwd`/summary_base.csv"}\
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
	rootine)
	    sytra_rootine $VOLUMENAME
    esac
else
    docker run --rm -it -v $VOLUMENAME:/root/data sytra:latest sytra $SUBCOM "$@"
fi
