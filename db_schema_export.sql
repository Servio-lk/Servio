with tables as (
  select
    n.nspname as schema_name,
    c.relname as table_name,
    c.oid as table_oid,
    (case when exists (
      select 1
      from pg_class rc
      join pg_namespace rn on rn.oid = rc.relnamespace
      where rc.oid = c.oid
        and rn.nspname = n.nspname
        and rc.relrowsecurity
    ) then true else false end) as rls_enabled
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where c.relkind = 'r' -- ordinary tables
    and n.nspname in ('public','auth','storage','realtime','graphql_public','graphql','vault','extensions','pgbouncer')
),
columns as (
  select
    t.schema_name,
    t.table_name,
    jsonb_agg(
      jsonb_build_object(
        'name', a.attname,
        'data_type', pg_catalog.format_type(a.atttypid, a.atttypmod),
        'is_nullable', (not a.attnotnull),
        'default', pg_get_expr(ad.adbin, ad.adrelid)
      )
      order by a.attnum
    ) as columns
  from tables t
  join pg_attribute a
    on a.attrelid = t.table_oid
   and a.attnum > 0
   and not a.attisdropped
  left join pg_attrdef ad
    on ad.adrelid = a.attrelid
   and ad.adnum = a.attnum
  group by t.schema_name, t.table_name
),
pk as (
  select
    t.schema_name,
    t.table_name,
    coalesce(
      jsonb_agg(att.attname order by kcu.ordinal_position),
      '[]'::jsonb
    ) as primary_keys
  from tables t
  join information_schema.table_constraints tc
    on tc.table_schema = t.schema_name
   and tc.table_name = t.table_name
   and tc.constraint_type = 'PRIMARY KEY'
  join information_schema.key_column_usage kcu
    on kcu.table_schema = tc.table_schema
   and kcu.table_name = tc.table_name
   and kcu.constraint_name = tc.constraint_name
  join pg_attribute att
    on att.attrelid = t.table_oid
   and att.attname = kcu.column_name
  group by t.schema_name, t.table_name
),
fk as (
  select
    t.schema_name,
    t.table_name,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'constraint_name', tc.constraint_name,
          'column', kcu.column_name,
          'referenced_table', ccu.table_name,
          'referenced_schema', ccu.table_schema,
          'referenced_column', ccu.column_name
        )
        order by tc.constraint_name, kcu.ordinal_position
      ),
      '[]'::jsonb
    ) as foreign_keys
  from tables t
  left join information_schema.table_constraints tc
    on tc.table_schema = t.schema_name
   and tc.table_name = t.table_name
   and tc.constraint_type = 'FOREIGN KEY'
  left join information_schema.key_column_usage kcu
    on kcu.table_schema = tc.table_schema
   and kcu.table_name = tc.table_name
   and kcu.constraint_name = tc.constraint_name
  left join information_schema.constraint_column_usage ccu
    on ccu.table_schema = tc.table_schema
   and ccu.table_name = tc.table_name
   and ccu.constraint_name = tc.constraint_name
  group by t.schema_name, t.table_name
)
select jsonb_pretty(
  jsonb_build_object(
    'tables',
    jsonb_object_agg(
      t.schema_name || '.' || t.table_name,
      jsonb_build_object(
        'schema', t.schema_name,
        'table', t.table_name,
        'rls_enabled', t.rls_enabled,
        'columns', coalesce(col.columns, '[]'::jsonb),
        'primary_keys', coalesce(pk.primary_keys, '[]'::jsonb),
        'foreign_keys', coalesce(fk.foreign_keys, '[]'::jsonb)
      )
    )
  )
) as db_structure_json
from tables t
left join columns col
  on col.schema_name = t.schema_name
 and col.table_name = t.table_name
left join pk
  on pk.schema_name = t.schema_name
 and pk.table_name = t.table_name
left join fk
  on fk.schema_name = t.schema_name
 and fk.table_name = t.table_name;