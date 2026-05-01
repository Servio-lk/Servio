| db_structure_json|
| {
    "tables": {
        "auth.users": {
            "table": "users",
            "schema": "auth",
            "columns": [
                {
                    "name": "instance_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "aud",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "role",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "email",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "encrypted_password",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "email_confirmed_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "invited_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "confirmation_token",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "confirmation_sent_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "recovery_token",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "recovery_sent_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "email_change_token_new",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "email_change",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "email_change_sent_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "last_sign_in_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "raw_app_meta_data",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                },
                {
                    "name": "raw_user_meta_data",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                },
                {
                    "name": "is_super_admin",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "phone",
                    "default": "NULL::character varying",
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "phone_confirmed_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "phone_change",
                    "default": "''::character varying",
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "phone_change_token",
                    "default": "''::character varying",
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "phone_change_sent_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "confirmed_at",
                    "default": "LEAST(email_confirmed_at, phone_confirmed_at)",
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "email_change_token_current",
                    "default": "''::character varying",
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "email_change_confirm_status",
                    "default": "0",
                    "data_type": "smallint",
                    "is_nullable": true
                },
                {
                    "name": "banned_until",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "reauthentication_token",
                    "default": "''::character varying",
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "reauthentication_sent_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "is_sso_user",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "deleted_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "is_anonymous",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.bills": {
            "table": "bills",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('bills_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "current_meter_reading",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "customer_address",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "customer_name",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "customer_phone",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "discount",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": true
                },
                {
                    "name": "invoice_no",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "issued_by",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "net_total",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": true
                },
                {
                    "name": "next_service_due",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "payment_mode",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "sub_total",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_no",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.sessions": {
            "table": "sessions",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "factor_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "aal",
                    "default": null,
                    "data_type": "auth.aal_level",
                    "is_nullable": true
                },
                {
                    "name": "not_after",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "refreshed_at",
                    "default": null,
                    "data_type": "timestamp without time zone",
                    "is_nullable": true
                },
                {
                    "name": "user_agent",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "ip",
                    "default": null,
                    "data_type": "inet",
                    "is_nullable": true
                },
                {
                    "name": "tag",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "oauth_client_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "refresh_token_hmac_key",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "refresh_token_counter",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "scopes",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "oauth_client_id",
                    "constraint_name": "sessions_oauth_client_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "user_id",
                    "constraint_name": "sessions_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.offers": {
            "table": "offers",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('offers_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "discount_type",
                    "default": null,
                    "data_type": "character varying(20)",
                    "is_nullable": true
                },
                {
                    "name": "discount_value",
                    "default": null,
                    "data_type": "numeric(10,2)",
                    "is_nullable": true
                },
                {
                    "name": "image_url",
                    "default": null,
                    "data_type": "character varying(500)",
                    "is_nullable": true
                },
                {
                    "name": "is_active",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "subtitle",
                    "default": null,
                    "data_type": "character varying(200)",
                    "is_nullable": true
                },
                {
                    "name": "title",
                    "default": null,
                    "data_type": "character varying(200)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "valid_from",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "valid_until",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "vault.secrets": {
            "table": "secrets",
            "schema": "vault",
            "columns": [
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "description",
                    "default": "''::text",
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "secret",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "key_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "nonce",
                    "default": "vault._crypto_aead_det_noncegen()",
                    "data_type": "bytea",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "CURRENT_TIMESTAMP",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "CURRENT_TIMESTAMP",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.instances": {
            "table": "instances",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "uuid",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "raw_base_config",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.reviews": {
            "table": "reviews",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('reviews_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "comment",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "rating",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "appointment_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "appointment_id",
                    "constraint_name": "fkfhaj6kqx2pjpn6eambt0pa1nm",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.flow_state": {
            "table": "flow_state",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "auth_code",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "code_challenge_method",
                    "default": null,
                    "data_type": "auth.code_challenge_method",
                    "is_nullable": true
                },
                {
                    "name": "code_challenge",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "provider_type",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "provider_access_token",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "provider_refresh_token",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "authentication_method",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "auth_code_issued_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "invite_token",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "referrer",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "oauth_client_state_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "linking_target_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "email_optional",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.identities": {
            "table": "identities",
            "schema": "auth",
            "columns": [
                {
                    "name": "provider_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "identity_data",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": false
                },
                {
                    "name": "provider",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "last_sign_in_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "email",
                    "default": "lower((identity_data ->> 'email'::text))",
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "uuid",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "user_id",
                    "constraint_name": "identities_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.payments": {
            "table": "payments",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('payments_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "amount",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "payment_date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "payment_method",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "payment_status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "transaction_id",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "appointment_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "profile_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "appointment_id",
                    "constraint_name": "fk9a0odew03qao7nlbdsesrux5u",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "profile_id",
                    "constraint_name": "fkdlfwqw4f71396kjdrna8x1qiy",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.profiles": {
            "table": "profiles",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "full_name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "avatar_url",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "username",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "is_admin",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "email",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "phone",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "role",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "joined",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "id",
                    "constraint_name": "profiles_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.services": {
            "table": "services",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('services_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "base_price",
                    "default": null,
                    "data_type": "numeric(10,2)",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "duration_minutes",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "image_url",
                    "default": null,
                    "data_type": "character varying(500)",
                    "is_nullable": true
                },
                {
                    "name": "is_active",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "is_featured",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "character varying(200)",
                    "is_nullable": false
                },
                {
                    "name": "price_range",
                    "default": null,
                    "data_type": "character varying(50)",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "category_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "category_id",
                    "constraint_name": "fkfffr4emayc2n4uq3yv618d9j0",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.vehicles": {
            "table": "vehicles",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('vehicles_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "license_plate",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "make",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "model",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "vin",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "year",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "profile_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "profile_id",
                    "constraint_name": "vehicles_profile_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "storage.buckets": {
            "table": "buckets",
            "schema": "storage",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "owner",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "public",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "avif_autodetection",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "file_size_limit",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "allowed_mime_types",
                    "default": null,
                    "data_type": "text[]",
                    "is_nullable": true
                },
                {
                    "name": "owner_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "type",
                    "default": "'STANDARD'::storage.buckettype",
                    "data_type": "storage.buckettype",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "storage.objects": {
            "table": "objects",
            "schema": "storage",
            "columns": [
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "bucket_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "owner",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "last_accessed_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "metadata",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                },
                {
                    "name": "path_tokens",
                    "default": "string_to_array(name, '/'::text)",
                    "data_type": "text[]",
                    "is_nullable": true
                },
                {
                    "name": "version",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "owner_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "user_metadata",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "bucket_id",
                    "constraint_name": "objects_bucketId_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.mfa_factors": {
            "table": "mfa_factors",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "friendly_name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "factor_type",
                    "default": null,
                    "data_type": "auth.factor_type",
                    "is_nullable": false
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "auth.factor_status",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "secret",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "phone",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "last_challenged_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "web_authn_credential",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                },
                {
                    "name": "web_authn_aaguid",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "last_webauthn_challenge_data",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "user_id",
                    "constraint_name": "mfa_factors_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.sso_domains": {
            "table": "sso_domains",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "sso_provider_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "domain",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "sso_provider_id",
                    "constraint_name": "sso_domains_sso_provider_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.job_cards": {
            "table": "job_cards",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('job_cards_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "actual_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "actual_hours",
                    "default": null,
                    "data_type": "double precision",
                    "is_nullable": true
                },
                {
                    "name": "completed_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "estimated_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "estimated_hours",
                    "default": null,
                    "data_type": "double precision",
                    "is_nullable": true
                },
                {
                    "name": "job_number",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "priority",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "service_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "started_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "appointment_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "service_bay_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "mechanic_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "walk_in_customer_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "mechanic_id",
                    "constraint_name": "fk30ar3t7xli9ptgl6ncqncymte",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "walk_in_customer_id",
                    "constraint_name": "fk5k4elmj2ofeao7a2kfn150jxy",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "service_bay_id",
                    "constraint_name": "fkj1lcsc1hfws999eh5d47vbg2e",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "appointment_id",
                    "constraint_name": "fkrmyo7e7m73bpwl59rp5ng52dp",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.job_tasks": {
            "table": "job_tasks",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('job_tasks_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "actual_hours",
                    "default": null,
                    "data_type": "double precision",
                    "is_nullable": true
                },
                {
                    "name": "completed_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "estimated_hours",
                    "default": null,
                    "data_type": "double precision",
                    "is_nullable": true
                },
                {
                    "name": "instructions",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "sequence_order",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "started_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "task_number",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "assigned_mechanic_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "job_card_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "assigned_mechanic_id",
                    "constraint_name": "fkpnlpfu9fs84b0rsxnaq7koib6",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "job_card_id",
                    "constraint_name": "fktdy5r0r2ejxd2igp1264nuu2g",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.mechanics": {
            "table": "mechanics",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('mechanics_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "email",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "experience_years",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "full_name",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "is_active",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "phone",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "specialization",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.bill_items": {
            "table": "bill_items",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('bill_items_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "amount",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "inventory_item_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "quantity",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": false
                },
                {
                    "name": "rate",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": false
                },
                {
                    "name": "bill_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "bill_id",
                    "constraint_name": "fkj9o7g8krc56gf6t6f0sy4ic5p",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.user_roles": {
            "table": "user_roles",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('user_roles_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "role",
                    "default": null,
                    "data_type": "app_role",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "user_id",
                    "constraint_name": "user_roles_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.oauth_clients": {
            "table": "oauth_clients",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "client_secret_hash",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "registration_type",
                    "default": null,
                    "data_type": "auth.oauth_registration_type",
                    "is_nullable": false
                },
                {
                    "name": "redirect_uris",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "grant_types",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "client_name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "client_uri",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "logo_uri",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "deleted_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "client_type",
                    "default": "'confidential'::auth.oauth_client_type",
                    "data_type": "auth.oauth_client_type",
                    "is_nullable": false
                },
                {
                    "name": "token_endpoint_auth_method",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.sso_providers": {
            "table": "sso_providers",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "resource_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "disabled",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.repair_jobs": {
            "table": "repair_jobs",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('repair_jobs_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "actual_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "actual_duration_hours",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "assigned_technician_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "completion_date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "estimated_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "estimated_duration_hours",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "labor_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "notes",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "parts_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "priority",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "start_date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "title",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "appointment_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "vehicle_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "vehicle_id",
                    "constraint_name": "fkeik8j3moflu807j2k6d4fxxjc",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "appointment_id",
                    "constraint_name": "fkif1bjqcxfov40qhonr2u2pugk",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "storage.migrations": {
            "table": "migrations",
            "schema": "storage",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": false
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "character varying(100)",
                    "is_nullable": false
                },
                {
                    "name": "hash",
                    "default": null,
                    "data_type": "character varying(40)",
                    "is_nullable": false
                },
                {
                    "name": "executed_at",
                    "default": "CURRENT_TIMESTAMP",
                    "data_type": "timestamp without time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
            ]
        },
        "auth.mfa_amr_claims": {
            "table": "mfa_amr_claims",
            "schema": "auth",
            "columns": [
                {
                    "name": "session_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "authentication_method",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "session_id",
                    "constraint_name": "mfa_amr_claims_session_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.mfa_challenges": {
            "table": "mfa_challenges",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "factor_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "verified_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "ip_address",
                    "default": null,
                    "data_type": "inet",
                    "is_nullable": false
                },
                {
                    "name": "otp_code",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "web_authn_session_data",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "factor_id",
                    "constraint_name": "mfa_challenges_auth_factor_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.oauth_consents": {
            "table": "oauth_consents",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "client_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "scopes",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "granted_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "revoked_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": "client_id",
                    "constraint_name": "oauth_consents_client_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "user_id",
                    "constraint_name": "oauth_consents_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.refresh_tokens": {
            "table": "refresh_tokens",
            "schema": "auth",
            "columns": [
                {
                    "name": "instance_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "id",
                    "default": "nextval('auth.refresh_tokens_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "token",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "revoked",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "parent",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "session_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "session_id",
                    "constraint_name": "refresh_tokens_session_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.saml_providers": {
            "table": "saml_providers",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "sso_provider_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "entity_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "metadata_xml",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "metadata_url",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "attribute_mapping",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "name_id_format",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "sso_provider_id",
                    "constraint_name": "saml_providers_sso_provider_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.appointments": {
            "table": "appointments",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('appointments_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "actual_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "appointment_date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "estimated_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "location",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "notes",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "service_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "profile_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "profile_id",
                    "constraint_name": "fk4r2911ns98uncpuc5dlfe6iqx",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "vehicle_id",
                    "constraint_name": "fkalpncq8pxtwld2wmgw4sxct70",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.repair_parts": {
            "table": "repair_parts",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('repair_parts_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "delivery_date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "notes",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "order_date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "part_name",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "part_number",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "quantity",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": false
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "supplier",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "total_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": false
                },
                {
                    "name": "unit_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "repair_job_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "repair_job_id",
                    "constraint_name": "fkb39hmhnslo5dfcva82jxbp81n",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.service_bays": {
            "table": "service_bays",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('service_bays_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "bay_number",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "capacity",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "is_active",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.one_time_tokens": {
            "table": "one_time_tokens",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "token_type",
                    "default": null,
                    "data_type": "auth.one_time_token_type",
                    "is_nullable": false
                },
                {
                    "name": "token_hash",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "relates_to",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp without time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp without time zone",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "user_id",
                    "constraint_name": "one_time_tokens_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.notifications": {
            "table": "notifications",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('notifications_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "is_read",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "message",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "title",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.repair_images": {
            "table": "repair_images",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('repair_images_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "image_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "image_url",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "repair_job_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "uploaded_by_user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "repair_job_id",
                    "constraint_name": "fknsmd02baki7km7h68io8tw8c5",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.job_card_notes": {
            "table": "job_card_notes",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('job_card_notes_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "note_text",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "note_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "created_by_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "job_card_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "job_card_id",
                    "constraint_name": "fkjcgiwopv562fuf9odntefsu4j",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.repair_history": {
            "table": "repair_history",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('repair_history_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "mileage_at_repair",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "notes",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "repair_date",
                    "default": null,
                    "data_type": "date",
                    "is_nullable": false
                },
                {
                    "name": "repair_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "technician_name",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "repair_job_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "vehicle_id",
                    "constraint_name": "fk8vi6ss63kro9jydyui2ged7yt",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "repair_job_id",
                    "constraint_name": "fktn0tpwf35p3bqelwt080cl0cf",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "realtime.subscription": {
            "table": "subscription",
            "schema": "realtime",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "subscription_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "entity",
                    "default": null,
                    "data_type": "regclass",
                    "is_nullable": false
                },
                {
                    "name": "filters",
                    "default": "'{}'::realtime.user_defined_filter[]",
                    "data_type": "realtime.user_defined_filter[]",
                    "is_nullable": false
                },
                {
                    "name": "claims",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": false
                },
                {
                    "name": "claims_role",
                    "default": "realtime.to_regrole((claims ->> 'role'::text))",
                    "data_type": "regrole",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": "timezone('utc'::text, now())",
                    "data_type": "timestamp without time zone",
                    "is_nullable": false
                },
                {
                    "name": "action_filter",
                    "default": "'*'::text",
                    "data_type": "text",
                    "is_nullable": true
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.audit_log_entries": {
            "table": "audit_log_entries",
            "schema": "auth",
            "columns": [
                {
                    "name": "instance_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "payload",
                    "default": null,
                    "data_type": "json",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "ip_address",
                    "default": "''::character varying",
                    "data_type": "character varying(64)",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.saml_relay_states": {
            "table": "saml_relay_states",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "sso_provider_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "request_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "for_email",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "redirect_to",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "flow_state_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "flow_state_id",
                    "constraint_name": "saml_relay_states_flow_state_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "sso_provider_id",
                    "constraint_name": "saml_relay_states_sso_provider_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.schema_migrations": {
            "table": "schema_migrations",
            "schema": "auth",
            "columns": [
                {
                    "name": "version",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
            ]
        },
        "public.inventory_items": {
            "table": "inventory_items",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('inventory_items_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "category",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "cost_per_unit",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "current_stock",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": false
                },
                {
                    "name": "minimum_stock",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": false
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "selling_price_per_unit",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "service_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "unit",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.job_card_photos": {
            "table": "job_card_photos",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('job_card_photos_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "photo_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "photo_url",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "job_card_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "uploaded_by_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "job_card_id",
                    "constraint_name": "fkc99b6notp8k9lqh9nentod6db",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.repair_progress": {
            "table": "repair_progress",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('repair_progress_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "actual_completion_time",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "current_status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "estimated_completion_time",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "last_updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "notes",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "progress_percentage",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "repair_job_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "repair_job_id",
                    "constraint_name": "fk44kam1ntav57shaal2o6pgjrt",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.service_options": {
            "table": "service_options",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('service_options_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "display_order",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "is_default",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "character varying(200)",
                    "is_nullable": false
                },
                {
                    "name": "price_adjustment",
                    "default": null,
                    "data_type": "numeric(10,2)",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "service_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "service_id",
                    "constraint_name": "fk6lpld6mqfcsj1skdjfhuupfih",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.service_records": {
            "table": "service_records",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('service_records_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "mileage",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "service_date",
                    "default": null,
                    "data_type": "date",
                    "is_nullable": false
                },
                {
                    "name": "service_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "vehicle_id",
                    "constraint_name": "fk11ppy4gvbrb3h4pdg9y4j86kp",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "storage.vector_indexes": {
            "table": "vector_indexes",
            "schema": "storage",
            "columns": [
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "bucket_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "data_type",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "dimension",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": false
                },
                {
                    "name": "distance_metric",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "metadata_configuration",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
            ]
        },
        "public.billing_invoices": {
            "table": "billing_invoices",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('billing_invoices_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "current_meter_reading",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "customer_address",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "customer_name",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "customer_phone",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "discount",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": true
                },
                {
                    "name": "invoice_no",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "issued_by",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "net_total",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": true
                },
                {
                    "name": "next_service_due",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "payment_mode",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "sub_total",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_no",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.repair_estimates": {
            "table": "repair_estimates",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('repair_estimates_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "approved_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "estimate_date",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "estimate_number",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "estimated_duration_days",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "estimated_labor_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "estimated_parts_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": true
                },
                {
                    "name": "estimated_total_cost",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": false
                },
                {
                    "name": "notes",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "validity_days",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "approved_by_user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "created_by_user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "repair_job_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "repair_job_id",
                    "constraint_name": "fkt0fpf949hsxhdqtqc9x56kigu",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.role_permissions": {
            "table": "role_permissions",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('role_permissions_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "role",
                    "default": null,
                    "data_type": "app_role",
                    "is_nullable": false
                },
                {
                    "name": "permission",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "storage.buckets_vectors": {
            "table": "buckets_vectors",
            "schema": "storage",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "type",
                    "default": "'VECTOR'::storage.buckettype",
                    "data_type": "storage.buckettype",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
            ]
        },
        "auth.oauth_client_states": {
            "table": "oauth_client_states",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "provider_type",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "code_verifier",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.webauthn_challenges": {
            "table": "webauthn_challenges",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "challenge_type",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "session_data",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "expires_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": "user_id",
                    "constraint_name": "webauthn_challenges_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.repair_activities": {
            "table": "repair_activities",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('repair_activities_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "activity_type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "performed_by_user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "repair_job_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "repair_job_id",
                    "constraint_name": "fkg16nuht5i3t8heeyihpypmh7a",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.service_providers": {
            "table": "service_providers",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('service_providers_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "address",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "city",
                    "default": null,
                    "data_type": "character varying(100)",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "email",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "is_active",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "character varying(200)",
                    "is_nullable": false
                },
                {
                    "name": "phone",
                    "default": null,
                    "data_type": "character varying(20)",
                    "is_nullable": true
                },
                {
                    "name": "rating",
                    "default": null,
                    "data_type": "numeric(3,2)",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.walk_in_customers": {
            "table": "walk_in_customers",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('walk_in_customers_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "email",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "full_name",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "is_registered",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "license_plate",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "notes",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "phone",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "registered_user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_make",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_model",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "vehicle_year",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.oauth_authorizations": {
            "table": "oauth_authorizations",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "authorization_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "client_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "redirect_uri",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "scope",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "state",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "resource",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "code_challenge",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "code_challenge_method",
                    "default": null,
                    "data_type": "auth.code_challenge_method",
                    "is_nullable": true
                },
                {
                    "name": "response_type",
                    "default": "'code'::auth.oauth_response_type",
                    "data_type": "auth.oauth_response_type",
                    "is_nullable": false
                },
                {
                    "name": "status",
                    "default": "'pending'::auth.oauth_authorization_status",
                    "data_type": "auth.oauth_authorization_status",
                    "is_nullable": false
                },
                {
                    "name": "authorization_code",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "expires_at",
                    "default": "(now() + '00:03:00'::interval)",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "approved_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "nonce",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": "client_id",
                    "constraint_name": "oauth_authorizations_client_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "user_id",
                    "constraint_name": "oauth_authorizations_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "auth.webauthn_credentials": {
            "table": "webauthn_credentials",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "user_id",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "credential_id",
                    "default": null,
                    "data_type": "bytea",
                    "is_nullable": false
                },
                {
                    "name": "public_key",
                    "default": null,
                    "data_type": "bytea",
                    "is_nullable": false
                },
                {
                    "name": "attestation_type",
                    "default": "''::text",
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "aaguid",
                    "default": null,
                    "data_type": "uuid",
                    "is_nullable": true
                },
                {
                    "name": "sign_count",
                    "default": "0",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "transports",
                    "default": "'[]'::jsonb",
                    "data_type": "jsonb",
                    "is_nullable": false
                },
                {
                    "name": "backup_eligible",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "backed_up",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "friendly_name",
                    "default": "''::text",
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "last_used_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": "user_id",
                    "constraint_name": "webauthn_credentials_user_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.service_categories": {
            "table": "service_categories",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('service_categories_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "display_order",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "is_active",
                    "default": null,
                    "data_type": "boolean",
                    "is_nullable": true
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "character varying(100)",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.stock_transactions": {
            "table": "stock_transactions",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('stock_transactions_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "notes",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": true
                },
                {
                    "name": "performed_by",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "quantity",
                    "default": null,
                    "data_type": "numeric(38,2)",
                    "is_nullable": false
                },
                {
                    "name": "type",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "inventory_item_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "inventory_item_id",
                    "constraint_name": "fk87pw0nkex8soxqpb9qclpmyc2",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "storage.buckets_analytics": {
            "table": "buckets_analytics",
            "schema": "storage",
            "columns": [
                {
                    "name": "name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "type",
                    "default": "'ANALYTICS'::storage.buckettype",
                    "data_type": "storage.buckettype",
                    "is_nullable": false
                },
                {
                    "name": "format",
                    "default": "'ICEBERG'::text",
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "deleted_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "realtime.schema_migrations": {
            "table": "schema_migrations",
            "schema": "realtime",
            "columns": [
                {
                    "name": "version",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "inserted_at",
                    "default": null,
                    "data_type": "timestamp(0) without time zone",
                    "is_nullable": true
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "version"
            ]
        },
        "auth.custom_oauth_providers": {
            "table": "custom_oauth_providers",
            "schema": "auth",
            "columns": [
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "provider_type",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "identifier",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "name",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "client_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "client_secret",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "acceptable_client_ids",
                    "default": "'{}'::text[]",
                    "data_type": "text[]",
                    "is_nullable": false
                },
                {
                    "name": "scopes",
                    "default": "'{}'::text[]",
                    "data_type": "text[]",
                    "is_nullable": false
                },
                {
                    "name": "pkce_enabled",
                    "default": "true",
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "attribute_mapping",
                    "default": "'{}'::jsonb",
                    "data_type": "jsonb",
                    "is_nullable": false
                },
                {
                    "name": "authorization_params",
                    "default": "'{}'::jsonb",
                    "data_type": "jsonb",
                    "is_nullable": false
                },
                {
                    "name": "enabled",
                    "default": "true",
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "email_optional",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "issuer",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "discovery_url",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "skip_nonce_check",
                    "default": "false",
                    "data_type": "boolean",
                    "is_nullable": false
                },
                {
                    "name": "cached_discovery",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                },
                {
                    "name": "discovery_cached_at",
                    "default": null,
                    "data_type": "timestamp with time zone",
                    "is_nullable": true
                },
                {
                    "name": "authorization_url",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "token_url",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "userinfo_url",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "jwks_uri",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "updated_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                }
            ],
            "rls_enabled": false,
            "foreign_keys": [
                {
                    "column": null,
                    "constraint_name": null,
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.billing_invoice_items": {
            "table": "billing_invoice_items",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('billing_invoice_items_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "amount",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "inventory_item_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                },
                {
                    "name": "quantity",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": false
                },
                {
                    "name": "rate",
                    "default": null,
                    "data_type": "numeric(19,2)",
                    "is_nullable": false
                },
                {
                    "name": "bill_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "bill_id",
                    "constraint_name": "fksboo28em81numh41auufy4sao",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "storage.s3_multipart_uploads": {
            "table": "s3_multipart_uploads",
            "schema": "storage",
            "columns": [
                {
                    "name": "id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "in_progress_size",
                    "default": "0",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "upload_signature",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "bucket_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "key",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "version",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "owner_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                },
                {
                    "name": "user_metadata",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                },
                {
                    "name": "metadata",
                    "default": null,
                    "data_type": "jsonb",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "bucket_id",
                    "constraint_name": "s3_multipart_uploads_bucket_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "public.repair_progress_updates": {
            "table": "repair_progress_updates",
            "schema": "public",
            "columns": [
                {
                    "name": "id",
                    "default": "nextval('repair_progress_updates_id_seq'::regclass)",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "actual_completion_time",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "created_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": false
                },
                {
                    "name": "description",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "estimated_completion_time",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "progress_percentage",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": true
                },
                {
                    "name": "status",
                    "default": null,
                    "data_type": "character varying(255)",
                    "is_nullable": false
                },
                {
                    "name": "technician_notes",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "updated_at",
                    "default": null,
                    "data_type": "timestamp(6) without time zone",
                    "is_nullable": true
                },
                {
                    "name": "repair_job_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "updated_by_user_id",
                    "default": null,
                    "data_type": "bigint",
                    "is_nullable": true
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "repair_job_id",
                    "constraint_name": "fk1rtkfp85hxmn8edxmmcyh2bt6",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        },
        "storage.s3_multipart_uploads_parts": {
            "table": "s3_multipart_uploads_parts",
            "schema": "storage",
            "columns": [
                {
                    "name": "id",
                    "default": "gen_random_uuid()",
                    "data_type": "uuid",
                    "is_nullable": false
                },
                {
                    "name": "upload_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "size",
                    "default": "0",
                    "data_type": "bigint",
                    "is_nullable": false
                },
                {
                    "name": "part_number",
                    "default": null,
                    "data_type": "integer",
                    "is_nullable": false
                },
                {
                    "name": "bucket_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "key",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "etag",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "owner_id",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": true
                },
                {
                    "name": "version",
                    "default": null,
                    "data_type": "text",
                    "is_nullable": false
                },
                {
                    "name": "created_at",
                    "default": "now()",
                    "data_type": "timestamp with time zone",
                    "is_nullable": false
                }
            ],
            "rls_enabled": true,
            "foreign_keys": [
                {
                    "column": "bucket_id",
                    "constraint_name": "s3_multipart_uploads_parts_bucket_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                },
                {
                    "column": "upload_id",
                    "constraint_name": "s3_multipart_uploads_parts_upload_id_fkey",
                    "referenced_table": null,
                    "referenced_column": null,
                    "referenced_schema": null
                }
            ],
            "primary_keys": [
                "id"
            ]
        }
    }
} |