# atom-setup
This repository contains the `main.sh` script which will, if run, build an AppImage for Atom on your local system, install a desktop configuration file for it and an icon.

## One-Liner
To execute `main.sh` in one line (regardless of whether you have a copy of this repo locally) merely run:

```bash
bash -c "$(wget -cqO- https://github.com/fusion809/atom-setup/raw/master/main.sh)"
```

## Dependencies
In order to use this repo you only need the following programs to be installed:

* cut
* grep
* SquashFS
* sed
* wget
