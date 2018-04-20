-- *
-- Create superuser `admin@example.com` with password `admin`
-- *
INSERT INTO public.webusers_webuser (id, password, last_login, email, full_name, is_active, is_staff) VALUES (1, 'pbkdf2_sha256$36000$sY5yuQ0CPLoY$nIMAXnQnL5IhxLwqAWQwL6SQ1IPp0X4yNd20trNiR+8=', null, 'admin@example.com', 'admin', true, true);
INSERT INTO public.webusers_webuser (id, password, last_login, email, full_name, is_active, is_staff, geofence) VALUES (2, 'pbkdf2_sha256$36000$rksSvRlrFIB6$ZOA2Mm7yP0I2Y7WNhQ2Xeo7F6ButK7AXdHEh7fKCRks=', null, 'user@example.com', 'user', true, false, '0103000020E6100000010000000700000067752A162717434076342E27A6A32C40D5B81C159C0443406F4DCA7682672C40C303F1F3AA1D434006E763B051152C40EA685CEE383543409C94ADE965372C401F97A311404143409B9E856988712C40EA685CEE38354340C6F918DCB0B52C4067752A162717434076342E27A6A32C40');


-- *
-- Load basic feature information
-- *

INSERT INTO features.changeset (
    id,
    webuser_id,
    ts_created
) select
    1 as id,
    1 as webuser_id,
    '2017-06-01T00:00:00' as ts_created;


INSERT INTO features.feature (
    feature_uuid,
    point_geometry,
    changeset_id,
    upstream_id
) select
    uuid_generate_v4() as feature_uuid,
    ST_SetSRID(ST_Point(Longitude::double precision, Latitude::double precision), 4326) as point_geometry,
    1 as changeset_id,
    id as upstream_id
from
    test_data.import_raw_data_2;


INSERT INTO
    public.attributes_attributegroup (id, label, key, position)
VALUES (1, 'General', 'general', 0);

INSERT INTO
    public.attributes_attributegroup (id, label, key, position)
VALUES (2, 'Group1', 'group1', 1);

INSERT INTO
    public.attributes_attributegroup (id, label, key, position)
VALUES (3, 'Group2', 'group2', 2);

INSERT INTO
    public.attributes_attributegroup (id, label, key, position)
VALUES (4, 'Group3', 'group3', 3);

INSERT INTO
    public.attributes_attributegroup (id, label, key, position)
VALUES (5, 'Group4', 'group4', 4 );


-- attributes


SELECT core_utils.load_text_attribute('Unique_Id', 'Unique id', 'unique_id', 1, False, True, False);

SELECT core_utils.load_dropdown_attribute('Zone', 'Zone', 'zone', 1, False, True, False);

SELECT core_utils.load_dropdown_attribute('Woreda', 'Woreda', 'woreda', 1, False, True, False);

SELECT core_utils.load_dropdown_attribute('Tabiya', 'Tabiya', 'tabiya', 1, False, True, False);

SELECT core_utils.load_dropdown_attribute('Kushet', 'Kushet', 'kushet', 1, False, True, False);

SELECT core_utils.load_text_attribute('Site_Name', 'Name', 'name', 1, True, True, False);

SELECT core_utils.load_dropdown_attribute('Scheme_Type', 'Scheme Type', 'scheme_type', 2, False, True, False);

SELECT core_utils.load_integer_attribute('Year_of_Construction', 'Year of Construction', 'construction_year', 2, False, True, False);

SELECT core_utils.load_dropdown_attribute('Result', 'Result', 'result', 2, False, True, False);

SELECT core_utils.load_decimal_attribute('Depth', 'Depth', 'depth', 2, False, True, False);

SELECT core_utils.load_decimal_attribute('Yield', 'Yield', 'yield', 2, False, True, False);

SELECT core_utils.load_decimal_attribute('Static_Water_Level', 'Static Water Level', 'static_water_level', 2, False, True, False);

SELECT core_utils.load_dropdown_attribute('Pump_Type', 'Pump Type', 'pump_type', 2, False, True, False);

SELECT core_utils.load_dropdown_attribute('Power_Source', 'Power Source', 'power_source', 2, False, True, False);

