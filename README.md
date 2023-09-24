# メール配信システム

## 構成

## Commands

```bash
# 初期データの登録
aws dynamodb batch-write-item \
  --request-items file://data/mailaddress_items.json

# メール本文のアップロード
aws s3 cp data/example.txt s3://mailbody-asjdfajlsa/

```

## memo

## TODO
