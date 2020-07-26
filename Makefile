EXTENSION = jsonb_diff
DATA = jsonb_diff--1.0.sql

REGRESS = 00_setup 01_basic 02_nest_object 03_nest_array 04_match

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
