if [[ "$target_platform" == "osx-64" ]]; then
    export CONDA_BUILD_SYSROOT_BACKUP=${CONDA_BUILD_SYSROOT}
    conda install -p $BUILD_PREFIX --quiet --yes clangxx_osx-64=${cxx_compiler_version}
    rm $BUILD_PREFIX/lib/libc++.dylib
    rm $BUILD_PREFIX/lib/libc++abi.dylib
    export CONDA_BUILD_SYSROOT=${CONDA_BUILD_SYSROOT_BACKUP}
    EXTRA_CMAKE_ARGS="-DDARWIN_osx_ARCHS=x86_64 -DCOMPILER_RT_ENABLE_IOS=Off -DCOMPILER_RT_HAS_APP_EXTENSION=off"
    EXTRA_CMAKE_ARGS="$EXTRA_CMAKE_ARGS -DDARWIN_macosx_CACHED_SYSROOT=${CONDA_BUILD_SYSROOT} -DCMAKE_LIBTOOL=$LIBTOOL"
    # https://bugs.llvm.org/show_bug.cgi?id=38959
    # https://bugs.llvm.org/show_bug.cgi?id=38958
    EXTRA_CMAKE_ARGS="$EXTRA_CMAKE_ARGS -DCOMPILER_RT_BUILD_XRAY=Off"
fi

# Prep build
cp -R "${PREFIX}/lib/cmake/llvm" "${PREFIX}/lib/cmake/modules/"

mkdir build
cd build

cmake \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_PREFIX_PATH:PATH="${PREFIX}" \
    -DCMAKE_INSTALL_PREFIX:PATH="${PREFIX}" \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH="${PREFIX}/lib" \
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH="${PREFIX}/lib" \
    -DCMAKE_MODULE_PATH:PATH="${PREFIX}/lib/cmake" \
    -DLLVM_CONFIG_PATH:PATH="${PREFIX}/bin/llvm-config" \
    -DPYTHON_EXECUTABLE:PATH="${BUILD_PREFIX}/bin/python" \
    -DCMAKE_LINKER="$LD" \
    ${EXTRA_CMAKE_ARGS} \
    "${SRC_DIR}"

# Build step
make -j$CPU_COUNT VERBOSE=1

# Install step
make install -j$CPU_COUNT

# Clean up after build
rm -rf "${PREFIX}/lib/cmake/modules"
