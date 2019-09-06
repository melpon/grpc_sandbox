# gRPC の実験場

自分用の gRPC の実験場です。

- `./install_tools.sh`
  - gRPC を含め、ここで利用する依存ライブラリ全体を入れるスクリプト
- `docker-compose.yml`
  - Envoy や Grafana, InfluxDB あたりを docker-compose で動かす設定
- その他は CMake の設定や実際のソースコードだったりするけど、見れば大体分かるはず

## セットアップ

`./install_tools.sh` を叩く。

## Envoy の統計情報を Grafana で確認する

- `./build.sh channelz-server` を実行して `channelz-server` を作る。
- 別窓で `./build/channelz-server --port 50062` を実行する
- 別窓で `./build/channelz-server --port 50063` を実行する
- 別窓で `docker-compose up` を実行する
- `./grpc_cli ls localhost:50051` や `./grpc_cli call localhost:50051 SayHello 'name: "foo"'` などを何度か実行して正常に結果が返ってくることを確認する
- ブラウザで `localhost:3000` を開いて admin/admin で Grafana にログインしてダッシュボードで結果が見れるのを確認する
