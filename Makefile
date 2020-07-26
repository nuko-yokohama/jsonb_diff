EXTENSION = jsonb_diff
DATA = jsonb_diff--1.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
