--
-- jsonb_diff.sql
-- Compare two JSONB documents and report the differences.
--
\echo Use "CREATE EXTENSION jsonb_diff" to load this file. \quit


DROP TYPE IF EXISTS diff CASCADE;
CREATE TYPE diff AS (kind text, left_path text, left_schema jsonb, right_path text, right_schema jsonb);

--
-- child_schema(internal)
-- Generate schema JSONB that shows the structural information of the child element immediately below.
--
CREATE OR REPLACE FUNCTION child_schema( jb jsonb )
 RETURNS jsonb
 LANGUAGE plpgsql
 -- common options:  IMMUTABLE  STABLE  STRICT  SECURITY DEFINER
AS $function$
DECLARE
rec RECORD;
ret jsonb := '[]';
BEGIN
  FOR rec IN SELECT jsonb_object_keys(jb) AS keyname
  LOOP
    -- RAISE NOTICE 'key=%', rec.keyname;
    -- RAISE NOTICE 'type=%', jsonb_typeof(jb->rec.keyname);
    ret := ret || jsonb_build_object(rec.keyname, jsonb_typeof(jb->rec.keyname));
  END LOOP;
  RETURN ret;
END;
$function$
;

--
-- array_schema(internal)
-- Generate a schema JSONB that shows the structural information of the array immediately below.
--
CREATE OR REPLACE FUNCTION array_schema( jb jsonb )
 RETURNS jsonb
 LANGUAGE plpgsql
 -- common options:  IMMUTABLE  STABLE  STRICT  SECURITY DEFINER
AS $function$
DECLARE
length integer;
ret jsonb := '{}';
arr jsonb := '[]';
BEGIN
  length := jsonb_array_length(jb);
  ret := jsonb_build_object('length', length);
  FOR cnt IN 0 .. (length - 1) LOOP
    arr := arr || jsonb_build_array(jsonb_typeof(jb->cnt));
  END LOOP;
  ret := ret || arr;
  RETURN ret;
END;
$function$
;

--
-- insert_scm_table(internal)
-- Insert the structure information of JSONB into the intermediate table (scm_table) for comparison.
--
CREATE OR REPLACE FUNCTION insert_scm_table( jb jsonb, path_text text, node text)
 RETURNS jsonb
 LANGUAGE plpgsql
 -- common options:  IMMUTABLE  STABLE  STRICT  SECURITY DEFINER
AS $function$
DECLARE
  typ text;
  obj jsonb;
  rec RECORD;
  cnt integer;
  length integer;
  scm jsonb;
BEGIN
  -- RAISE NOTICE 'path_text=%', path_text;
  typ := jsonb_typeof(jb);
  CASE typ
    WHEN 'object' THEN
      -- RAISE NOTICE 'typeof is object,%', jb::text;
      -- RAISE NOTICE 'child_schema=%', child_schema(jb);
      scm := child_schema(jb);
      FOR rec IN SELECT jsonb_object_keys(jb) AS keyname
      LOOP
        -- RAISE NOTICE 'key=%', rec.keyname;
        PERFORM insert_scm_table(jb->rec.keyname, path_text || '->''' || rec.keyname || '''', node);
      END LOOP;
    WHEN 'number' THEN
      -- RAISE NOTICE 'typeof is number,%', jb::text;
      -- RAISE NOTICE 'value=%', jsonb_build_object('number', jb);
      scm := jsonb_build_object('number', jb);
    WHEN 'string' THEN
      -- RAISE NOTICE 'typeof is string,%', jb::text;
      -- RAISE NOTICE 'value=%', jsonb_build_object('string', jb);
      scm := jsonb_build_object('string', jb);
    WHEN 'boolean' THEN
      -- RAISE NOTICE 'typeof is boolean,%', jb::text;
      -- RAISE NOTICE 'value=%', jsonb_build_object('string', jb);
      scm := jsonb_build_object('boolean', jb);
    WHEN 'array' THEN
      -- RAISE NOTICE 'typeof is array,%', jb::text;
      -- RAISE NOTICE 'array_schema=%', array_schema(jb);
      scm := array_schema(jb);
      length := jsonb_array_length(jb);
      FOR cnt IN 0 .. (length - 1) LOOP
        PERFORM insert_scm_table(jb->cnt, path_text || '->' || cnt, node);
      END LOOP;
    WHEN 'null' THEN
      -- RAISE NOTICE 'typeof is null,' ;
      -- RAISE NOTICE '{}';
      scm := '{}'::jsonb;
    ELSE 
     -- bug case
     RAISE EXCEPTION 'jsonb_typeof error, %', jb::text;
  END CASE;
  INSERT INTO scm_table (node, path_text, schema_info) VALUES (node, path_text, scm );
  return jb;
END;
$function$
;

--
-- jsonb_diff()
-- Compare two JSONB documents and report the differences.
--
CREATE OR REPLACE FUNCTION jsonb_diff(lj jsonb, rj jsonb)
 RETURNS SETOF diff
 LANGUAGE plpgsql
 -- common options:  IMMUTABLE  STABLE  STRICT  SECURITY DEFINER
AS $function$
BEGIN
  DROP TABLE IF EXISTS scm_table CASCADE;
  CREATE TEMP TABLE scm_table (node text, path_text text, schema_info jsonb);
  PERFORM insert_scm_table(lj, '', 'left');
  PERFORM insert_scm_table(rj, '', 'right');

  RETURN QUERY 
WITH diff AS (
SELECT 
  l.path_text AS left_path, 
  l.schema_info AS left_schema, 
  r.path_text AS right_path, 
  r.schema_info AS right_schema 
FROM
  (SELECT path_text, schema_info FROM scm_table WHERE node = 'left') l
  FULL OUTER JOIN
  (SELECT path_text, schema_info FROM scm_table WHERE node = 'right') r
  ON (l.path_text = r.path_text)
)
SELECT 'append' AS kind, diff.* FROM diff WHERE diff.left_path IS NULL
UNION
SELECT 'delete' AS kind, diff.* FROM diff WHERE diff.right_path IS NULL
UNION
SELECT 'update' AS kind, diff.* FROM diff WHERE diff.left_path IS NOT NULL AND diff.right_path IS NOT NULL AND left_schema <> right_schema
;

  RETURN;
END;
$function$
;
