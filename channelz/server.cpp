#include <algorithm>
#include <chrono>
#include <cmath>
#include <iostream>
#include <memory>
#include <string>
#include <random>
#include <deque>
#include <thread>
#include <fstream>
#include <sstream>
#include <chrono>

#include <grpc/grpc.h>
#include <grpc++/grpc++.h>
#include <grpcpp/server.h>
#include <grpcpp/server_builder.h>
#include <grpcpp/server_context.h>
#include <grpcpp/security/server_credentials.h>
#include <grpcpp/ext/channelz_service_plugin.h>

#include <CLI/CLI.hpp>

#include "helloworld.grpc.pb.h"

class GreeterServiceImpl final : public helloworld::Greeter::Service {
  grpc::Status SayHello(grpc::ServerContext *context,
                        const helloworld::HelloRequest *request,
                        helloworld::HelloReply *reply) override {
    std::string prefix("Hello ");
    reply->set_message(prefix + request->name());
    return grpc::Status::OK;
  }
};

class GrpcServer final {
public:
  void Run(int port) {
    // channelz を有効にするおまじない
    ::grpc::channelz::experimental::InitChannelzService();

    std::string server_address("0.0.0.0:" + std::to_string(port));
    GreeterServiceImpl service;

    grpc::ServerBuilder builder;
    // 認証せずに指定されたアドレスを listen する
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());

    // channelz を有効にする
    builder.AddChannelArgument(GRPC_ARG_ENABLE_CHANNELZ, 1);
    builder.AddChannelArgument(GRPC_ARG_MAX_CHANNEL_TRACE_EVENT_MEMORY_PER_NODE, 1024);

    builder.RegisterService(&service);

    std::unique_ptr<grpc::Server> server(builder.BuildAndStart());
    std::cout << "gRPC Server listening on " << server_address << std::endl;

    server->Wait();
  }
};

static int run_grpc(int argc, char** argv) {
  CLI::App app("channelz-server");
  int port = 50051;

  app.add_option("--port", port, "ポート番号")->check(CLI::Range(0, 65535));

  try {
    app.parse(argc, argv);
  } catch (const CLI::ParseError &e) {
    return app.exit(e);
  }

  GrpcServer grpc_server;
  grpc_server.Run(port);
  return 0;
}

int main(int argc, char **argv) { return run_grpc(argc, argv); }
