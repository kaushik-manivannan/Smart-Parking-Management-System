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