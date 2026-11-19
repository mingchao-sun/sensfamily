# sensfamily — 感度分析（jamovi モジュール）

「未観測の交絡がどれほど強ければ回帰推定値が変わるか」に答える、線形回帰後の 2 つの事後ツール。 詳しい英語の説明は [README.md](README.md)、中国語の要約は [README.zh.md](README.zh.md) を参照してください。

## 分析（jamovi メニュー：Sensitivity > Regression）

| 分析 | 内容 |
|---|---|
| **欠落変数バイアス** | Cinelli と Hazlett (2020)：頑健性値、観測共変量をベンチマークにした境界、等高線図 |
| **係数の安定性** | Oster (2019)：δ、バイアス調整済み係数と境界 |

各分析の出力には「方法の説明」と「データと設定ガイド」があります。

エンジンは base R で書かれ、R パッケージ `sensemakr`、`robomit` および Stata コマンド `sensemakr`、`psacalc` と照合済みです。マッチング・重み付け推定の E 値と Rosenbaum バウンドは `matchfamily` にあります。サンプルデータ：`darfur.csv`。

## インストール
- **jamovi ライブラリ**：jamovi 右上のモジュールボタンから *jamovi library* を開き、検索してインストール（モジュール公開後）。
- **サイドロード**：`.jmo` ファイルをダウンロードし、同じメニューの *Install from file* から導入します。`.jmo` はビルドした OS、プロセッサ、jamovi のバージョンでのみ動作します。
- **ソースから**：R と `jmvtools` が必要です：`jmvtools::install(home = "C:/Program Files/jamovi 28.17.0.0")`（パスはお使いの jamovi に合わせてください）。

## 引用とライセンス
引用：Sun, M. *sensfamily* (jamovi module). https://github.com/mingchao-sun/sensfamily 。使用した手法の原論文（出力に記載）も併せて引用してください。

ライセンス：`DESCRIPTION` を参照（GPL）。第三者のコードとデータは `NOTICE` に記載。不具合や提案：https://github.com/mingchao-sun/sensfamily/issues
