FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    make cmake ninja-build wget perl automake libtool patch git
RUN mkdir /prefix && mkdir /source && mkdir /download

#new cmake
ARG CMAKE_VERSION=3.13
ARG CMAKE_VERSION_FULL=${CMAKE_VERSION}.4
RUN wget https://cmake.org/files/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION_FULL}-Linux-x86_64.tar.gz && tar -xzf cmake-${CMAKE_VERSION_FULL}-Linux-x86_64.tar.gz
ENV PATH="/cmake-${CMAKE_VERSION_FULL}-Linux-x86_64/bin:${PATH}"


RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:ubuntu-toolchain-r/test && apt-get update && apt-get install gcc-8 g++-8 -y
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 60 --slave /usr/bin/g++ g++ /usr/bin/g++-8 && \
update-alternatives --config gcc


# cmake toolchain
RUN printf "SET(CMAKE_SYSTEM_NAME Linux) \n\
SET(CMAKE_SYSTEM_VERSION 1) \n\
SET(CMAKE_C_COMPILER   gcc-8) \n\
SET(CMAKE_CXX_COMPILER g++-8) \n\
SET(CMAKE_CXX_FLAGS \"-std=c++17\") \n\
SET(CMAKE_AR gcc-ar-8 CACHE FILEPATH \"Archiver\") \n\
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER) \n\
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER) \n\
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER) \n\
" >> /prefix/toolchain.txt

# fmt
ARG FMT_VERSION=5.3.0
RUN wget https://github.com/fmtlib/fmt/archive/${FMT_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf ${FMT_VERSION}.tar.gz && cd fmt-${FMT_VERSION} && \
mkdir -p build && cd build && \
cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt -DCMAKE_INSTALL_PREFIX="/prefix" -GNinja .. && \
ninja install


# spdlog
ARG SPDLOG_VERSION=1.3.1
RUN wget https://github.com/gabime/spdlog/archive/v${SPDLOG_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf v${SPDLOG_VERSION}.tar.gz && cd spdlog-${SPDLOG_VERSION} && \
mkdir -p build && cd build && \
cmake -DBUILD_SHARED_LIBS=ON -DSPDLOG_BUILD_BENCH=OFF -DSPDLOG_BUILD_TESTS=OFF -DSPDLOG_FMT_EXTERNAL=ON -DSPDLOG_BUILD_EXAMPLES=OFF -DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/prefix" -GNinja .. && \
ninja install

#boost
ARG BOOST_VERSION_MAJOR=1
ARG BOOST_VERSION_MINOR=69
ARG BOOST_VERSION=${BOOST_VERSION_MAJOR}.${BOOST_VERSION_MINOR}.0
ARG BOOST_VERSION_STR=${BOOST_VERSION_MAJOR}_${BOOST_VERSION_MINOR}_0
RUN wget https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_STR}.tar.gz -P /download
RUN cd /download/ && tar -xzvf boost_${BOOST_VERSION_STR}.tar.gz && cd boost_${BOOST_VERSION_STR} && \
export CXX=g++-8 && export C=gcc-8 && \
./bootstrap.sh  --prefix="/prefix" &&  ./b2 --toolset=gcc-8 threading=multi link=shared variant=release address-model=64 stage   && \
./b2 install


# OpenSSL
ARG OPENSSL_VERSION=1_1_1b
RUN wget https://github.com/openssl/openssl/archive/OpenSSL_${OPENSSL_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf OpenSSL_${OPENSSL_VERSION}.tar.gz && cd openssl-OpenSSL_${OPENSSL_VERSION} && \
./Configure linux-generic64 shared --prefix="/prefix" && make install
RUN cd /download/ && rm * -rf

