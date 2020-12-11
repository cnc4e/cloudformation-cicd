# 目次

# 用語
## CodePipeline
### ステージ
1つまたは複数の[アクション](#アクション)をまとめたものです。  

### アクション
パイプライン中で実行されるタスクを定義したものです。  
ソース、ビルド、テスト、デプロイ、承認、呼び出しという6つのアクションタイプが存在し、アクションのカスタムができる他、それぞれに[アクションプロバイダ](#アクションプロバイダ)を統合できます。

### アクションプロバイダ
アクションに統合できるAWSサービス、またはパートナーサービスを指します。  
例えばソースアクションに`CodeCommit`や`GitHub`などを統合することができますし、デプロイアクションに`CodeDeploy`や`CloudFormation`などを統合することができます。統合されたアクションにパラメータを与えるだけで、パイプライン-サービス間の連携を簡単に取ることができます。

# CICDフローについて
作成するCICDパイプラインは主に以下のような流れを取ります。
1. CodeCommitにソースをPush
2. CodePipelineがキックされる
3. CodeBuildでソースのテストを実施
  - Cfn-lintによる文法チェック
  - Cfn-guardによるポリシーチェック
4. CloudFormationで環境にデプロイされる

今回は[ブランチ戦略](#ブランチ戦略について)に基づき、`master`と`production`という2つのブランチ・2つの環境を想定したサンプルになっています。CICDパイプラインが実際にどのような流れであるか、図示します。

![push](img/flow-push.drawio.png)  

![kick](img/flow-kick.drawio.png)  

![test](img/flow-test.drawio.png)  

![deploy](img/flow-deploy.drawio.png  )


# ブランチ戦略について
今回のリファレンスでは`GitLab-flow`を採用しています。なお、次の参考ページをまとめた内容です。[Introduction to GitLab Flow](https://docs.gitlab.com/ee/topics/gitlab_flow.html)  
ブランチ戦略は他にも`Git-flow`、`GitHub-flow`がありますが、ここでは割愛します。

## GitLab-flow
以下3種類のブランチを使い分ける戦略。通常の開発はmasterブランチをベースに行う。何らかの修正を加えた場合、masterブランチからfeatureブランチを作成し、修正が完了したらmasterにマージする。masterブランチで動作を確認したのち問題なければproductionブランチにマージします。(場合によってはproductionブランチの前にstagingブランチなどを設け、より本番に近い環境でテストしてからproductionブランチにマージしても良いです。)

- master
- production
- feature

この戦略は環境差異を含むレポジトリの管理に有効な戦略です。

# 作成されるリソース
今回のリファレンスでは、パイプラインと関連リソースをCloudFormationスタックで作成します。  
ブランチ問わず共通で使用するリソースは[pipeline-base.yml](../pipeline-template/pipeline-base.yml)で作成し、ブランチごとのリソースは[pipeline-template.yml](../pipeline-template/pipeline-template.yml)にパラメータを渡して作り分けます。  
以下は作成されるリソース一覧です。  

- 共通リソース  
  |リソース|説明|
  |-|-|
  |CodeCommit|環境にデプロイするCFnソースを配置するリポジトリ。パイプラインのトリガとなるソース置き場。サンプルでは`CloudFormationTemplate`という名前で作成する。|
  |IAMロール(CodeBuid用)|CodeBuild実行用ロール。サンプルでは`cfn-cicd-base-SERVICEROLEforCODEBUILD-<乱数>`という名前で作成する。|
  |IAMロール(CodePipeline用)|CodePipeline実行用ロール。サンプルでは`cfn-cicd-base-SERVICEROLEforCODEPIPELINE-<乱数>`という名前で作成する。|
  |IAMロール(CloudFormation用)|CloudFormation実行用ロール。サンプルでは`cfn-cicd-base-SERVICEROLEforCLOUDFORMATION-<乱数>`という名前で作成する。CodePipelineのReleaseアクションでCloudFormationを実行する際に使用する。|

- ブランチごとのリソース  
  |リソース|説明|
  |-|-|
  |S3バケット(CodeBuild用)|CodeBuildのキャッシュ用バケット。サンプルでは`cfn-cicd-<ブランチ名>-s3bucketforcodebuild-<乱数>`という名前で作成する。|
  |CodeBuild(cfnlint)|cfnlintを実行するCodeBuild。サンプルでは`Cfn-lint-<ブランチ名>`という名前で作成する。|
  |CodeBuild(cfnguard)|cfnguardを実行するCodeBuild。サンプルでは`Cfn-guard-<ブランチ名>`という名前で作成する。|
  |S3バケット(CodePipeline用)|CodePipeline用のバケット。ステージ間のデータ受け渡しに使用。サンプルでは`cfn-cicd-<ブランチ名>-s3bucketforcodepipeline-<乱数>`という名前で作成する。|
  |CodePipeline|CICDパイプライン。サンプルでは`cfn-cicd-<ブランチ名>`という名前で作成する。|