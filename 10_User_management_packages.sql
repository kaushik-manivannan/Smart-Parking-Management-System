SET SERVEROUTPUT ON;
SET AUTOCOMMIT ON;
CREATE OR REPLACE PACKAGE spms_customer_management_pkg AS

/* Creating or declaring required packages for Smart parking management system customer management. Under this Package we are creating 3 packages
	1. For customer registration
	2. To add new VEHICLE
	3. To update the customer information
	4. Function to hash password and then store
*/

  /* Custom Exceptions */
    null_name_error EXCEPTION;
    empty_name_error EXCEPTION;
    invalid_name_error EXCEPTION;
    invalid_email_error EXCEPTION;
    invalid_mobile_error EXCEPTION;
    no_customer_found_error EXCEPTION;
    user_exists_error EXCEPTION;
    name_length_exceeded_error EXCEPTION;
    value_error EXCEPTION;
    vehicle_registered_other_error EXCEPTION;
    invalid_registration_no_error EXCEPTION;  
    duplicate_mobile_error EXCEPTION;  


  /* Procedures and Functions */
    PROCEDURE spms_new_customer_insert (
        p_first_name VARCHAR,
        p_last_name  VARCHAR,
        p_email      VARCHAR,
        p_password   VARCHAR,
        p_mobile_no  VARCHAR
    );

    PROCEDURE spms_add_vehicle (
        p_registration_no VARCHAR,
        p_email           VARCHAR
    );

    FUNCTION hash_password (
        p_password VARCHAR
    ) RETURN RAW
        DETERMINISTIC;

    PROCEDURE spms_customer_update (
        p_first_name VARCHAR,
        p_last_name  VARCHAR,
        p_email      VARCHAR,
        p_password   VARCHAR,
        p_mobile_no  VARCHAR
    );

END spms_customer_management_pkg;
/

