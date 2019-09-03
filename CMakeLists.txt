cmake_minimum_required(VERSION 3.12)

project(grpc-memo C CXX)

set(LIBRARY_DIR ${PROJECT_SOURCE_DIR}/../_build)

find_package(gRPC REQUIRED)
find_package(CLI11 REQUIRED)

# set(_GRPC_GRPCPP_UNSECURE gRPC::grpc++_unsecure)
set(_GRPC_GRPCPP gRPC::grpc++)
set(_GRPC_GRPCPP_CHANNELZ gRPC::grpcpp_channelz)
if (APPLE)
  set(_GRPC_GRPCPP_REFLECTION -Wl,-force_load gRPC::grpc++_reflection)
  set(_GRPC_GRPCPP_CHANNELZ -Wl,-force_load gRPC::grpcpp_channelz)
else()
  set(_GRPC_GRPCPP_REFLECTION -Wl,--whole-archive gRPC::grpc++_reflection -Wl,--no-whole-archive)
  set(_GRPC_GRPCPP_CHANNELZ -Wl,--whole-archive gRPC::grpcpp_channelz -Wl,--no-whole-archive)
endif()
set(_GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:gRPC::grpc_cpp_plugin>)
set(_PROTOBUF_PROTOC $<TARGET_FILE:protobuf::protoc>)
set(_CLI11_CLI11 CLI11::CLI11)

get_filename_component(HELLOWORLD_PROTO "./proto/helloworld.proto" ABSOLUTE)
get_filename_component(HELLOWORLD_PROTO_PATH "${HELLOWORLD_PROTO}" PATH)

# Generated sources
set(HELLOWORLD_PROTO_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/proto/helloworld.pb.cc" "${CMAKE_CURRENT_BINARY_DIR}/proto/helloworld.grpc.pb.cc")
set(HELLOWORLD_PROTO_HEADERS "${CMAKE_CURRENT_BINARY_DIR}/proto/helloworld.pb.h" "${CMAKE_CURRENT_BINARY_DIR}/proto/helloworld.grpc.pb.h")

file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/proto")
add_custom_command(
  OUTPUT
    ${HELLOWORLD_PROTO_SOURCES}
    ${HELLOWORLD_PROTO_HEADERS}
  COMMAND
    ${_PROTOBUF_PROTOC}
  ARGS
    --grpc_out "${CMAKE_CURRENT_BINARY_DIR}/proto"
    --cpp_out "${CMAKE_CURRENT_BINARY_DIR}/proto"
    -I "${HELLOWORLD_PROTO_PATH}"
    --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
    "${HELLOWORLD_PROTO}"
  DEPENDS
    "${HELLOWORLD_PROTO}")

# channelz のテスト
add_executable(channelz-server ${PROJECT_SOURCE_DIR}/channelz/server.cpp ${HELLOWORLD_PROTO_SOURCES})
target_include_directories(channelz-server PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/proto")
set_target_properties(channelz-server PROPERTIES CXX_STANDARD 17 C_STANDARD 99)

if (ENABLE_TSAN)
  # tsan
  set_target_properties(channelz-server PROPERTIES
    COMPILE_OPTIONS "-g;-fsanitize=thread"
    LINK_OPTIONS    "-g;-fsanitize=thread"
    INTERFACE_LINK_OPTIONS    "-g;-fsanitize=thread")
endif()

if (ENABLE_ASAN)
  # asan
  set_target_properties(channelz-server PROPERTIES
    COMPILE_FLAGS "-g;-fsanitize=address;-fno-omit-frame-pointer"
    LINK_OPTIONS  "-g;-fsanitize=address;-fno-omit-frame-pointer"
    INTERFACE_LINK_OPTIONS  "-g;-fsanitize=address;-fno-omit-frame-pointer")
endif()

target_link_libraries(channelz-server
  ${_GRPC_GRPCPP}
  ${_GRPC_GRPCPP_REFLECTION}
  ${_GRPC_GRPCPP_CHANNELZ}
  ${_PROTOBUF_LIBPROTOBUF}
  ${_CLI11_CLI11})
