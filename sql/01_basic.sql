SELECT * FROM jsonb_diff(
  '{"id":1, "name":"foo", "data":"foo", "col":1, "arr":[1,"2",3,4] }',
  '{"id":1, "data":"bar", "val":1, "arr":[1,2,3]}'
);
