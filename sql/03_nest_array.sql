-- update
SELECT * FROM jsonb_diff(
  '[{"key":0, "value":"foo"},{"key":1, "value":"foo"},{"key":2, "value":"bar"}]',
  '[{"key":0, "value":"foo"},{"key":1, "value":"baz"},{"key":3, "value":"bar"}]'
);

-- append
SELECT * FROM jsonb_diff(
  '[{"key":0, "value":"foo"},{"key":2, "value":"bar"}]',
  '[{"key":0, "value":"foo"},{"key":1, "value":"foo"},{"key":2, "value":"bar"}]'
);

-- delete
SELECT * FROM jsonb_diff(
  '[{"key":0, "value":"foo"},{"key":1, "value":"foo"},{"key":2, "value":"bar"}]',
  '[{"key":0, "value":"foo"},{"key":2, "value":"bar"}]'
);

