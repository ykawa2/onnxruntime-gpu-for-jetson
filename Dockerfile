ARG L4T_VERSION

FROM ${L4T_VERSION}

ARG ONNXRUNTIME_REPO=https://github.com/microsoft/onnxruntime
ARG ONNXRUNTIME_COMMIT=v1.16.3
ARG BUILD_CONFIG=Release
ARG CMAKE_VERSION=3.28.1
ARG CPU_ARCHITECTURE=aarch64
ARG CUDA_ARCHITECTURES=70;75;80;86;87

ENV PATH=${PATH}:/workspace/cmake/bin

# set up cmake
RUN apt-get update \
    && apt-get remove -y cmake \
    && rm -rf /usr/local/bin/cmake \
    && apt-get install -y wget\
    && mkdir -p /workspace/cmake /output \
    && cd /workspace \
    && wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${CPU_ARCHITECTURE}.tar.gz  \
    && tar zxf cmake-${CMAKE_VERSION}-linux-${CPU_ARCHITECTURE}.tar.gz --strip-components=1 -C /workspace/cmake

# clone onnxruntime repository
RUN apt-get install -y patch \
    && git clone ${ONNXRUNTIME_REPO} /workspace/onnxruntime

# build onnxruntime
RUN cd /workspace/onnxruntime \
    && git checkout ${ONNXRUNTIME_COMMIT} \
    && /bin/bash build.sh \
    --parallel \
    --build_shared_lib \
    --build_wheel \
    --allow_running_as_root \
    --cuda_home /usr/local/cuda \
    --cudnn_home /usr/lib/${CPU_ARCHITECTURE}-linux-gnu/ \
    --use_tensorrt \
    --tensorrt_home /usr/lib/${CPU_ARCHITECTURE}-linux-gnu/ \
    --config ${BUILD_CONFIG} \
    --skip_tests \
    --cmake_extra_defines CMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} \
    onnxruntime_BUILD_UNIT_TESTS=OFF

RUN export ONNXRUNTIME_VERSION=$(cat /workspace/onnxruntime/VERSION_NUMBER) \
    && cd /workspace/onnxruntime \
    && BINARY_DIR=build \
    ARTIFACT_NAME=onnxruntime-linux-${CPU_ARCHITECTURE}-gpu-${ONNXRUNTIME_VERSION} \
    LIB_NAME=libonnxruntime.so \
    BUILD_CONFIG=Linux/${BUILD_CONFIG} \
    SOURCE_DIR=/workspace/onnxruntime \
    COMMIT_ID=$(git rev-parse HEAD) \
    tools/ci_build/github/linux/copy_strip_binary.sh \
    && cd /workspace/onnxruntime/build/onnxruntime-linux-${CPU_ARCHITECTURE}-gpu-${ONNXRUNTIME_VERSION}/lib/ \
    && ln -s libonnxruntime.so libonnxruntime.so.${ONNXRUNTIME_VERSION} \
    && cp -r /workspace/onnxruntime/build/onnxruntime-linux-${CPU_ARCHITECTURE}-gpu-${ONNXRUNTIME_VERSION} /output

RUN cd /workspace/onnxruntime/build/Linux/${BUILD_CONFIG}/dist/ \
    && pip install onnxruntime_gpu-*.whl \
    && cp onnxruntime_gpu-*.whl /output

ENV SHELL=/bin/bash

CMD ["/bin/bash"]
