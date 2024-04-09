CREATE OR REPLACE PACKAGE spms_customer_management_pkg AS

/* Creating or declaring required packages for Smart parking management system customer management. Under this Package we are creating 3 packages
	1. For customer registration
	2. To add new VEHICLE
	3. To update the customer information
	4. Function to hash password and then store
*/
  PROCEDURE spms_new_customer_insert(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_password VARCHAR,
    p_mobile_no VARCHAR
  );

  PROCEDURE spms_add_vehicle(
    p_registration_no VARCHAR,
    p_email VARCHAR
  );
  
  FUNCTION hash_password(p_password VARCHAR) RETURN RAW DETERMINISTIC;

  PROCEDURE spms_customer_update(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_mobile_no VARCHAR
  );
END spms_customer_management_pkg;
/

CREATE OR REPLACE PACKAGE BODY spms_customer_management_pkg AS

-- Function to hash the provided password.
  FUNCTION hash_password(p_password VARCHAR) RETURN RAW DETERMINISTIC IS
    v_hashed_password RAW(2000);
  BEGIN
    v_hashed_password := DBMS_CRYPTO.HASH(
      UTL_I18N.STRING_TO_RAW(p_password, 'AL32UTF8'),
      DBMS_CRYPTO.HASH_SH1
    );
    RETURN v_hashed_password;
  END hash_password;
  
  
  PROCEDURE spms_new_customer_insert(
    p_first_name    VARCHAR,
    p_last_name     VARCHAR,
    p_email         VARCHAR,
    p_password      VARCHAR,
    p_mobile_no     VARCHAR
  ) AS
  BEGIN
    IF NOT REGEXP_LIKE(p_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$') THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid email format.');
    END IF;

    IF NOT REGEXP_LIKE(p_mobile_no, '^\d{10}$') THEN
      RAISE_APPLICATION_ERROR(-20002, 'Invalid mobile number format. Expected 10 digits.');
    END IF;

    IF p_first_name IS NULL OR p_last_name IS NULL THEN
      RAISE_APPLICATION_ERROR(-20003, 'First name and last name cannot be null.');
    END IF;

    INSERT INTO CUSTOMER (
	  CUSTOMER_ID,
      FIRST_NAME, 
      LAST_NAME, 
      EMAIL, 
      PASSWORD, 
      MOBILE_NO
    ) VALUES (
	  CUST_VAL.NEXTVAL,
      p_first_name,
      p_last_name,
      p_email,
      hash_password(p_password),
      p_mobile_no
    );
  END spms_new_customer_insert;

  PROCEDURE spms_add_vehicle(
    p_registration_no VARCHAR,
    p_email           VARCHAR
  ) AS
    v_customer_id NUMBER;
  BEGIN
    /*IF NOT REGEXP_LIKE(p_registration_no, '^[A-Z0-9]{2,7}$') THEN
      RAISE_APPLICATION_ERROR(-20004, 'Invalid registration number format. Must satisfy US number plate standards.');
    END IF;*/

    SELECT CUSTOMER_ID INTO v_customer_id
    FROM CUSTOMER
    WHERE EMAIL = p_email;

    INSERT INTO VEHICLE (
	  VEHICLE_ID,
      REGISTRATION_NO, 
      CUSTOMER_ID
    ) VALUES (
	  VEHICLE_VAL.NEXTVAL,
      p_registration_no,
      v_customer_id
    );
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20005, 'No customer found with the provided email.');
  END spms_add_vehicle;

 
  PROCEDURE spms_customer_update(
    p_first_name   VARCHAR,
    p_last_name    VARCHAR,
    p_email        VARCHAR,
    p_mobile_no    VARCHAR
  ) AS
    v_existing_first_name  VARCHAR(20);
    v_existing_last_name   VARCHAR(20);
    v_existing_mobile_no   VARCHAR(12);
  BEGIN
    SELECT FIRST_NAME, LAST_NAME, MOBILE_NO INTO v_existing_first_name, v_existing_last_name, v_existing_mobile_no
    FROM CUSTOMER
    WHERE EMAIL = p_email;

    IF p_email IS NOT NULL AND NOT REGEXP_LIKE(p_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
      RAISE_APPLICATION_ERROR(-20002, 'Invalid email format.');
    END IF;

    IF p_mobile_no IS NOT NULL AND NOT REGEXP_LIKE(p_mobile_no, '^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$') THEN
      RAISE_APPLICATION_ERROR(-20004, 'Invalid mobile number format.');
    END IF;

    UPDATE CUSTOMER
    SET FIRST_NAME = COALESCE(p_first_name, v_existing_first_name),
        LAST_NAME = COALESCE(p_last_name, v_existing_last_name),
        MOBILE_NO = COALESCE(p_mobile_no, v_existing_mobile_no)
    WHERE EMAIL = p_email;

    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20006, 'No customer found with the provided Email ID.');
    END IF;
  END spms_customer_update;


END spms_customer_management_pkg;
/
