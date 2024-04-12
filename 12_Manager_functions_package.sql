SET SERVEROUTPUT ON
CLEAR SCREEN;

CREATE OR REPLACE PACKAGE spms_manager_management_pkg AS

    -- Declare custom exceptions for each column
    invalid_name EXCEPTION;
    invalid_street_address EXCEPTION;
    invalid_city EXCEPTION;
    invalid_state EXCEPTION;
    invalid_country EXCEPTION;
    invalid_zip_code EXCEPTION;
    invalid_latitude EXCEPTION;
    invalid_longitude EXCEPTION;
    invalid_pricing_per_hour EXCEPTION;
    invalid_floor_level EXCEPTION;
    invalid_max_height EXCEPTION;
    invalid_slot_name EXCEPTION;

    -- Declare custom exceptions for length validation
    invalid_name_length EXCEPTION;
    invalid_street_address_length EXCEPTION;
    invalid_city_length EXCEPTION;
    invalid_state_length EXCEPTION;
    invalid_country_length EXCEPTION;
    invalid_zip_code_length EXCEPTION;
    invalid_floor_level_length EXCEPTION;
    invalid_slot_name_length EXCEPTION;

    --other validations
    address_already_exists EXCEPTION;
    parking_lot_already_exists EXCEPTION;
    already_address_exists_with_lat_long EXCEPTION;
    null_input EXCEPTION;
    address_not_exists EXCEPTION;
    parking_lot_not_exists EXCEPTION;
    parking_lot_or_address_not_exists EXCEPTION;
    floor_name_already_exists EXCEPTION;
    floor_does_not_exists EXCEPTION;
    slot_name_already_exists EXCEPTION;

    PROCEDURE spms_add_parking_lot (
        p_name             VARCHAR,
        p_street_address   VARCHAR,
        p_city             VARCHAR,
        p_state            VARCHAR,
        p_country          VARCHAR,
        p_zip_code         VARCHAR,
        p_latitude         DECIMAL,
        p_longitude        DECIMAL,
        p_pricing_per_hour DECIMAL
    );

    PROCEDURE spms_add_floor (
        p_parking_lot_name VARCHAR,
        p_street_address   VARCHAR,
        p_city             VARCHAR,
        p_zip_code         VARCHAR,
        p_floor_level      VARCHAR,
        p_max_height       DECIMAL
    );

    PROCEDURE spms_add_parking_slot (
        p_parking_lot_name VARCHAR,
        p_street_address   VARCHAR,
        p_city             VARCHAR,
        p_zip_code         VARCHAR,
        p_floor_level      VARCHAR,
        p_slot_name        VARCHAR
    );

END spms_manager_management_pkg;
/

CREATE OR REPLACE PACKAGE BODY spms_manager_management_pkg AS


    PROCEDURE spms_add_parking_lot (
        p_name             VARCHAR,
        p_street_address   VARCHAR,
        p_city             VARCHAR,
        p_state            VARCHAR,
        p_country          VARCHAR,
        p_zip_code         VARCHAR,
        p_latitude         DECIMAL,
        p_longitude        DECIMAL,
        p_pricing_per_hour DECIMAL
    ) AS

        v_address_id      NUMBER;
        v_parking_lot_id  NUMBER;
        v_name            VARCHAR(100);
        v_street_address  VARCHAR(50);
        v_city            VARCHAR(20);
        v_state           VARCHAR(20);
        v_country         VARCHAR(20);
        v_zip_code        VARCHAR(10);
        v_next_address_id NUMBER;
BEGIN
        -- Trim string values
        v_name := upper(trim(p_name));
        v_street_address := upper(trim(p_street_address));
        v_city := upper(trim(p_city));
        v_state := upper(trim(p_state));
        v_country := upper(trim(p_country));
        v_zip_code := upper(trim(p_zip_code));

        -- Validate inputs
        IF v_name IS NULL OR v_street_address IS NULL OR v_city IS NULL OR v_state IS NULL OR v_country IS NULL OR v_zip_code IS NULL
        OR p_pricing_per_hour IS NULL OR p_latitude IS NULL OR p_longitude IS NULL THEN
            RAISE null_input;
            --raise_application_error(-20001, 'All fields are required.');
END IF;

        IF length(v_name) > 50 THEN
            RAISE invalid_name_length;
