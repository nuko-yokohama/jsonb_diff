# jsonb_diff
2つのjsonb文書の差分を表示するSQL関数。

## SQL関数形式

```
jsonb_diff(lj jsonb, rj jsonb)
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

例えば、以下の2つのJSONB文書（わかりやすくするため、jsonb_prettyで表示する）がある。

left側

```
jsonb_diff=# SELECT jsonb_pretty('{"id":1, "name":"foo", "data":"foo", "col":1, "arr":[1,"2",3,4] }');
    jsonb_pretty
--------------------
 {                 +
     "id": 1,      +
     "arr": [      +
         1,        +
         "2",      +
         3,        +
         4         +
     ],            +
     "col": 1,     +
     "data": "foo",+
     "name": "foo" +
 }
(1 row)
```

right側

```
jsonb_diff=# SELECT jsonb_pretty('{"id":1, "data":"bar", "val":1, "arr":[1,2,3]}');
   jsonb_pretty
-------------------
 {                +
     "id": 1,     +
     "arr": [     +
         1,       +
         2,       +
         3        +
     ],           +
     "val": 1,    +
     "data": "bar"+
 }
(1 row)
```

この2つのJSONB文書をjsonb_diff関数で比較すると以下のようになる。

```
jsonb_diff=# SELECT * FROM jsonb_diff(
  '{"id":1, "name":"foo", "data":"foo", "col":1, "arr":[1,"2",3,4] }',
  '{"id":1, "data":"bar", "val":1, "arr":[1,2,3]}'
);
  kind  | left_path  |                                           left_schema                                           | right_path |
          right_schema
--------+------------+-------------------------------------------------------------------------------------------------+------------+-----------------------------------------------------------------------------
 update |            | [{"id": "number"}, {"arr": "array"}, {"col": "number"}, {"data": "string"}, {"name": "string"}] |            | [{"id": "number"}, {"arr": "array"}, {"val": "number"}, {"data": "string"}]
 update | ->'arr'    | [{"length": 4}, "number", "string", "number", "number"]                                         | ->'arr'    | [{"length": 3}, "number", "number", "number"]
 delete | ->'col'    | {"number": 1}                                                                                   |            |
 update | ->'arr'->1 | {"string": "2"}                                                                                 | ->'arr'->1 | {"number": 2}
 delete | ->'name'   | {"string": "foo"}                                                                               |            |
 append |            |                                                                                                 | ->'val'    | {"number": 1}
 delete | ->'arr'->3 | {"number": 4}                                                                                   |            |
 update | ->'data'   | {"string": "foo"}                                                                               | ->'data'   | {"string": "bar"}
(8 rows)

jsonb_diff=#
```

差分情報の内容は以下のようになる。

|行|種別|内容|
|--:|:--|:--|
|1|update|文書トップ(パスが空白)の直下の差分を示す。|
|2|update|->'arr' パスで示される箇所の差分を示す。配列要素数の違いや、途中の要素の型の違いがある。|
|3|delete|->'col' パスで示される箇所は、left側には存在するが、right側には存在しない。|
|4|update|->'arr'->1 パスで示される箇所の差分を示す。左辺はstring型の2だが、右辺はnumber型の2である。|
|5|delete|->'name' パスで示される箇所は、left側には存在するが、right側には存在しない。|
|6|append|->'val' パスで示される箇所は、left側には存在しないが、right側には存在する。|
|7|delete|->'arr'->3 パス(0相対なのでarrの4番目の要素)で示される箇所は、left側には存在するが、right側には存在しない。|
|8|update|->'data' パスで示される箇所の差分を示す。この例では値(fooとbar)が異なっている。|

## TODO

* extension化
* リグレッションテストの作成
* pl/pgsqlで作っているので、性能面での懸念がある。（ただ、C言語等での作り直しはするつもりはない）