# proto
ARG PROTO_VERSION=3.6.1
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v${PROTO_VERSION}/protobuf-cpp-${PROTO_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf protobuf-cpp-${PROTO_VERSION}.tar.gz && cd protobuf-${PROTO_VERSION}/cmake && \
mkdir -p build && cd build && \
cmake -DBUILD_SHARED_LIBS=ON -Dprotobuf_BUILD_PROTOC_BINARIES=on -Dprotobuf_BUILD_EXAMPLES=off -Dprotobuf_BUILD_TESTS=off -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt -DCMAKE_INSTALL_PREFIX="/prefix" -GNinja .. && \
ninja install
RUN cd /download/ && rm * -rf



# gflags
ARG GFLAGS_VERSION=2.2.1
RUN wget https://github.com/gflags/gflags/archive/v${GFLAGS_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf v${GFLAGS_VERSION}.tar.gz && cd gflags-${GFLAGS_VERSION} && \
mkdir -p build && cd build && \
cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt -DCMAKE_INSTALL_PREFIX="/prefix" -GNinja .. && \
ninja install
RUN cd /download/ && rm * -rf

# gtest
ARG GTEST_VERSION=1.8.1
RUN wget https://github.com/google/googletest/archive/release-${GTEST_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf release-${GTEST_VERSION}.tar.gz && cd googletest-release-${GTEST_VERSION} && \
mkdir -p build && cd build && \
cmake -DBUILD_SHARED_LIBS=ON -DTHREADS_PTHREAD_ARG=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt -DCMAKE_INSTALL_PREFIX="/prefix" -GNinja .. && \
ninja install
RUN cd /download/ && rm * -rf

# gbench
ARG GBENCH_VERSION=1.4.1
RUN wget https://github.com/google/benchmark/archive/v${GBENCH_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf v${GBENCH_VERSION}.tar.gz && cd benchmark-${GBENCH_VERSION} && \
mkdir -p build && cd build && \
cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt -DCMAKE_INSTALL_PREFIX="/prefix" -GNinja .. && \
ninja install
RUN cd /download/ && rm * -rf

# c-ares
ARG CARES_VERSION=1_14_0
RUN wget https://github.com/c-ares/c-ares/archive/cares-${CARES_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf cares-${CARES_VERSION}.tar.gz && cd c-ares-cares-${CARES_VERSION} && \
mkdir -p build && cd build && \
cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt -DCMAKE_INSTALL_PREFIX="/prefix" -GNinja .. && \
ninja install

# zlib
ARG ZLIB_VERSION=1.2.11
RUN cd /download/ && git clone https://github.com/madler/zlib.git && cd zlib && git checkout v${ZLIB_VERSION}
RUN cd /download/zlib && mkdir -p build && cd build && cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="/prefix" .. && \
make && make install
RUN cd /download/ && rm * -rf

#grpc
ARG GRPC_VERSION=1.18.0
RUN wget https://github.com/grpc/grpc/archive/v${GRPC_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf v${GRPC_VERSION}.tar.gz && cd grpc-${GRPC_VERSION} && \
mkdir -p build && cd build && \
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/prefix/lib && cmake -DZLIB_ROOT_DIR="/prefix/lib" \
-DBUILD_SHARED_LIBS=ON \
-DgRPC_BUILD_CODEGEN=ON \
-DgRPC_BUILD_CSHARP_EXT=OFF \
-DgRPC_ZLIB_PROVIDER=package \
-DgRPC_PROTOBUF_PROVIDER=package \
-DgRPC_GFLAGS_PROVIDER=package \
-DgRPC_CARES_PROVIDER=package \
-DgRPC_SSL_PROVIDER=package \
-DgRPC_BENCHMARK_PROVIDER=package \
-DgRPC_BUILD_TESTS=OFF \
-DCMAKE_BUILD_TYPE=Release \
-Dgflags_DIR="/prefix/include" \
-DCMAKE_PREFIX_PATH="/prefix" \
-DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt \
-DCMAKE_INSTALL_PREFIX="/prefix" \
 -GNinja .. && \
ninja install
RUN cd /download/ && rm * -rf

# json
RUN wget https://github.com/nlohmann/json/releases/download/v3.5.0/json.hpp -P /prefix/include/nlohmann/

ARG CXXOPTS_VERSION=2.1.2
RUN wget https://github.com/jarro2783/cxxopts/archive/v${CXXOPTS_VERSION}.tar.gz -P /download
RUN cd /download/ && tar -xzvf v${CXXOPTS_VERSION}.tar.gz && cd cxxopts-${CXXOPTS_VERSION} && \
mkdir -p build && cd build && \
cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_TOOLCHAIN_FILE=/prefix/toolchain.txt -DCMAKE_INSTALL_PREFIX="/prefix" -GNinja .. && \
ninja install
RUN rm /download/* -rf



VOLUME /source


CMD cd /source/ && ./build.sh
