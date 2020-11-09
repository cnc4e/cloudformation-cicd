# CloudFormationCICD
# 図
![cloudformation-cicd-fix](/uploads/a0bae86fe17165b48e41a1a82ff06777/cloudformation-cicd-fix.png)

# 手順
1. `./terraform`でterraformを実行
2. `./cfn-templates`の中身を1で作成したCodeCommitリポジトリへプッシュ
3. リポジトリに変更がある度に以下が行われる  
  - テンプレートのリンティング
  - `.taskcat.yml`で指定したパラメータでCloudFormationスタックを作成
    - テスト用スタックのため、実際に作成され直ちに削除される。スタック作成可能か確認する
  - テンプレートで指定したパラメータでCloudFormationスタックを作成