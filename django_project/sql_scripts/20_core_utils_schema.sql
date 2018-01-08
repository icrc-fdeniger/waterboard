-- DROP SCHEMA IF EXISTS core_utils CASCADE;
CREATE SCHEMA IF NOT EXISTS core_utils;

-- *
-- core_utils.get_events
-- *

CREATE OR REPLACE FUNCTION core_utils.get_events(min_x double precision, min_y double precision, max_x double precision, max_y double precision)
  RETURNS text
STABLE
LANGUAGE SQL
AS $body$
SELECT coalesce(jsonb_agg(d.row) :: TEXT, '[]') AS data
FROM (
       SELECT jsonb_build_object(
                  '_feature_uuid', ft.feature_uuid :: TEXT,
                  '_created_date', chg.ts_created,
                  '_data_captor', wu.email,
                  '_geometry', ARRAY [ST_X(ft.point_geometry), ST_Y(ft.point_geometry)]
              ) || coalesce(attributes.row, '{}' :: JSONB) AS row
       FROM
         features.feature ft

             LEFT JOIN LATERAL (
                       SELECT
                          fav.feature_uuid,
                           jsonb_object_agg(
                               dg.key || '/' || da.key,
                                row_to_json(fav) -> CASE
                                                                WHEN da.result_type = 'Integer'
                                                                    THEN 'val_int'
                                                                WHEN da.result_type = 'Decimal'
                                                                    THEN 'val_real'
                                                                WHEN da.result_type = 'Text'
                                                                    THEN 'val_text'
                                                                WHEN da.result_type = 'DropDown'
                                                                    THEN 'val_int'
                                                                WHEN da.result_type = 'MultipleChoice'
                                                                    THEN 'val_text'
                                                                ELSE NULL
                                                                END
                            ) AS row
                       FROM
                           features.feature_attribute_value fav
                           JOIN public.attributes_attribute da ON da.id = fav.attribute_id
                           JOIN public.attributes_attributegroup dg ON dg.id = da.attribute_group_id

                   WHERE
                     fav.feature_uuid = ft.feature_uuid
                     AND fav.is_active = TRUE

                   GROUP BY fav.feature_uuid
                   ) attributes ON TRUE
         JOIN features.changeset chg ON ft.changeset_id = chg.id
         JOIN webusers_webuser wu ON chg.webuser_id = wu.id

       WHERE
         ft.point_geometry && ST_SetSRID(ST_MakeBox2D(ST_Point($1, $2), ST_Point($3, $4)), 4326)
         AND ft.is_active = TRUE
       GROUP BY ft.feature_uuid, chg.ts_created, wu.email, ft.point_geometry,
         attributes.row
       ORDER BY ft.feature_uuid) d;

$body$;

-- *
-- core_utils.create_changeset
-- *

CREATE OR REPLACE FUNCTION core_utils.create_changeset(i_webuser_id integer)
  RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_new_changeset_id INTEGER;
BEGIN

  INSERT INTO features.changeset (webuser_id) VALUES (i_webuser_id) RETURNING id INTO v_new_changeset_id;

  RETURN v_new_changeset_id;
END;

$$;


-- *
-- core_utils.add_feature
-- *

CREATE OR REPLACE FUNCTION core_utils.add_feature(i_feature_uuid uuid, i_feature_changeset integer, i_feature_point_geometry geometry, i_feature_attributes text)
  RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_attributes JSONB;
    v_key            TEXT;

    v_attr_id        INTEGER;
    v_result_type    TEXT;
    v_allowed_values TEXT [];

    v_int_value      INTEGER;
    v_decimal_value  DECIMAL(9, 2);
    v_text_value     VARCHAR(32);

    v_fav_active     features.FEATURE_ATTRIBUTE_VALUE;
