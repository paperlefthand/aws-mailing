# メール配信システム

## 仕様

- 配信先アドレスをテーブルに登録
- テキストファイルをS3バケットにuploadすると,登録した配信先にメール配信
- テキストファイルの[サンプル](./data/example.txt). 1行目がタイトル,2行目以降が本文
- 配信に失敗した(bounceが返ってきた)アドレスはテーブルでステータスを更新

## 構成図

![alt](./diagrams/arch.drawio.svg)

## デプロイ

```sh
# 予め"dev"プロファイルを設定
cd terraform 
terraform fmt
tflint
terraform plan --var aws_profile=dev
terraform apply --var aws_profile=dev
```

## 実行準備

<!-- TODO terraform化 -->
- Lamnda`bounceReceive`にSNSトリガーを追加
- `terraform.tfvars`で指定したメールアドレスをSESでID検証(Email Address Verification Requestメールが届く)
- 初期データの登録

  ```sh
  aws --profile dev dynamodb batch-write-item \
    --request-items file://data/mailaddress_items.json
  ```

## 実行手順

- メール本文のアップロード

  ```sh
  aws --profile dev s3 cp data/example.txt s3://mailbody-xxx/
  ```

## 関数の更新

- planでzip化
- cliでupload
