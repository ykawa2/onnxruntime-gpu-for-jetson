# ONNX Runtime GPU for Jetson
This repository contains the wheel files and build scripts for ONNX Runtime with GPU support on Jetson platforms.

## Build the Container
Modify the build arguments according to your environment.
```bash
docker build \
--build-arg L4T_VERSION=nvcr.io/nvidia/l4t-ml:r35.2.1-py3 \
--build-arg ONNXRUNTIME_REPO=https://github.com/microsoft/onnxruntime \
--build-arg ONNXRUNTIME_COMMIT=v1.16.3 \
--build-arg BUILD_CONFIG=Release \
--build-arg CMAKE_VERSION=3.28.1 \
--build-arg CPU_ARCHITECTURE=aarch64 \
--build-arg CUDA_ARCHITECTURES="70;72;75;80;86;87" \
-t onnx-builder \
-f Dockerfile .
```

## Check ONNX Providers
Add `--runtime nvidia` if necessary.
```bash
docker run --rm onnx-builder bash -c "python3 -c 'import onnxruntime; print(onnxruntime.get_available_providers())'"
```

## Check Outputs
To check the outputs, run:
```bash
docker run -it --rm onnx-builder bash
```
Then, inside the container:
```bash
cd /output
```

## Copy Wheel Files
Retrieve the wheel file from the `./export` directory.
```bash
docker run --rm -v $(pwd)/export:/export onnx-builder bash -c "cp /output/onnxruntime_gpu-*.whl /export"

sudo chown -R $(id -u):$(id -g) ./export
```

## Credits and References
This project is based upon the work shared by seddonm1: [GitHub Gist - seddonm1](https://gist.github.com/seddonm1/5927db05cb7ad38d98a22674fa82a4c6)
