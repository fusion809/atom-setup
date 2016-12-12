#!/usr/bin/env bash

# Halt on errors
set -e
set -x

# Check dependencies
which wget >/dev/null 2>&1 || ( printf '\e[1;31m%-6s\e[m' "wget missing" && exit 1 )
which grep >/dev/null 2>&1 || ( printf '\e[1;31m%-6s\e[m' "grep missing" && exit 1 )
which sed >/dev/null 2>&1 || ( printf '\e[1;31m%-6s\e[m' "sed missing" && exit 1 )
which cut >/dev/null 2>&1 || ( printf '\e[1;31m%-6s\e[m' "cut missing" && exit 1 )
which mksquashfs >/dev/null 2>&1 || ( printf '\e[1;31m%-6s\e[m' "mksquashfs missing" && exit 1 )

printf '\e[1;32m%-6s\e[m' "Welcome to the Atom AppImage builder and installer! If you experience a bug please report it at our bug tracker: https://github.com/fusion809/atom-setup/issues.\n"

# Check architecture
ARCH=$(uname -m)
if ! [[ $ARCH == "x86_64" ]]; then
  printf '\e[1;31m%-6s\e[m' "Ah, buddy this script won't work on systems other than x86_64 and this script has detected you are running on a $ARCH system. So this script will exit. If this is an error on the part of this script please report it at https://github.com/fusion809/atom-setup/issues/.\n" && exit 1
fi

# appname
APP=atom

# Download URL
DLD=$(wget -q "https://api.github.com/repos/atom/atom/releases/latest"  -O - | grep -E "https.*atom-amd64.tar.gz" | cut -d '"' -f4)

# Atom Version
ATOM_VERSION=$(printf $DLD | cut -d '/' -f 8 | sed 's/v//g')
printf '\e[1;34m%-6s\e[m' "This script has determined the latest available stable release of Atom to be $ATOM_VERSION. If this is wrong please report this as this is a bug!\n"

if [[ -f "$HOME/.local/bin/$APP-$ATOM_VERSION.glibc2.14-$ARCH.AppImage" ]]; then
  printf '\e[1;32m%-6s\e[m' "The latest version of Atom is presently available on this system, so this script will exit.\n" && exit 1
fi

# Work in /tmp
cd /tmp
# Download tarball
wget -c $DLD
# Extract its contents
tar zxf atom*tar.gz

# Make AppDir and its binary subdirectory
mkdir -p AppDir/usr/bin

# Copy Atom tarball contents across
cp -r atom-*/* AppDir/usr/bin

# Enter the AppDir directory
cd AppDir

# Move icon to top-level directory
find . -name atom.png -exec cp {} atom.png \;

# Create destop config file
cat > atom.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Atom
Icon=atom
Exec=atom %u
Categories=Development;TextEditor;GTK;
MimeType=application/javascript;application/json;application/x-desktop;application/x-httpd-eruby;application/x-httpd-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/x-ruby;application/x-bash;application/x-csh;application/x-sh;application/x-zsh;application/x-shellscript;application/x-sql;application/x-tcl;application/xhtml+xml;application/xml;application/xml-dtd;application/xslt+xml;text/coffeescript;text/css;text/html;text/plain;text/xml;text/xml-dtd;text/x-bash;text/x-c++;text/x-c++hdr;text/x-c++src;text/x-c;text/x-chdr;text/x-csh;text/x-csrc;text/x-dsrc;text/x-diff;text/x-go;text/x-java;text/x-java-source;text/x-makefile;text/x-markdown;text/x-objc;text/x-perl;text/x-php;text/x-python;text/x-ruby;text/x-sh;text/x-zsh;text/yaml;inode/directory;
Comment=The hackable text editor for the 21st Century.
EOF

# Add a symlink so that the atom and apm executables are available from the same folder
( cd usr/bin && ln -sf resources/app/apm/bin/apm apm )

cd usr/bin
# Remove unneeded files
find . \
  -name "*.md" -exec rm {} \; \
  -or -name "*.html" -exec rm {} \; \
  -or -name "*.bat" -exec rm {} \; \
  -or -name "*.cmd" -exec rm {} \; \
  -or -name "LICENSE" -exec rm {} \; \
  -or -name "*akefile*" -exec rm {} \; \
  -or -name "*.markdown" -exec rm {} \; \
  -or -name "*.txt" -exec rm {} \; \
  -or -name "*.png" -exec rm {} \; \
  -or -name "*.py" -exec rm {} \;
cd -

# Download AppRun
curl -OL "https://github.com/probonopd/AppImageKit/releases/download/5/AppRun" # (64-bit)
chmod a+x ./AppRun

# Strip unnecessary binaries, which reduces the size of the AppImage by 2 MB.
find . -type f -executable -exec strip {} \;

# Determine the minimum glibc version needed
GLIBC_NEEDED=$(find . -type f -executable -exec strings {} \; | grep ^GLIBC_2 | sed s/GLIBC_//g | sort --version-sort | uniq | tail -n 1)

# Generate version string used in the AppImage's filename
VERSION=${ATOM_VERSION}.glibc$GLIBC_NEEDED

# Print version string
printf "VERSION is $VERSION\n"

# cd out of AppDir
cd ..

# create out directory
mkdir -p out

# Delete any existing AppImages
rm -f out/*.AppImage || true

# Download AppImageAssistant
curl -sL "https://github.com/probonopd/AppImageKit/releases/download/6/AppImageAssistant_6-x86_64.AppImage" > AppImageAssistant

# Fix perms
chmod a+x AppImageAssistant

# Build AppImage
./AppImageAssistant ./AppDir/ out/$APP"-"$VERSION"-"$ARCH".AppImage" || printf "Building the AppImage failed. Please check your SquashFS setup."

# Set perms on AppImage
chmod +x out/$APP"-"$VERSION"-"$ARCH".AppImage"

# Move AppImage to $HOME/.local/bin
printf '\e[1;34m%-6s\e[m' "Moving AppImage to $HOME/.local/bin\n"
if ! [[ -d $HOME/.local/bin ]]; then
  mkdir -p $HOME/.local/bin
fi
# delete previous Atom AppImages
rm $HOME/.local/bin/$APP*.AppImage
cp out/*AppImage $HOME/.local/bin

# Install desktop config file and icon
printf '\e[1;34m%-6s\e[m' "Installing desktop configuration file and icon to $HOME/.local/share"
if ! [[ -d $HOME/.local/share/applications ]]; then
  mkdir -p $HOME/.local/share/applications
fi
if ! [[ -d $HOME/.local/share/icons ]]; then
  mkdir -p $HOME/.local/share/icons
fi
cp AppDir/atom.desktop $HOME/.local/share/applications/appimage-atom.desktop
cp AppDir/atom.png $HOME/.local/share/icons
sed -i -e "s|Exec=atom|Exec=$HOME/.local/bin/$APP-$VERSION-$ARCH.AppImage|g" $HOME/.local/share/applications/appimage-atom.desktop
chmod +x $HOME/.local/share/applications/appimage-atom.desktop

# Remove AppDir
rm -rf /tmp/AppDir
