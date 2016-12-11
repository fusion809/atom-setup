#!/usr/bin/env bash

# Halt on errors
set -e
set -x

# Check dependencies
which wget >/dev/null 2>&1 || ( printf "wget missing" && exit 1 )
which grep >/dev/null 2>&1 || ( printf "grep missing" && exit 1 )
which sed >/dev/null 2>&1 || ( printf "sed missing" && exit 1 )
which cut >/dev/null 2>&1 || ( printf "cut missing" && exit 1 )

APP=atom
DLD=$(wget -q "https://api.github.com/repos/atom/atom/releases/latest"  -O - | grep -E "https.*atom-amd64.tar.gz" | cut -d '"' -f4)
ATOM_VERSION=$(printf $DLD | cut -d '/' -f 8 | sed 's/v//g')
if [[ -f "$HOME/.local/bin/$APP-$ATOM_VERSION*-$ARCH.AppImage" ]]; then
  printf "The latest version of Atom is presently available on this system!" && exit 1
fi

cd /tmp
wget -c $DLD
tar zxvf atom*tar.gz

mkdir -p AppDir/usr/bin
cp -r atom-*/* AppDir/usr/bin
cd AppDir
find . -name atom.png -exec cp {} atom.png \;
cat > atom.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Atom
Icon=atom
Exec=atom %u
Categories=Development;TextEditor;GTK;
MimeType=application/javascript;application/json;application/x-desktop;application/x-httpd-eruby;application/x-httpd-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/x-ruby;application/x-bash;application/x-csh;application/x-sh;application/x-zsh;application/x-shellscript;application/x-sql;application/x-tcl;application/xhtml+xml;application/xml;application/xml-dtd;application/xslt+xml;text/coffeescript;text/css;text/html;text/plain;text/xml;text/xml-dtd;text/x-bash;text/x-c++;text/x-c++hdr;text/x-c++src;text/x-c;text/x-chdr;text/x-csh;text/x-csrc;text/x-dsrc;text/x-diff;text/x-go;text/x-java;text/x-java-source;text/x-makefile;text/x-markdown;text/x-objc;text/x-perl;text/x-php;text/x-python;text/x-ruby;text/x-sh;text/x-zsh;text/yaml;inode/directory;
Comment=The hackable text editor for the 21st century.
EOF

if ! [[ -d $HOME/.local/share/applications ]]; then
  mkdir -p $HOME/.local/share/applications
fi
if ! [[ -d $HOME/.local/share/icons ]]; then
  mkdir -p $HOME/.local/share/icons
fi
cp atom.desktop $HOME/.local/share/applications/appimage-atom.desktop
cp atom.png $HOME/.local/share/icons
( cd usr/bin && ln -sf resources/app/apm/bin/apm apm )
curl -OL "https://github.com/probonopd/AppImageKit/releases/download/5/AppRun" # (64-bit)
chmod a+x ./AppRun
find . -type f -executable -exec strip {} \;

GLIBC_NEEDED=$(find . -type f -executable -exec strings {} \; | grep ^GLIBC_2 | sed s/GLIBC_//g | sort --version-sort | uniq | tail -n 1)
VERSION=${ATOM_VERSION}.glibc$GLIBC_NEEDED
printf "VERSION is $VERSION\n"

cd ..

ARCH=$(uname -m)
if [[ "$ARCH" = "x86_64" ]] ; then
	APPIMAGE=$APP"-"$VERSION"-x86_64.AppImage"
fi
if [[ "$ARCH" = "i686" ]] ; then
	APPIMAGE=$APP"-"$VERSION"-i386.AppImage"
fi

mkdir -p out

rm -f out/*.AppImage || true

curl -sL "https://github.com/probonopd/AppImageKit/releases/download/6/AppImageAssistant_6-x86_64.AppImage" > AppImageAssistant
chmod a+x AppImageAssistant
./AppImageAssistant ./AppDir/ out/$APP"-"$VERSION"-"$ARCH".AppImage"
chmod +x out/$APP"-"$VERSION"-"$ARCH".AppImage"
if ! [[ -d $HOME/.local/bin ]]; then
  mkdir -p $HOME/.local/bin
fi
cp out/*AppImage $HOME/.local/bin

sed -i -e "s|Exec=atom|Exec=$HOME/.local/bin/$APP-$VERSION-$ARCH.AppImage|g" $HOME/.local/share/applications/appimage-atom.desktop
chmod +x $HOME/.local/share/applications/appimage-atom.desktop
