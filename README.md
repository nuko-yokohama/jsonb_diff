# jsonb_diff
2つのjsonb文書の差分を表示するSQL関数。

## SQL関数形式

```
diff_jsonb(lj jsonb, rj jsonb)
```
### 引数

* lj, rj JSONB型のデータ

### 返却値

* diff 行型

diff行型は以下のような列を持ちます。

|列名|型|内容|
|:--|:--|:--|
|kind|text|差分の種別。aは追加、uは更新、dは削除を示す。|
|left_path|text|差分箇所のパス文字列(jsonbのパス文字列)|
|left_schema|jsonb|差分箇所のスキーマを示すJSONBデータ|
|right_path|text|差分箇所のパス文字列(jsonbのパス文字列)|
|right_schema|jsonb|差分箇所のスキーマを示すJSONBデータ|

## 使用例

```
jsonb_diff=# SELECT * FROM diff_jsonb('{"id":1, "name":"foo", "data":"foo", "col":1}', '{"id":1, "data":"bar", "val":1}');
  kind  | left_path |                                  left_schema                                  | right_path |                       right_schema

--------+-----------+-------------------------------------------------------------------------------+------------+-----------------------------------------------------------
 update | ->'data'  | {"string": "foo"}                                                             | ->'data'   | {"string": "bar"}
 update |           | [{"id": "number"}, {"col": "number"}, {"data": "string"}, {"name": "string"}] |            | [{"id": "number"}, {"val": "number"}, {"data": "string"}]
 delete | ->'name'  | {"string": "foo"}                                                             |            |
 append |           |                                                                               | ->'val'    | {"number": 1}
 delete | ->'col'   | {"number": 1}                                                                 |            |
(5 rows)

jsonb_diff=#
```
## TODO

* extension化
* リグレッションテストの作成
* pl/pgsqlで作っているので、性能面での懸念がある。（ただ、C言語等での作り直しはするつもりはない）

