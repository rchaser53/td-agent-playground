# renew-checker

td-agent から Elasticsearch へログを送信する Docker Compose のサンプル環境です。

指定した nginx アクセスログファイルの全データを td-agent 経由で Elasticsearch 7.10.2 に送信するスクリプトも含まれています。

## 構成

| サービス | バージョン | 接続先 |
| --- | --- | --- |
| Elasticsearch | 7.10.2 | http://localhost:9200 |
| Kibana | 7.10.2 | http://localhost:5601 |
| nginx | 1.27 | http://localhost:8080 |
| td-agent | 4.5.2 | Forward protocol: `24224/tcp`, `24224/udp` |

Fluentd の Forward 入力から送信されたログは、`td-agent-test-YYYY.MM.DD` 形式の Elasticsearch インデックスに保存されます。

nginx のアクセスログは、`nginx-access-YYYY.MM.DD` 形式の Elasticsearch インデックスに保存されます。

## OpenSearch からの変更点

- OpenSearch を Elasticsearch `7.10.2` に変更しました。
- OpenSearch Dashboards を Kibana `7.10.2` に変更しました。
- 出力プラグインを `fluent-plugin-opensearch` から `fluent-plugin-elasticsearch 4.3.3` に変更しました。
- Fluentd を td-agent の公式パッケージ `4.5.2-1` で動作する構成に変更しました。
- Elasticsearch 7.10.2 との互換性のため、Elasticsearch クライアント 7.17.9 と Faraday 1 系を使用しています。

## 前提条件

Docker と Docker Compose が利用できることを確認してください。

```bash
docker --version
docker compose version
```

## 起動

```bash
docker compose up -d --build
docker compose ps
```

`elasticsearch`、`kibana`、`fluentd` の 3 コンテナが起動していれば正常です。

ログを確認する場合:

```bash
docker compose logs elasticsearch
docker compose logs fluentd
docker compose logs nginx
docker compose logs kibana
```

## バージョン確認

Elasticsearch:

```bash
curl http://localhost:9200
```

td-agent:

```bash
docker compose exec fluentd dpkg-query -W -f='${Version}\n' td-agent
```

`4.5.2-1` と表示されれば td-agent のバージョン固定は成功です。

`service "fluentd" is not running` と表示された場合は、イメージを再ビルドして起動してください。

```bash
docker compose up -d --build fluentd
docker compose ps
docker compose logs fluentd
```

## nginx のアクセスログファイルを Elasticsearch に送信

ホスト上の nginx アクセスログファイルを指定して、その時点でファイルに存在する全行を送信します。

```bash
./scripts/send-nginx-log.sh /path/to/access.log
```

スクリプトは各行を Docker Compose の td-agent に渡します。td-agent は nginx 標準アクセスログ形式としてパースし、`nginx-access-YYYY.MM.DD` インデックスへ保存します。Mac 側に `fluent-cat` をインストールする必要はありません。

送信件数はスクリプト実行時に表示されます。バッファの flush を待ってから Elasticsearch 側を確認します。

```bash
curl 'http://localhost:9200/nginx-access-*/_count?pretty'
curl 'http://localhost:9200/nginx-access-*/_search?pretty&size=5'
```

インデックス一覧を確認する場合:

```bash
curl 'http://localhost:9200/_cat/indices/nginx-access-*?v'
```

Fluentd 側でパースエラーなどを確認する場合:

```bash
docker compose logs --tail=100 fluentd
```

> [!NOTE]
> Docker 版 nginx の `/var/log/nginx/access.log` は `/dev/stdout` へのシンボリックリンクです。そのため、このサンプルでは Fluentd の `in_tail` でコンテナの `access.log` を直接監視せず、指定された通常のログファイルを Forward 入力へ送信します。

## Fluentd からテストログを送信

```bash
echo '{"message":"Hello Elasticsearch"}' | \
  docker compose exec -T fluentd /opt/td-agent/bin/fluent-cat test.log
```

バッファは約 1 秒ごとに flush されます。数秒待ってからインデックスを確認します。

```bash
curl 'http://localhost:9200/_cat/indices?v'
```

`td-agent-test-YYYY.MM.DD` が表示されれば、Elasticsearch への送信に成功しています。

送信したログの確認:

```bash
curl 'http://localhost:9200/td-agent-test-*/_search?pretty'
```

検索結果の `_source` に、次のようなデータが含まれます。

```json
{
  "message": "Hello Elasticsearch",
  "fluentd_tag": "test.log"
}
```

## Kibana

ブラウザで http://localhost:5601 を開きます。

nginx ログを検索する場合は `nginx-access-*`、Forward 入力のログを検索する場合は `td-agent-test-*` を対象とする data view を作成してください。

## 停止

コンテナを停止・削除します。

```bash
docker compose down
```

Elasticsearch のデータやログ用ボリュームも削除する場合は、次を実行します。

```bash
docker compose down -v
```

## 最短の動作確認

```bash
docker compose up -d --build
curl http://localhost:9200

./scripts/send-nginx-log.sh /path/to/access.log

sleep 2
curl 'http://localhost:9200/_cat/indices/nginx-access-*?v'
curl 'http://localhost:9200/nginx-access-*/_count?pretty'
```
