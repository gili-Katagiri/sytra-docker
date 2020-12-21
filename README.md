[sytra-repo]: https://github.com/gili-Katagiri/sytra

# sytra-docker
## Abstract
`Dockerfile` prepared this repository is easiest way 
to construct [sytra][sytra-repo] environment isolatedly.

## Installation

The installation procedure is as described below.
In some cases, you may need to use `sudo`.

1. Clone this repository on your local machine.  
1. Build image from dockerfile.  
1. Set entrypoint to sytra.  

```bash
    # Clone into your local
    git clone https://github.com/gili-Katagiri/sytra-docker ~/sytra-docker
    cd ~/sytra-docker

    # Build image
    docker build -t sytra:latest .

    # Set entrypoint
    cp sytra-entry.sh /usr/local/bin/sytra 
    chmod 755 /usr/local/bin/sytra 
```

---
***Note:***
*You already can delete `~/sytra-docker` if you want to.
Moreover, you can clean uninstall easily 
if you delete Docker-Image (as `sytra:latest`), 
Docker-Volume (if created, default-name: `sytra-stocks`) 
and `/usr/local/bin/sytra`.*

---

## Usage
`sytra-entry.sh` eliminates the complexity of the commands 
associated with using `Docker`.

A simple example would be:
```bash
    # sytra follow command with container
    docker run --rm -it -v sytra-stocks:/root/data sytra:latest sytra follow 1234
    # this is equivalent to 
    sytra follow 1234 
```
Furthermore, you can use three subcommands `import`, `backup` and `extract` 
in addition to the [sytra][sytra-repo] basic commands.

---
*Note: The target Docker-Volume can be specified with the -v option 
in every situation.*

---

### import
`import` command is an alternative to the `cp` command.
More precisely, this command copy the local file to Docker-Volume.
This is most often used when importing `summary.csv`,
so `./summary.csv` is specified by default.
`-f` option can specify a local file.

```bash
    # copy from './summary.csv' to 'sytra-stocks:/root/data/summary.csv'
    sytra import 

    # copy from './foo.txt' to 'dvtest:/root/data/foo.txt'
    sytra import -f foo.txt -v dvtest
```

### backup
`backup` command creates an archive of the specified volume.
`-f` option can specify the name of the archive file, 
default file name is `backup.tar.gz`.

---
*Note: Used `tar` command is in container from `busybox`.*

---

```bash
    # create './backup.tar.gz'
    sytra backup 

    # create './123120.tar.gz' (based on today), target: 'dvtest'
    sytra backup -f $(date +%m%d%y).tar.gz -v dvtest
```

### extract
`extract` command create Docker-Volume by extraction `backup.tar.gz`.
If specified volume is exist,
after your confirmation, delete it and extract it from the archive.

```bash
    # extract './backup.tar.gz' to 'sytra-stocks'
    sytra extract

    # extract './123120.tar.gz' to 'dvtest'
    sytra extract -f 123120.tar.gz -v dvtest
```
