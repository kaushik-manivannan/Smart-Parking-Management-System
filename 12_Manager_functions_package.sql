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



END spms_manager_management_pkg;
/