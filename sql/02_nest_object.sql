SELECT * FROM jsonb_diff(
  '{"id":1, "obj":{"key":1, "data1":"foo", "data2":"bar"}}',
  '{"id":1, "obj":{"key":1, "data1":"foo", "data2":"baz"}}'
);
