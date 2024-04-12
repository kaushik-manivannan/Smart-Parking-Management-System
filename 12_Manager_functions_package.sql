CREATE OR REPLACE PACKAGE spms_manager_management_pkg AS

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