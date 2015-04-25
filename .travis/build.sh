#!/bin/bash
set -ex

case "$BUILD_ARCH" in
32bit)
    binary=rsqueak
    sudo i386 chroot "$chroot" sh -c "
    cd $PWD &&
    pypy .build/build.py"
    cp rsqueak* rsqueak-x86-Linux-jit-$TRAVIS_COMMIT || true
    exitcode=$?
    ;;
64bit)
    binary=rsqueak-64
    python .build/build.py
    cp rsqueak* rsqueak-x86_64-Linux-jit-$TRAVIS_COMMIT || true
    exitcode=$?
    ;;
*) exit 0 ;;
esac

if [ $exitcode -eq 0 ]; then
    if [ "$TRAVIS_BRANCH" == "master" ]; then
        if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
            curl -T rsqueak-x86* http://www.lively-kernel.org/babelsberg/RSqueak/
            cp rsqueak-x86* rsqueak-linux-latest
            curl -T rsqueak-linux-latest http://www.lively-kernel.org/babelsberg/RSqueak/
	fi
    fi
    sudo rm -rf .build/pypy/rpython/_cache
    if [ yes == "$EXECUTE_JITTESTS" ]; then
       case "$BUILD_ARCH" in
           32bit)
               sudo i386 chroot "$chroot" sh -c "
                cd $PWD &&
                echo \$(pwd) &&
                ls &&
                python .build/jittests.py"
               exitcode=$?
               ;;
           64bit)
	       pypy .build/jittests.py
               exitcode=$?
               ;;
           *)
               exitcode=0
               ;;
       esac
    fi
else
    exit $exitcode
fi
