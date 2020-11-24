# 環境構築
## 前提
適宜追加  
- `iam:PassRole`ポリシーが適用されたIAMユーザを使用すること
- `aws`コマンドが使用できること

## 目次
1. パイプライン作成
2. 必要資材を格納
3. パイプライン確認
   1. master
   2. production

## 1. CI/CDパイプライン作成
まずはこのリポジトリを任意のディレクトリにクローンします。  

```
export CLONEDIR=`pwd`
git clone https://github.com/cnc4e/cloudformation-cicd.git
```

以下図のCI/CDパイプラインを作成します。
図  
クローンしたディレクトリ内のテンプレートを使い、CloudFormationスタックを作成します。  
CodeCommitのリポジトリのmasterブランチをソースとするパイプラインと、CodeCommitリポジトリのproductionブランチをソースとするパイプラインの2種類が作成されます。  
作成する方法はAWS CLIまたはAWSコンソールどちらでも構いません。以下はコマンドでCloudFormationスタックを作成する場合の手順です。  

```
aws cloudformation create-stack --stack-name Cloudformation-cicd-master --template-body file://$CLONEDIR/cloudformation-cicd/cfn-template/pipeline-master.yml --capabilities CAPABILITY_NAMED_IAM

aws cloudformation create-stack --stack-name Cloudformation-cicd-production --template-body file://$CLONEDIR/cloudformation-cicd/cfn-template/pipeline-production.yml --capabilities CAPABILITY_NAMED_IAM
```

CI/CDパイプラインが作成されているか確認します。以下の手順はAWSコンソールを使用してください。    
- サービス > CloudFormation > スタック で`Cloudformation-cicd-master`及び`Cloudformation-cicd-production`スタックのステータスが`CREATE_COMPLETE`になっていることを確認
- サービス > CodePipeline > パイプライン で`Cloudformation-cicd-master`及び`Cloudformation-cicd-production`パイプラインが作成されていることを確認（この時点ではパイプライン内のSourceアクションは失敗していて構いません）
- サービス > CodeBuild > ビルドプロジェクト で`Cfn-lint-master`、`Cfn-guard-master`、`Cfn-lint-production`、`Cfn-guard-production`プロジェクトが作成されていることを確認
- サービス > CodeCommit > リポジトリ で`CloudFormationTemplate`リポジトリが作成されていることを確認

これでCI/CDパイプラインが作成されました。ただし今のままでは必要なファイルが存在していないため動作しません。次のステップでは必要なファイルをCodeCommitのリポジトリに格納します。  

## 2. 必要資材を格納
作成したCI/CDパイプラインを動作させるためには、以下のファイルをCodeCommitのリポジトリに格納する必要があります。  
- CodeBuildで使用するbuildspec（Cfn-lint用）
- CodeBuildで使用するbuildspec（CloudFormationGuard用）
- CloudFormationGuardで使用するポリシー
- 実際にデプロイしたいCloudFormationテンプレート

最初にクローンしたディレクトリ内に、それぞれのファイルのサンプルを用意しています。これらのファイルをコピーし、CodeCommitのリポジトリに格納します。  
まずディレクトリを移動します。  
```
cd $CLONEDIR
```

その後`接続のステップ`（サービス > CodeCommit > リポジトリ > `CloudFormationTemplate`）に書かれた手順を実行し、CodeCommitのリポジトリをクローンしてください。クローンしたディレクトリは空の状態です。  

今クローンしたディレクトリに必要資材をコピーします。  
```
cp $CLONEDIR/cloudformation-cicd/cfn-lint/* $CLONEDIR/CloudFormationTemplate/
cp $CLONEDIR/cloudformation-cicd/cloudformation-guard/* $CLONEDIR/CloudFormationTemplate/
```

CodeCommitのリポジトリに格納します。  
```
cd $CLONEDIR/CloudFormationTemplate
git add .
git commit -m "init"
git push
# プッシュ時のユーザ名/パスワードは、CodeCommitのリポジトリクローン時のものと同じです
```

CodeCommitのリポジトリに格納されているか確認します。以下の手順はAWSコンソールを使用してください。     
- サービス > CodeCommit > リポジトリ > `CloudFormationTemplate`リポジトリ で以下のファイルが存在していることを確認
  - `buildspec-cfn-lint.yml`
  - `buildspec-cfn-guard.yml`
  - `cfn_guard_ruleset_example`
  - `cfn_template_file_example.yaml`

必要資材を格納したため、これでCI/CDパイプラインが動作します。次のステップでは、記法チェックやポリシーチェックが行われ、CloudFormationテンプレートがデプロイされているかどうか確認します。

## 3. パイプライン確認
今回作成したパイプラインは以下の動作をします。
- CloudFormationテンプレートを含む必要資材をCodeCommitから取得
- Cfn-lintを使用した記法チェック
- CloudFormation-guardを使用したポリシーチェック
- チェックに合格したCloudFormationテンプレートをデプロイ

#### master
AWSコンソールで、サービス > CodePipeline > パイプライン > `Cloudformation-cicd-master`パイプライン を表示します。すべての項目をパスし、CloudFormationテンプレートがデプロイされるまで5分～10分程度かかります。最後の`Release`アクションをパスしたら、以下を確認します。  
- テンプレート記載のリソースがデプロイされていること
- デプロイされたリソースのタグが`env:master`であること

#### production
masterブランチをproductionブランチにマージすると、`Cloudformation-cicd-production`パイプラインが動作し始めます。つまり、マージ操作をすることで記法チェックやポリシーチェックを行った上で本番環境へのデプロイが行われます。  

まずはCodeCommitにproductionブランチをプッシュします。この際、CloudFormationテンプレートは削除しておきます。（masterブランチからマージされるテンプレートをデプロイさせるため）
```
git checkout -b production
rm $CLONEDIR/CloudFormationTemplate/cfn_template_file_example.yaml
git add .
git commit -m "init"
git push
# プッシュ時のユーザ名/パスワードは、CodeCommitのリポジトリクローン時のものと同じです
```

続いてAWSコンソールで、サービス > CodeCommit > リポジトリ > `CloudFormationTemplate` > プルリクエスト を表示します。`プルリクエストの作成`より、以下の内容でプルリクエストを作成します。
- 

AWSコンソールで、先ほど作成したプルリクエストをマージします。  

AWSコンソールで、サービス > CodePipeline > パイプライン > `Cloudformation-cicd-production`パイプライン を表示します。すべての項目をパスし、CloudFormationテンプレートがデプロイされるまで5分～10分程度かかります。最後の`Release`アクションをパスしたら、以下を確認します。  
- テンプレート記載のリソースがデプロイされていること
- デプロイされたリソースのタグが`env:production`であること

## 4. パイプライン削除

```
# パイプラインからデプロイされたスタックを削除
aws cloudformation delete-stack --stack-name CloudFormationCICD-master
aws cloudformation delete-stack --stack-name CloudFormationCICD-production
# パイプラインのスタックを削除
aws cloudformation delete-stack --stack-name Cloudformation-cicd-master
aws cloudformation delete-stack --stack-name Cloudformation-cicd-production
```