END IF;
        IF length(v_street_address) > 50 THEN
            RAISE invalid_street_address_length;
END IF;
        IF length(v_state) > 20 THEN
            RAISE invalid_state_length;
END IF;
        IF length(v_country) > 20 THEN
            RAISE invalid_country_length;
END IF;
        IF length(v_zip_code) > 10 THEN
            RAISE invalid_zip_code_length;
END IF;
        IF length(v_city) > 20 THEN
            RAISE invalid_city_length;
END IF;

        IF NOT regexp_like(v_street_address, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_street_address;
END IF;

      --Regex validation for city
        IF NOT regexp_like(v_city, '^[A-Z]+(\s[A-Z]+)*$') THEN
            RAISE invalid_city;
END IF;

        IF NOT regexp_like(v_name, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_name;
END IF;
--
         IF NOT regexp_like(v_state, '^[A-Z]+(\s[A-Z]+)*$') THEN
            RAISE invalid_state;
END IF;

         IF NOT regexp_like(v_country, '^[A-Z]+(\s[A-Z]+)*$') THEN
            RAISE invalid_country;
END IF;



        -- Regex validation
        IF NOT regexp_like(v_zip_code, '^\d{5}(-\d{4})?$') THEN
            RAISE invalid_zip_code;
END IF;
        IF p_latitude < -90.0 OR p_latitude > 90.0 THEN
            RAISE invalid_latitude;
END IF;
        IF p_longitude < -180.0 OR p_longitude > 180.0 THEN
            RAISE invalid_longitude;
END IF;
        IF p_pricing_per_hour < 0 OR p_pricing_per_hour > 999.99 THEN
            RAISE invalid_pricing_per_hour;
END IF;

        -- Get the next value of the address sequence
SELECT
    address_val.NEXTVAL
INTO v_next_address_id
FROM
    dual;

-- Check if address already exists
BEGIN
SELECT
    address_id
INTO v_address_id
FROM
    address
WHERE
        street_address = v_street_address
  AND city = v_city
  AND state = v_state
  AND country = v_country
  AND zip_code = v_zip_code;

EXCEPTION
            WHEN no_data_found THEN
                v_address_id := NULL; -- Set v_address_id to NULL if no data found
END;

        IF v_address_id IS NOT NULL THEN
            RAISE address_already_exists;
            --raise_application_error(-20002, 'Address already exists.');
END IF;

        -- Check if latitude and longitude are unique
BEGIN
SELECT
    COUNT(*)
INTO v_address_id
FROM
    address
WHERE
        latitude = p_latitude
  AND longitude = p_longitude;

-- If no rows are found, set v_address_id to 0
IF v_address_id IS NULL THEN
                v_address_id := 0;
END IF;
EXCEPTION
            WHEN no_data_found THEN
                v_address_id := 0;
END;

        IF v_address_id > 0 THEN
            RAISE already_address_exists_with_lat_long;
            --raise_application_error(-20003, 'Latitude and longitude should be unique.');
END IF;

        -- Insert new address
INSERT INTO address (
    address_id,
    street_address,
    city,
    state,
    country,
    zip_code,
    latitude,
    longitude
) VALUES (
             v_next_address_id,
             v_street_address,
             v_city,
             v_state,
             v_country,
             v_zip_code,
             p_latitude,
             p_longitude
         );

-- Insert new parking lot
BEGIN
SELECT
    parking_lot_id
INTO v_parking_lot_id
FROM
    parking_lot
WHERE
        name = v_name
  AND address_id = v_address_id;

EXCEPTION
            WHEN no_data_found THEN
                v_parking_lot_id := NULL; -- Set v_parking_lot_id to NULL if no data found
END;

        IF v_parking_lot_id IS NOT NULL THEN
            RAISE parking_lot_already_exists;
            --raise_application_error(-20004, 'Parking lot already exists with the same name and address.');
END IF;
INSERT INTO parking_lot (
    parking_lot_id,
    name,
    address_id,
    pricing_per_hour
) VALUES (
             parking_lot_id_val.NEXTVAL,
             v_name,
             v_next_address_id,
             p_pricing_per_hour
         );

COMMIT;
EXCEPTION
        WHEN invalid_zip_code THEN
            dbms_output.put_line('Invalid zip code format');
ROLLBACK;
RETURN;
WHEN invalid_latitude THEN
            dbms_output.put_line('Invalid latitude. Latitude must be between -90 and 90.');
ROLLBACK;
RETURN;
WHEN invalid_longitude THEN
            dbms_output.put_line('Invalid longitude. Longitude must be between -180 and 180.');
ROLLBACK;
RETURN;
WHEN invalid_pricing_per_hour THEN
            dbms_output.put_line('Invalid pricing per hour. Must be between 0 and 999.99.');
ROLLBACK;
RETURN;
WHEN invalid_street_address THEN
            dbms_output.put_line('Invalid Street Address');
ROLLBACK;
RETURN;
WHEN invalid_city THEN
            dbms_output.put_line('Invalid city format.');
            --ROLLBACK;
            RETURN;
WHEN invalid_city_length THEN
            dbms_output.put_line('Invalid city length, max length 20');
ROLLBACK;
RETURN;
WHEN invalid_name_length THEN
            dbms_output.put_line('Parking lot name length exceeded the maximum length 50');
ROLLBACK;
RETURN;
WHEN invalid_name THEN
            dbms_output.put_line('Invalid Parkling lot name format');
ROLLBACK;
RETURN;
WHEN invalid_street_address_length THEN
            dbms_output.put_line('Street address length exceeded the maximum length 50');
ROLLBACK;
RETURN;
WHEN invalid_state_length THEN
            dbms_output.put_line('State length exceeded the maximum length 20');
ROLLBACK;
RETURN;
WHEN invalid_zip_code_length THEN
            dbms_output.put_line('Zip Code length exceeded the maximum length 10');
ROLLBACK;
RETURN;
WHEN invalid_country_length THEN
            dbms_output.put_line('Country length exceeded the maximum length 20');
ROLLBACK;
RETURN;
WHEN address_already_exists THEN
            dbms_output.put_line('Address already exists');
ROLLBACK;
RETURN;
WHEN parking_lot_already_exists THEN
            dbms_output.put_line('Parking lot already exists with the same name and address.');
ROLLBACK;
RETURN;
WHEN already_address_exists_with_lat_long THEN
            dbms_output.put_line('Already an address exists lat/long, Latitude and longitude should be unique.');
ROLLBACK;
RETURN;
WHEN null_input THEN
            dbms_output.put_line('Please provide a valid input for the fields, All fields are required');
ROLLBACK;
RETURN;
WHEN invalid_state THEN
            dbms_output.put_line('Invalid State format, accepts only alphabets');
ROLLBACK;
RETURN;
WHEN invalid_country THEN
            dbms_output.put_line('Invalid Country format, accepts only alphabets');
ROLLBACK;
RETURN;
WHEN OTHERS THEN
            dbms_output.put_line('Not able to add parking lot details');
            --RAISE; -- Re-raise the exception to the calling code
ROLLBACK;
RETURN;
END spms_add_parking_lot;

    PROCEDURE spms_add_floor (
        p_parking_lot_name VARCHAR,
        p_street_address   VARCHAR,
        p_city             VARCHAR,
        p_zip_code         VARCHAR,
        p_floor_level      VARCHAR,
        p_max_height       DECIMAL
    ) AS
        v_parking_lot_id   NUMBER;
        v_address_id       NUMBER;
        v_parking_lot_name VARCHAR(100);
        v_street_address   VARCHAR(100);
        v_city             VARCHAR(50);
        v_zip_code         VARCHAR(10);
        v_floor_level      VARCHAR(100);
        v_floor_count      NUMBER;
BEGIN
        -- Trim string values and convert to lowercase
        v_parking_lot_name := upper(trim(p_parking_lot_name));
        v_street_address := upper(trim(p_street_address));
        v_city := upper(trim(p_city));
        v_zip_code := upper(trim(p_zip_code));
        v_floor_level := upper(trim(p_floor_level));

        -- Validate inputs
        IF v_parking_lot_name IS NULL OR v_street_address IS NULL OR v_city IS NULL OR v_zip_code IS NULL OR v_floor_level IS NULL
        OR p_max_height IS NULL THEN
            RAISE null_input;
            --raise_application_error(-20005, 'Parking lot name, street address, city, zip code, and floor level are required.');
END IF;

        IF length(v_parking_lot_name) > 50 THEN
            RAISE invalid_name_length;
END IF;
        IF length(v_street_address) > 50 THEN
            RAISE invalid_street_address_length;
END IF;
        IF length(v_zip_code) > 10 THEN
            RAISE invalid_zip_code_length;
END IF;
        IF length(v_city) > 20 THEN
            RAISE invalid_city_length;
END IF;
        IF length(v_floor_level) > 5 THEN
            RAISE invalid_floor_level_length;
END IF;

         IF NOT regexp_like(v_parking_lot_name, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_name;
END IF;

        IF NOT regexp_like(v_street_address, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_street_address;
END IF;

        -- Regex validation for city
        IF NOT regexp_like(v_city,  '^[A-Z]+(\s[A-Z]+)*$') THEN
            RAISE invalid_city;
            --raise_application_error(-20007, 'Invalid city format.');
END IF;

        -- Regex validation for zip code
        IF NOT regexp_like(v_zip_code, '^\d{5}(-\d{4})?$') THEN
            RAISE invalid_zip_code;
            --raise_application_error(-20008, 'Invalid zip code format.');
END IF;

        -- Regex validation for floor level ^[A-Za-z0-9 ]{1,5}$
        IF NOT regexp_like(v_floor_level, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_floor_level;
            --raise_application_error(-20009, 'Invalid floor level format.');
END IF;

        IF p_max_height < 10 OR p_max_height > 15 THEN
            RAISE invalid_max_height;
END IF;

        -- Get address ID and parking lot ID
BEGIN
SELECT
    a.address_id,
    pl.parking_lot_id
INTO
    v_address_id,
    v_parking_lot_id
FROM
    address a
        JOIN parking_lot pl ON a.address_id = pl.address_id
WHERE
        a.street_address = v_street_address
  AND a.city = v_city
  AND a.zip_code = v_zip_code
  AND pl.name = v_parking_lot_name;
EXCEPTION
                WHEN no_data_found THEN
                    v_address_id := NULL;
                    v_parking_lot_id:= NULL;
END;

         IF v_address_id IS NULL and v_parking_lot_id IS NULL THEN
            RAISE parking_lot_or_address_not_exists;
            --raise_application_error(-20011, 'Address does not exist.');
END IF;

        IF v_address_id IS NULL THEN
            RAISE address_not_exists;
            --raise_application_error(-20011, 'Address does not exist.');
END IF;
        IF v_parking_lot_id IS NULL THEN
            RAISE parking_lot_not_exists;
            --raise_application_error(-20012, 'Parking lot does not exist for the provided address.');
END IF;


BEGIN
SELECT COUNT(*)
INTO v_floor_count
FROM address a
         JOIN parking_lot pl ON a.address_id = pl.address_id
         JOIN floor f ON pl.parking_lot_id = f.parking_lot_id
WHERE
        a.street_address = v_street_address
  AND a.city = v_city
  AND a.zip_code = v_zip_code
  AND pl.name = v_parking_lot_name
  AND f.floor_level = v_floor_level;

IF v_floor_count > 0 THEN
                RAISE floor_name_already_exists;
END IF;

EXCEPTION
            WHEN no_data_found THEN
                    v_floor_count := 0;

END;

    IF v_floor_count > 0 THEN
            RAISE floor_name_already_exists;
END IF;


        -- Insert new floor
INSERT INTO floor (
    floor_id,
    parking_lot_id,
    floor_level,
    max_height
) VALUES (
             floor_id_val.NEXTVAL,
             v_parking_lot_id,
             v_floor_level,
             p_max_height
         );

COMMIT;
EXCEPTION
        WHEN floor_name_already_exists THEN
            dbms_output.put_line('Floor name already exists for the given address and parking lot');
ROLLBACK;
RETURN;
WHEN invalid_max_height THEN
            dbms_output.put_line('Invalid Max Height,range is between 10 to 15 feet');
ROLLBACK;
RETURN;
WHEN parking_lot_or_address_not_exists THEN
            dbms_output.put_line('Parking lot/Address does not exists');
ROLLBACK;
RETURN;
WHEN null_input THEN
            dbms_output.put_line('Please provide a valid input for the fields, All fields are required');
ROLLBACK;
RETURN;
WHEN invalid_name_length THEN
            dbms_output.put_line('Please provide a valid parking lot name, max length 50 exceeded');
ROLLBACK;
RETURN;
WHEN invalid_street_address_length THEN
            dbms_output.put_line('Street address length exceeded the maximum length 50');
ROLLBACK;
RETURN;
WHEN invalid_zip_code_length THEN
            dbms_output.put_line('Zip Code length exceeded the maximum length 10');
ROLLBACK;
RETURN;
WHEN invalid_city_length THEN
            dbms_output.put_line('Invalid city length, max length 20');
ROLLBACK;
RETURN;
WHEN invalid_floor_level_length THEN
            dbms_output.put_line('Floor level length exceeded the maximum length 5');
ROLLBACK;
RETURN;
WHEN invalid_street_address THEN
            dbms_output.put_line('Invalid Street Address');
ROLLBACK;
RETURN;
WHEN invalid_city THEN
            dbms_output.put_line('Invalid city format.');
ROLLBACK;
RETURN;
WHEN invalid_zip_code THEN
            dbms_output.put_line('Invalid zip code format');
ROLLBACK;
RETURN;
WHEN invalid_floor_level THEN
            dbms_output.put_line('Invalid floor level');
ROLLBACK;
RETURN;
WHEN address_not_exists THEN
            dbms_output.put_line('Address not exists, provide valid address details');
ROLLBACK;
RETURN;
WHEN invalid_name THEN
            dbms_output.put_line('Invalid Parkling lot name format');
ROLLBACK;
RETURN;
WHEN parking_lot_not_exists THEN
            dbms_output.put_line('Parking does not exists, provide a valid parking lot name');
ROLLBACK;
RETURN;
WHEN OTHERS THEN
            dbms_output.put_line('Not able to add parking floor details');
ROLLBACK;
RAISE;
RETURN;
END spms_add_floor;

    PROCEDURE spms_add_parking_slot (
        p_parking_lot_name VARCHAR,
        p_street_address   VARCHAR,
        p_city             VARCHAR,
        p_zip_code         VARCHAR,
        p_floor_level      VARCHAR,
        p_slot_name        VARCHAR
    ) AS

        v_floor_id         NUMBER;
        v_parking_lot_name VARCHAR(100);
        v_street_address   VARCHAR(100);
        v_city             VARCHAR(100);
        v_zip_code         VARCHAR(10);
        v_floor_level      VARCHAR(100);
        v_slot_name        VARCHAR(100);
        v_slot_count       NUMBER;
BEGIN
        -- Trim string values and convert to uppercase
        v_parking_lot_name := upper(trim(p_parking_lot_name));
        v_street_address := upper(trim(p_street_address));
        v_city := upper(trim(p_city));
        v_zip_code := upper(trim(p_zip_code));
        v_floor_level := upper(trim(p_floor_level));
        v_slot_name := upper(trim(p_slot_name));

        -- Validate inputs
        IF v_parking_lot_name IS NULL OR v_street_address IS NULL OR v_city IS NULL OR v_zip_code IS NULL OR v_floor_level IS NULL OR
        v_slot_name IS NULL THEN
            RAISE null_input;
            --raise_application_error(-20007, 'Parking lot name, street address, city, zip code, floor level, and slot name are required.');
END IF;

        IF length(v_parking_lot_name) > 50 THEN
            RAISE invalid_name_length;
END IF;
        IF length(v_floor_level) > 20 THEN
            RAISE invalid_floor_level_length;
END IF;
        IF length(v_street_address) > 50 THEN
            RAISE invalid_street_address_length;
END IF;
        IF length(v_city) > 20 THEN
            RAISE invalid_city_length;
END IF;
        IF length(v_zip_code) > 10 THEN
            RAISE invalid_zip_code_length;
END IF;
        IF length(v_slot_name) > 5 THEN
            RAISE invalid_slot_name_length;
END IF;


        IF NOT regexp_like(v_floor_level, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_floor_level;
            --raise_application_error(-20009, 'Invalid floor level format.');
END IF;
        IF NOT regexp_like(v_street_address, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_street_address;
END IF;
        IF NOT regexp_like(v_city,  '^[A-Z]+(\s[A-Z]+)*$') THEN
            RAISE invalid_city;
            --raise_application_error(-20007, 'Invalid city format.');
END IF;
        IF NOT regexp_like(v_zip_code, '^\d{5}(-\d{4})?$') THEN
            RAISE invalid_zip_code;
            --raise_application_error(-20008, 'Invalid zip code format.');
END IF;

                -- Regex validation for parking slot name
        IF NOT regexp_like(v_slot_name, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_slot_name;
            --raise_application_error(-20013, 'Invalid parking slot name format.');
END IF;

       IF NOT regexp_like(v_parking_lot_name, '^[A-Z0-9]+(\s[A-Z0-9]+)*$') THEN
            RAISE invalid_name;
END IF;

        -- Get floor ID
BEGIN
SELECT
    f.floor_id
INTO v_floor_id
FROM
    floor f
        JOIN parking_lot pl ON f.parking_lot_id = pl.parking_lot_id
        JOIN address     a ON pl.address_id = a.address_id
WHERE
        pl.name = v_parking_lot_name
  AND a.street_address = v_street_address
  AND a.city = v_city
  AND a.zip_code = v_zip_code
  AND f.floor_level = v_floor_level;

IF v_floor_id IS NULL  THEN
            RAISE floor_does_not_exists;
END IF;

EXCEPTION
        WHEN no_data_found THEN
                v_floor_id := NULL;

END;

        IF v_floor_id IS NULL THEN
            raise floor_does_not_exists;
END IF;


BEGIN
SELECT COUNT(*)
INTO v_slot_count
FROM parking_slot ps
WHERE ps.floor_id = v_floor_id
  AND ps.slot_name = v_slot_name;

IF v_slot_count > 0 THEN
                RAISE slot_name_already_exists;
END IF;

EXCEPTION
            WHEN no_data_found THEN
                v_slot_count := 0;
END;

        IF v_slot_count > 0 THEN
                RAISE slot_name_already_exists;
END IF;

        -- Insert new parking slot
INSERT INTO parking_slot (
    parking_slot_id,
    floor_id,
    slot_name
) VALUES (
             parking_slot_id_val.NEXTVAL,
             v_floor_id,
             v_slot_name
         );

COMMIT;
EXCEPTION
        WHEN slot_name_already_exists THEN
            dbms_output.put_line('Slot name already exists for the fiven floor and parking lot');
ROLLBACK;
RETURN;
WHEN floor_does_not_exists THEN
            dbms_output.put_line('Floor/Parking lot/Address does not exists');
ROLLBACK;
RETURN;
WHEN invalid_name_length THEN
            dbms_output.put_line('Please provide a valid parking lot name, max length 50 exceeded');
ROLLBACK;
RETURN;
WHEN invalid_floor_level_length THEN
            dbms_output.put_line('Floor level length exceeded the maximum length 5');
ROLLBACK;
RETURN;
WHEN invalid_street_address_length THEN
            dbms_output.put_line('Street address length exceeded the maximum length 50');
ROLLBACK;
RETURN;
WHEN invalid_city_length THEN
            dbms_output.put_line('Invalid city length, max length 20');
ROLLBACK;
RETURN;
WHEN invalid_zip_code_length THEN
            dbms_output.put_line('Zip Code length exceeded the maximum length 10');
ROLLBACK;
RETURN;
WHEN invalid_slot_name_length THEN
            dbms_output.put_line('Slot name length exceeded the maximum length 5');
ROLLBACK;
RETURN;
WHEN invalid_floor_level THEN
            dbms_output.put_line('Invalid floor level');
ROLLBACK;
RETURN;
WHEN invalid_street_address THEN
            dbms_output.put_line('Invalid Street Address');
ROLLBACK;
RETURN;
WHEN invalid_city THEN
            dbms_output.put_line('Invalid city format.');
ROLLBACK;
RETURN;
WHEN invalid_zip_code THEN
            dbms_output.put_line('Invalid zip code format');
ROLLBACK;
RETURN;
WHEN invalid_slot_name THEN
            dbms_output.put_line('Invalid slot name format');
ROLLBACK;
RETURN;
WHEN invalid_name THEN
            dbms_output.put_line('Invalid Parkling lot name format');
ROLLBACK;
RETURN;
WHEN OTHERS THEN
            dbms_output.put_line('Not able to add parking slot details');
            RAISE;
ROLLBACK;
RETURN;

END spms_add_parking_slot;

END spms_manager_management_pkg;
/




-- Adding parking lot Validation
--
-- null check
-- -- parking lot null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('', '123 Main St','Boston', 'Massachusetts', 'United States', '12345-2344', 40.7128, -74.0060, 10.50);
-- -- stree addr null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '','Boston', 'Massachusetts', 'United States', '12345-2344', 40.7128, -74.0060, 10.50);
-- -- state null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','', 'Massachusetts', 'United States', '12345-2344',1, -49.0, 10.0);
-- -- city null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','lksalk', '', 'United States', '12345-2344',1, -49.0, 10.0);
-- -- zip code null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','lksalk', 'dkdk', 'United States', NULL,1, -49.0, 10.0);
-- -- country null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','lksalk', 'dkdk', '', '12345-2344',1, -49.0, 10.0);
-- -- latitude null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','Boston', 'Massachusetts', 'United States', '12345-2344',NULL , -74.0060, 10.50);
-- -- longitude null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','Boston', 'Massachusetts', 'United States', '12345-2344',1, NULL, 10.50);
-- -- pricing per hour null
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','Boston', 'Massachusetts', 'United States', '12345-2344',1, -49.0, NULL);
--
--
--
-- -- special characters in state
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','Boston', 'Massachus]]etts', 'United States', '12345-2344', 12, -74.0060, 10.50);
-- -- special characters in city
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','Bos?ton', 'Massachusetts', 'United States', '12345-2344', 12, -74.0060, 10.50);
-- -- special characters in street address
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa l;kk','Boston', 'Massachusetts', 'United States', '12345-2344', 12, -74.0060, 10.50);
-- -- in country
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Center', '12 sallsa lkk','lksalk', 'dkdk', 'klklfd,mm,cz]', '12345-2344',1, -49.0, 10.0);
-- -- parking lot
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('City Cente[]r', '123 main street','Boston', 'Massachusetts', 'Uniter States', '12345-2344',1, -49.0, 10.0);
-- Invalid Zipcode
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('Parking Lot 12', '123 Main St','Boston', 'Massachusetts', 'United States', '12345-234', 40.7128, -74.0060, 10.50);
--
--
-- Valid
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('Parking Lot 12', '123 Main St','Boston', 'Massachusetts', 'United States', '12345-2344', 89.9, 94.090, 10.50);
--
-- Address Already Exists
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('Parking Lot 12', '123 Main St','Boston', 'Massachusetts', 'United States', '12345-2344', 74.9, 95.090, 12.50);
--
--
--
--
-- ---------------------  testcase for Adding parking floor ---------
--
-- -- invalid parking lot name format
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12]','123 Simon St','Boston', '20120-6007', 'F1', 10.5);
--
-- -- invalid street address
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simo[n St','Boston', '20120-6007', 'F1', 10.5);
-- -- height exceeds max range
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','Boston', '20120-6007', 'F1', 20);
-- -- floor level length exceeded
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','Boston', '20120-6007', 'F1saallk;la;las', 10.5);
--
--
-- null
--
-- - state
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','', '20120-6007', 'F1', 10.5);
-- - parking lot name null
-- EXEC spms_manager_management_pkg.spms_add_floor('','123 Simon St','Boston', '20120-6007', 'F1', 10.5);
-- -- streer address null
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','','Boston', '20120-6007', 'F1', 10.5);
-- -- city null
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','', '20120-6007', 'F1', 10.5);
-- -- slot name null
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','Boston', '20120-6007', '', 10.5);
-- -- floor height null
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','Boston', '20120-6007', 'F1', '');
--
--
--
-- Valid
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','Boston', '20120-6007', 'F1', 10.5);
--
-- -- floor name already exists
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','Boston', '20120-6007', 'F1', 10.5);
--
--
--
-- ----- testing for adding slot ---
--
-- valid
-- EXEC spms_manager_management_pkg.spms_add_parking_slot('Parking Lot 12', '123 Simon St','Boston', '20120-6007', 'F1', 'SA');
--
--
--
-- ------- ALl Valid case --
-- -- Adding lot/Address
-- EXEC spms_manager_management_pkg.spms_add_parking_lot('Parking Lot 12', '123 Simon St','Boston', 'Massachusetts', 'United States', '20120-6007',89.9, 94.090, 10.50);
-- -- Adding parkign floor
-- EXEC spms_manager_management_pkg.spms_add_floor('Parking Lot 12','123 Simon St','Boston', '20120-6007', 'F1', '');
-- -Adding parking slot
-- EXEC spms_manager_management_pkg.spms_add_parking_slot('Parking Lot 12', '123 Simon St','Boston', '20120-6007', 'F1', 'SA');