CREATE OR REPLACE PACKAGE BODY spms_customer_management_pkg AS

  /* Function to hash the provided password. */
    FUNCTION hash_password (
        p_password VARCHAR
    ) RETURN RAW
        DETERMINISTIC
    IS
        v_hashed_password RAW(2000);
    BEGIN
        v_hashed_password := dbms_crypto.hash(utl_i18n.string_to_raw(p_password, 'AL32UTF8'), dbms_crypto.hash_sh1);

        RETURN v_hashed_password;
    END hash_password;
  
  /* Procedure to insert a new customer */
    PROCEDURE spms_new_customer_insert (
        p_first_name VARCHAR,
        p_last_name  VARCHAR,
        p_email      VARCHAR,
        p_password   VARCHAR,
        p_mobile_no  VARCHAR
    ) AS
        v_count INTEGER;
    BEGIN
    -- Check if user already exists
        SELECT
            COUNT(*)
        INTO v_count
        FROM
            customer
        WHERE
            email = p_email
            OR mobile_no = p_mobile_no;

        IF v_count > 0 THEN
            RAISE user_exists_error;
        END IF; 
    -- Perform validation checks
        IF p_first_name IS NULL OR p_last_name IS NULL THEN
            RAISE null_name_error;
        END IF;
        IF length(trim(p_first_name)) = 0 OR length(trim(p_last_name)) = 0 THEN
            RAISE empty_name_error;
        END IF;

        IF length(trim(p_first_name)) > 20 OR length(trim(p_last_name)) > 20 THEN
            RAISE name_length_exceeded_error;
        END IF;

        IF NOT regexp_like(p_first_name, '^[A-Za-z]+$') OR NOT regexp_like(p_last_name, '^[A-Za-z]+$') THEN
            RAISE invalid_name_error;
        END IF;

        IF p_password IS NULL OR length(p_password) < 8 OR length(p_password) > 255 THEN
            RAISE value_error;
        END IF;

        IF p_email IS NULL OR length(p_email) > 255 THEN
            RAISE invalid_email_error;
        END IF;
        IF NOT regexp_like(p_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
            RAISE invalid_email_error;
        END IF;
        IF p_mobile_no IS NULL OR length(trim(p_mobile_no)) = 0 OR length(p_mobile_no) > 12 OR NOT regexp_like(p_mobile_no, '^\d{10,12}$'
        ) THEN
            RAISE invalid_mobile_error;
        END IF;

    -- Insert the new customer
        INSERT INTO customer (
            customer_id,
            first_name,
            last_name,
            email,
            password,
            mobile_no
        ) VALUES (
            cust_val.NEXTVAL,
            p_first_name,
            p_last_name,
            p_email,
            hash_password(p_password),
            p_mobile_no
        );

        dbms_output.put_line('Customer added successfully.');
    EXCEPTION
        WHEN null_name_error THEN
            dbms_output.put_line('Error: First name and last name cannot be null.');
        WHEN empty_name_error THEN
            dbms_output.put_line('Error: First name and last name cannot be empty.');
        WHEN invalid_name_error THEN
            dbms_output.put_line('Error: First name and last name can only contain alphabetic characters.');
        WHEN name_length_exceeded_error THEN
            dbms_output.put_line('Error: First name or last name cannot be greater than 20 characters.');
        WHEN user_exists_error THEN
            dbms_output.put_line('Error: User with the provided email or phone number already exists.');
        WHEN invalid_email_error THEN
            dbms_output.put_line('Error: Invalid email format. Email cannot be null or exceeds 255 characters or should be in the correct format.');
        WHEN value_error THEN
            dbms_output.put_line('Error: Password must be at least 8 characters and at most 255 characters.');
        WHEN invalid_mobile_error THEN
            dbms_output.put_line('Error: Invalid mobile number format. Expected 10-12 digits.');
        WHEN OTHERS THEN
            dbms_output.put_line('Error: An unexpected error occurred.');
            RAISE;
    END spms_new_customer_insert;

  /* Procedure to add a vehicle */
    PROCEDURE spms_add_vehicle (
        p_registration_no VARCHAR,
        p_email           VARCHAR
    ) AS
        v_customer_id          NUMBER;
        v_existing_customer_id NUMBER;
    BEGIN
    -- Check if customer exists
        v_customer_id := NULL;
        BEGIN
            SELECT
                customer_id
            INTO v_customer_id
            FROM
                customer
            WHERE
                email = p_email;

        EXCEPTION
            WHEN no_data_found THEN
                dbms_output.put_line('Error: No customer found with the provided email.');
                RETURN;
        END;

    -- Check if the vehicle is registered with the same user
        BEGIN
            SELECT
                customer_id
            INTO v_existing_customer_id
            FROM
                vehicle
            WHERE
                registration_no = p_registration_no;

        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- No action needed if no vehicle is found with the provided registration number
        END;

        IF
            v_existing_customer_id IS NOT NULL
        THEN
            RAISE vehicle_registered_other_error;
        END IF;
    
    -- Check if the registration number meets the requirements
        IF p_registration_no IS NULL OR length(p_registration_no) > 10 OR NOT regexp_like(p_registration_no, '^[a-zA-Z0-9-]{5,10}$') THEN
            RAISE invalid_registration_no_error;
        END IF;


    -- Insert the vehicle
        INSERT INTO vehicle (
            vehicle_id,
            registration_no,
            customer_id
        ) VALUES (
            vehicle_val.NEXTVAL,
            p_registration_no,
            v_customer_id
        );
        dbms_output.put_line('SUCCESS: Vehicle is added successfully to the customer');
    EXCEPTION
        WHEN no_customer_found_error THEN
            dbms_output.put_line('Error: No customer found with the provided email.');
        WHEN invalid_registration_no_error THEN
            dbms_output.put_line('Error: Invalid registration number format.');
        WHEN vehicle_registered_other_error THEN
            dbms_output.put_line('Error: The vehicle is already registered.');
        WHEN OTHERS THEN
            dbms_output.put_line('Error: An unexpected error occurred.');
            RAISE;
    END spms_add_vehicle;


  /* Procedure to update customer information */
    PROCEDURE spms_customer_update (
        p_first_name VARCHAR,
        p_last_name  VARCHAR,
        p_email      VARCHAR,
        p_password   VARCHAR,
        p_mobile_no  VARCHAR
    ) AS

        v_existing_first_name VARCHAR(20);
        v_existing_last_name  VARCHAR(20);
        v_existing_mobile_no  VARCHAR(12);
        v_existing_password   VARCHAR(255);
        v_new_hashed_password RAW(2000);
        v_count               INTEGER;
    BEGIN
   -- Fetch existing customer details


        SELECT
            first_name,
            last_name,
            mobile_no,
            password
        INTO
            v_existing_first_name,
            v_existing_last_name,
            v_existing_mobile_no,
            v_existing_password
        FROM
            customer
        WHERE
            email = p_email;

        IF (
            length(trim(p_first_name)) != 0
            AND length(trim(p_first_name)) > 20
        ) OR (
            length(trim(p_last_name)) != 0
            AND length(trim(p_last_name)) > 20
        ) THEN
            RAISE name_length_exceeded_error;
        END IF;

        IF (
            length(trim(p_first_name)) != 0
            AND NOT regexp_like(p_first_name, '^[A-Za-z]+$')
        ) OR NOT (
            length(trim(p_last_name)) != 0
            AND regexp_like(p_last_name, '^[A-Za-z]+$')
        ) THEN
            RAISE invalid_name_error;
        END IF;

        IF
            length(trim(p_password)) != 0
            AND ( length(p_password) < 8 OR length(p_password) > 255 )
        THEN
            RAISE value_error;
        END IF;

        IF
            length(trim(p_email)) != 0
            AND length(p_email) > 255
        THEN
            RAISE invalid_email_error;
        END IF;

        IF
            length(trim(p_email)) != 0
            AND NOT regexp_like(p_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        THEN
            RAISE invalid_email_error;
        END IF;

        IF
            length(trim(p_mobile_no)) != 0
            AND NOT regexp_like(p_mobile_no, '^\d{10,12}$')
        THEN
            RAISE invalid_mobile_error;
        END IF;
        IF p_mobile_no IS NOT NULL AND p_mobile_no != v_existing_mobile_no THEN
        SELECT COUNT(*)
        INTO v_count
        FROM customer
        WHERE mobile_no = p_mobile_no;

        IF v_count > 0 THEN
            RAISE duplicate_mobile_error;
        END IF;
    END IF;
        IF length(trim(p_password)) != 0 THEN
            v_new_hashed_password := hash_password(p_password);
        ELSE
            v_new_hashed_password := v_existing_password; -- Keep the existing password if no new password is provided
        END IF;
   -- Update customer information
        UPDATE customer
        SET
            first_name = coalesce(p_first_name, v_existing_first_name),
            last_name = coalesce(p_last_name, v_existing_last_name),
            mobile_no = coalesce(p_mobile_no, v_existing_mobile_no),
            password = v_new_hashed_password
        WHERE
            email = p_email;

   -- Check if any rows were updated
        IF SQL%rowcount = 0 THEN
            RAISE no_customer_found_error;
        END IF;
        dbms_output.put_line('SUCCESS: Customer is updated successfully');
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('Error: No customer found with the provided email.');
        WHEN empty_name_error THEN
            dbms_output.put_line('Error: First name and last name cannot be empty.');
        WHEN invalid_name_error THEN
            dbms_output.put_line('Error: First name and last name can only contain alphabetic characters.');
        WHEN name_length_exceeded_error THEN
            dbms_output.put_line('Error: First name or last name cannot be greater than 20 characters.');
        WHEN user_exists_error THEN
            dbms_output.put_line('Error: User with the provided email already exists.');
        WHEN invalid_email_error THEN
            dbms_output.put_line('Error: Invalid email format or exceeds 255 characters.');
        WHEN value_error THEN
            dbms_output.put_line('Error: Password must be at least 8 characters and at most 255 characters.');
        WHEN invalid_mobile_error THEN
            dbms_output.put_line('Error: Invalid mobile number format. Expected 10 digits.');
        WHEN no_customer_found_error THEN
            dbms_output.put_line('Error: No customer found with the provided Email ID.');
        WHEN duplicate_mobile_error THEN
            dbms_output.put_line('Error: The provided phone number already exists');
        WHEN OTHERS THEN
            dbms_output.put_line('Error: An unexpected error occurred.');
            RAISE;
    END spms_customer_update;

END spms_customer_management_pkg;
/
