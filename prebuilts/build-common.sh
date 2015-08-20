# latest version of this file can be found at
# sso://googleplex-android/platform/external/lldb-utils
#
# inputs
# $PROJ - project name
# $VER - project version
# $1 - name of this file
#
# this file does the following:
#
# 1) define the following env vars
#    OS - linux|darwin|windows
#    USER - username
#    CORES - numer of cores (for parallel builds)
#    PATH (with appropriate compilers)
#    CFLAGS/CXXFLAGS/LDFLAGS
#    RD - root directory for source and object files
#    INSTALL - install directory/git repo root
#    SCRIPT_FILE - absolute path to the parent build script
#    SCRIPT_DIR - absolute path to the parent build script's directory
#    COMMON_FILE - absolute path to this file
# 2) create an empty tmp directory at /tmp/$PROJ-$USER
# 3) checkout the destination git repo to /tmp/prebuilts/$PROJ/$OS-x86/$VER
# 4) cd $RD

UNAME="$(uname)"
SCRATCH=/tmp
UPSTREAM=sso://googleplex-android/platform/prebuilts
case "$UNAME" in
Linux)
    OS='linux'
    INSTALL_VER=$VER
    ;;
Darwin)
    OS='darwin'
    OSX_MIN=10.8
    export CC=clang
    export CXX=$CC++
    export CFLAGS="$CFLAGS -mmacosx-version-min=$OSX_MIN"
    export CXXFLAGS="$CXXFLAGS -mmacosx-version-min=$OSX_MIN -stdlib=libc++"
    export LDFLAGS="$LDFLAGS -mmacosx-version-min=$OSX_MIN"
    INSTALL_VER=$VER
    ;;
*_NT-*)
    USER=$USERNAME
    OS='windows'
    CORES=$NUMBER_OF_PROCESSORS
    # VS2013 x64 Native Tools Command Prompt
    case "$MSVS" in
    2013)
        devenv() {
            cmd /c "${VS120COMNTOOLS}VsDevCmd.bat" '&' devenv.com "$@"
        }
        INSTALL_VER=${VER}_${MSVS}
        ;;
    *)
        # g++/make build
        export CC=x86_64-w64-mingw32-gcc
        export CXX=x86_64-w64-mingw32-g++
        export LD=x86_64-w64-mingw32-ld
        ;;
    esac
    ;;
*)
    exit 1
    ;;
esac

RD=$SCRATCH/$PROJ-$USER
INSTALL="$RD/install"

# OSX lacks a "realpath" bash command
realpath() {
    [[ "$1" == /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

SCRIPT_FILE=$(realpath "$0")
SCRIPT_DIR="$(dirname "$SCRIPT_FILE")"
COMMON_FILE="$SCRIPT_DIR/$1"

cd /tmp # windows can't delete if you're in the dir
rm -rf $RD
mkdir -p $INSTALL
mkdir -p $RD
cd $RD

# clone prebuilt gcc
case "$OS" in
linux)
    # can't get prebuilt clang working so we're using host clang-3.5 https://b/22748915
    #CLANG_DIR=$RD/clang
    #git clone $UPSTREAM/clang/linux-x86/host/3.6 $CLANG_DIR
    #export CC="$CLANG_DIR/bin/clang"
    #export CXX="$CC++"
    export CC=clang-3.5
    export CXX=clang++-3.5

    GCC_DIR=$RD/gcc
    git clone $UPSTREAM/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8 $GCC_DIR

    find "$GCC_DIR" -name x86_64-linux -exec ln -fns {} {}-gnu \;

    FLAGS+=(-fuse-ld=gold)
    FLAGS+=(--gcc-toolchain="$GCC_DIR")
    FLAGS+=(--sysroot "$GCC_DIR/sysroot")
    FLAGS+=(-B"$GCC_DIR/bin/x86_64-linux-")
    export CFLAGS="$CFLAGS ${FLAGS[*]}"
    export CXXFLAGS="$CXXFLAGS ${FLAGS[*]}"
    export LDFLAGS="$LDFLAGS -m64"
    ;;
esac

commit_and_push()
{
    BRANCH=studio-master-dev
    # check into a local git clone
    rm -rf $SCRATCH/prebuilts/$PROJ/
    mkdir -p $SCRATCH/prebuilts/$PROJ/
    cd $SCRATCH/prebuilts/$PROJ/
    git clone $UPSTREAM/$PROJ/$OS-x86 -b $BRANCH
    GIT_REPO="$SCRATCH/prebuilts/$PROJ/$OS-x86"
    cd $GIT_REPO
    rm -rf *
    mv $INSTALL/* $GIT_REPO
    cp $SCRIPT_FILE $GIT_REPO
    cp $COMMON_FILE $GIT_REPO

    git add .
    git commit -m "Adding binaries for $INSTALL_VER"

    # execute this command to upload
    #git push origin HEAD:refs/for/$BRANCH

    rm -rf $RD
}