BEGIN
    -- we first update feature and set is_active = FALSE
    UPDATE features.feature
    SET is_active = FALSE
    WHERE feature_uuid = i_feature_uuid AND is_active = TRUE;

    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'NOT FOUND - Feature uuid=%, is_active=TRUE', i_feature_uuid;
    END IF;

    -- insert a new feature

    INSERT INTO features.feature (feature_uuid, changeset_id, point_geometry, is_active)
    VALUES (
        i_feature_uuid, i_feature_changeset, i_feature_point_geometry,
        TRUE
    );

    v_new_attributes := cast(i_feature_attributes AS JSONB);

    -- collect type definitions
    CREATE TEMPORARY TABLE tmp_attribute_types ON COMMIT DROP AS
        SELECT
            aa.id,
            aa.key AS key,
            aa.result_type,
            array_agg(ao.value) AS allowed_values
        FROM attributes_attribute aa
            JOIN attributes_attributegroup ag ON aa.attribute_group_id = ag.id
            LEFT JOIN attributes_attributeoption ao ON ao.attribute_id = aa.id
        GROUP BY aa.id, aa.key, aa.result_type;

    -- collect current active rows
    CREATE TEMPORARY TABLE tmp_fav_active ON COMMIT DROP AS
        SELECT *
        FROM features.feature_attribute_value
        WHERE feature_uuid = i_feature_uuid AND is_active = TRUE;

    FOR v_key IN SELECT * FROM jsonb_object_keys(v_new_attributes) LOOP
        -- check attributes
        SELECT
            id,
            result_type,
            allowed_values
        INTO
            v_attr_id,
            v_result_type,
            v_allowed_values
        FROM tmp_attribute_types
        WHERE key = v_key;

        IF NOT FOUND
        THEN
            RAISE NOTICE 'Attribute="%" is not defined, skipping', v_key;
            CONTINUE;
        END IF;

        SELECT *
        INTO v_fav_active
        FROM tmp_fav_active
        WHERE attribute_id = v_attr_id;

        -- check attribute type
        IF v_result_type = 'Integer'
        THEN
            v_int_value := v_new_attributes -> v_key;


            -- only insert new data if the value has changed
            IF v_int_value != v_fav_active.val_int or v_fav_active.val_int is NULL THEN
                -- insert new data
                INSERT INTO features.feature_attribute_value (feature_uuid, changeset_id, attribute_id, val_int)
                VALUES (
                    i_feature_uuid, i_feature_changeset, v_attr_id, v_int_value
                );
                -- deactivate old attribute data
                UPDATE features.feature_attribute_value SET is_active = FALSE
                WHERE feature_uuid=i_feature_uuid AND is_active = TRUE and changeset_id != i_feature_changeset AND attribute_id = v_attr_id;
            END IF;

        ELSEIF v_result_type = 'Decimal'
            THEN
                v_decimal_value := v_new_attributes -> v_key;

                -- only insert new data if the value has changed
                IF v_decimal_value != v_fav_active.val_real or v_fav_active.val_real IS NULL THEN
                    -- insert new data
                    INSERT INTO features.feature_attribute_value (feature_uuid, changeset_id, attribute_id, val_real)
                    VALUES (
                        i_feature_uuid, i_feature_changeset, v_attr_id, v_decimal_value
                    );
                    -- deactivate old attribute data
                    UPDATE features.feature_attribute_value SET is_active = FALSE
                    WHERE feature_uuid=i_feature_uuid AND is_active = TRUE and changeset_id != i_feature_changeset AND attribute_id = v_attr_id;
                END IF;

        ELSEIF v_result_type = 'Text'
            THEN
                -- for whatever reason text values must be extracted as text (oprerator ->>)
                v_text_value := v_new_attributes ->> v_key;

                -- only insert new data if the value has changed
                IF v_text_value != v_fav_active.val_text or v_fav_active.val_text is null THEN
                    -- insert new data
                    INSERT INTO features.feature_attribute_value (feature_uuid, changeset_id, attribute_id, val_text)
                    VALUES (
                        i_feature_uuid, i_feature_changeset, v_attr_id, v_text_value::text
                    );
                    -- deactivate old attribute data
                    UPDATE features.feature_attribute_value SET is_active = FALSE
                    WHERE feature_uuid=i_feature_uuid AND is_active = TRUE and changeset_id != i_feature_changeset AND attribute_id = v_attr_id;
                END IF;

        ELSEIF v_result_type = 'DropDown'
            THEN
                v_int_value := v_new_attributes -> v_key;

                -- only insert new data if the value has changed
                IF NOT (v_allowed_values @> ARRAY [v_int_value :: TEXT])
                THEN
                    RAISE 'Attribute "%" value "%" is not allowed: %', v_key, v_int_value, v_allowed_values;
                END IF;

                IF v_int_value != v_fav_active.val_int or v_fav_active.val_int is null THEN

                    -- insert new data
                    INSERT INTO features.feature_attribute_value (feature_uuid, changeset_id, attribute_id, val_int)
                    VALUES (
                        i_feature_uuid, i_feature_changeset, v_attr_id, v_int_value
                    );
                    -- deactivate old attribute data
                    UPDATE features.feature_attribute_value SET is_active = FALSE
                    WHERE feature_uuid=i_feature_uuid AND is_active = TRUE and changeset_id != i_feature_changeset AND attribute_id = v_attr_id;
                END IF;
        END IF;

    END LOOP;

    RETURN core_utils.get_event_by_uuid(i_feature_uuid);