SELECT core_utils.load_dropdown_attribute('Functioning', 'Functioning', 'functioning', 2, False, True, False);

SELECT core_utils.load_text_attribute('Reason_of_Non_Functioning', 'Reason of Non Functioning', 'reason_of_non_functioning', 2, False, True, False);

SELECT core_utils.load_dropdown_attribute('Intervention_Required', 'Intervention Required', 'intervention_required', 2, False, True, False);

SELECT core_utils.load_integer_attribute('Beneficiaries', 'Beneficiaries', 'beneficiaries', 3, False, True, False);

SELECT core_utils.load_integer_attribute('"Female Beneficiaries"', 'Female Beneficiaries', 'female_beneficiaries', 3, False, True, False);

SELECT core_utils.load_integer_attribute('Livestock', 'Livestock', 'livestock', 3, False, True, False);

SELECT core_utils.load_dropdown_attribute('Water_Committe_Exist', 'Water Committe Exist', 'water_committe_exist', 3, False, True, False);

SELECT core_utils.load_dropdown_attribute('"Bylaw /Sirit/"', 'Bylaw Sirit', 'bylaw_sirit', 3, False, True, False);

SELECT core_utils.load_dropdown_attribute('"Fund Raise"', 'Fund Raise', 'fund_raise', 3, False, True, False);

SELECT core_utils.load_decimal_attribute('"Amount of Fund Deposit"', 'Amount of Fund Deposit', 'amount_of_deposited', 3, False, True, False);

SELECT core_utils.load_dropdown_attribute('"Bank Book"', 'Bank Book', 'bank_book', 3, False, True, False);

SELECT core_utils.load_dropdown_attribute('Fencing_Exist', 'Fencing Exist', 'fencing_exists', 4, False, True, False);

SELECT core_utils.load_dropdown_attribute('Guard', 'Guard', 'guard', 4, False, True, False);

SELECT core_utils.load_decimal_attribute('Ave_Dist_from_near_Village', 'Ave Dist from near Village', 'ave_dist_from_near_village', 4, False, True, False);

SELECT core_utils.load_dropdown_attribute('Funded_By', 'Funded By', 'funded_by', 4, False, True, False);

SELECT core_utils.load_dropdown_attribute('Constructed_By', 'Constructed By', 'constructed_by', 4, False, True, False);

SELECT core_utils.load_dropdown_attribute('General_Condition', 'General Condition', 'general_condition', 4, False, True, False);

SELECT core_utils.load_dropdown_attribute('Name_of_Data_Collector', 'Name of Data Collector', 'name_of_data_collector', 5, False, True, False);

SELECT core_utils.load_text_attribute('Date_of_Data_Collection', 'Date of Data Collection', 'date_of_data_collection', 5, False, True, False);

SELECT core_utils.load_text_attribute('Name_and_tel_of_Contact_Person', 'Name and tel of Contact Person', 'name_and_tel_of_contact_person', 5, False, True, False);

SELECT core_utils.load_decimal_attribute('Latitude', 'Latitude', 'latitude', 5, False, True, False);

SELECT core_utils.load_decimal_attribute('Longitude', 'Longitude', 'longitude', 5, False, True, False);

SELECT core_utils.load_decimal_attribute('Altitude', 'Altitude', 'altitude', 5, False, True, False);

SELECT core_utils.load_text_attribute('Picture_of_Scehem', 'Picture of Scehem', 'picture_of_scehem', 5, False, True, False);
-----------------------------------------------------------

-- *
-- Restart sequences
-- *

SELECT setval('public.webusers_webuser_id_seq', COALESCE((SELECT MAX(id)+1 FROM public.webusers_webuser), 1), false);
SELECT setval('features.changeset_id_seq', COALESCE((SELECT MAX(id)+1 FROM features.changeset), 1), false);
SELECT setval('public.attributes_attributegroup_id_seq', COALESCE((SELECT MAX(id)+1 FROM public.attributes_attributegroup), 1), false);
SELECT setval('public.attributes_attribute_id_seq', COALESCE((SELECT MAX(id)+1 FROM public.attributes_attribute), 1), false);

-- *
-- * Refresh active data materialized view
-- *

select core_utils.refresh_active_data();
