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

`./build.sh channelz-server` を実行して `channelz-server` を作る。