END;

$$;


-- *
-- core_utils.get_event_by_uuid
-- *

CREATE OR REPLACE FUNCTION core_utils.get_event_by_uuid(i_uuid UUID)
    RETURNS TEXT AS
$BODY$
SELECT coalesce(jsonb_agg(d.row) :: TEXT, '[]') AS data
FROM (
       SELECT jsonb_build_object(
                  '_feature_uuid', ft.feature_uuid :: TEXT,
                  '_created_date', chg.ts_created,
                  '_data_captor', wu.email,
                  '_geometry', ARRAY [ST_X(ft.point_geometry), ST_Y(ft.point_geometry)]
              ) || coalesce(attributes.row, '{}' :: JSONB) AS row
       FROM
         features.feature ft

             LEFT JOIN LATERAL (
                       SELECT
                           fav.feature_uuid,
                           jsonb_object_agg(
                               dg.key || '/' || da.key,
                                row_to_json(fav) -> CASE
                                                                WHEN da.result_type = 'Integer'
                                                                    THEN 'val_int'
                                                                WHEN da.result_type = 'Decimal'
                                                                    THEN 'val_real'
                                                                WHEN da.result_type = 'Text'
                                                                    THEN 'val_text'
                                                                WHEN da.result_type = 'DropDown'
                                                                    THEN 'val_int'
                                                                WHEN da.result_type = 'MultipleChoice'
                                                                    THEN 'val_text'
                                                                ELSE NULL
                                                                END
                            ) AS row
                       FROM
                           features.feature_attribute_value fav
                           JOIN public.attributes_attribute da ON da.id = fav.attribute_id
                           JOIN public.attributes_attributegroup dg ON dg.id = da.attribute_group_id
                       WHERE
                           fav.feature_uuid = ft.feature_uuid
                           AND fav.is_active = TRUE
                       GROUP BY fav.feature_uuid
                       ) attributes ON TRUE

                 JOIN features.changeset chg ON ft.changeset_id = chg.id
             JOIN webusers_webuser wu ON chg.webuser_id = wu.id

       WHERE
         ft.feature_uuid = $1
         AND ft.is_active = TRUE
       GROUP BY ft.feature_uuid, chg.ts_created, wu.email, ft.point_geometry,
         attributes.row
       ORDER BY ft.feature_uuid) d;
$BODY$
LANGUAGE SQL
STABLE
COST 100;
