/* This script contains - DDL statements for Smart Parking Management system - Create/Drop Tables, Create/Drop Sequences */
--Execution Order:4
--Execute using: PLADMIN


SET SERVEROUTPUT ON;
CLEAR SCREEN;
--------------------------------EXECUTE BELOW ONLY INCASE DROPPING THE WHOLE TABLE IS REQUIRED------------------------------------------
/*As relationships are already established between tables drop tables in below order. Incase if any one table needs to be dropped the specified relationship needs to be broken and then table should be dropped*/




CREATE OR REPLACE PROCEDURE DROP_TABLE_SPMS(
    p_table_name IN VARCHAR
) AS
BEGIN
	EXECUTE IMMEDIATE 'DROP TABLE ' || p_table_name;
    DBMS_OUTPUT.PUT_LINE('Table ' || p_table_name || ' dropped successfully.');
	
EXCEPTION 
	WHEN OTHERS THEN 
	IF SQLCODE= -00942 THEN
		DBMS_OUTPUT.PUT_LINE(p_table_name ||' table doesn''t exist. Please create the table or check the table name');   
	ELSIF SQLCODE = -02449 THEN 
		DBMS_OUTPUT.PUT_LINE(p_table_name ||' - The Primary key in the table is referenced by Foreign key. Hence please break the relationship/drop the child table first!');
		RETURN;
	ELSE
        DBMS_OUTPUT.PUT_LINE('Error: ' || p_table_name);
		RETURN;
	END IF;
END DROP_TABLE_SPMS;
/





BEGIN
DROP_TABLE_SPMS('FEEDBACK');
END;
/





BEGIN
DROP_TABLE_SPMS('CHECK_IN');
END;
/





BEGIN
DROP_TABLE_SPMS('SLOT_BOOKING');
END;
/





BEGIN
DROP_TABLE_SPMS('PAYMENT');
END;
/






BEGIN
DROP_TABLE_SPMS('VEHICLE');
END;
/






BEGIN
DROP_TABLE_SPMS('CUSTOMER');
END;
/





BEGIN
DROP_TABLE_SPMS('PARKING_SLOT');
END;
/





BEGIN
DROP_TABLE_SPMS('FLOOR');
END;
/






BEGIN
DROP_TABLE_SPMS('PARKING_LOT');
END;
/






BEGIN
DROP_TABLE_SPMS('ADDRESS');
END;
/






-------------------------------FOR CREATING TABLES USE BELOW-----------------------------------------

--CREATING A PROCEDURE TO CREATE TABLES IF IT NOT EXISTS

CREATE OR REPLACE PROCEDURE CREATE_TABLE_IF_NOT_EXISTS(
    p_table_name IN VARCHAR,
    p_table_definition IN VARCHAR
) AS
    table_exists NUMBER;
    sql_stmt VARCHAR2(2000);
BEGIN
    -- Check if the table exists
    SELECT COUNT(*)
    INTO table_exists
    FROM user_tables
    WHERE table_name = UPPER(p_table_name);

    -- If the table does not exist, create it
    IF table_exists = 0 THEN
        sql_stmt := 'CREATE TABLE ' || p_table_name || ' ' || p_table_definition;
        EXECUTE IMMEDIATE sql_stmt;
        DBMS_OUTPUT.PUT_LINE('Table ' || p_table_name || ' has been created.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table ' || p_table_name || ' already exists.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
	IF SQLCODE= -00907 THEN
		DBMS_OUTPUT.PUT_LINE('Syntax Error in Create. Please correct the syntax' || p_table_name);
	ELSIF SQLCODE = -00922 THEN 
		DBMS_OUTPUT.PUT_LINE('missing or invalid option' || p_table_name);
		RETURN;
	ELSIF SQLCODE = -00942 THEN 
		DBMS_OUTPUT.PUT_LINE('The Parent table doesn''t exist to establish the relationship. Please create the parent table and then execute!' || p_table_name);
		RETURN;
	ELSE
        DBMS_OUTPUT.PUT_LINE('Error: in' || p_table_name);
		RETURN;
	END IF;
END CREATE_TABLE_IF_NOT_EXISTS;
/







--To create table ADDRESS

BEGIN
    CREATE_TABLE_IF_NOT_EXISTS('ADDRESS', '(ADDRESS_ID NUMERIC PRIMARY KEY,
	STREET_ADDRESS VARCHAR(50) NOT NULL,
	CITY VARCHAR(20) NOT NULL,
	STATE VARCHAR(20) NOT NULL,
	COUNTRY VARCHAR(20) NOT NULL,
	ZIP_CODE VARCHAR(10) NOT NULL,
	LATITUDE DECIMAL(10,6) NOT NULL,
	LONGITUDE DECIMAL(10,6) NOT NULL,
	CONSTRAINT ADDRESS_UNIQ UNIQUE(STREET_ADDRESS,CITY)) 
	');
END;
/







--To create table PARKING_LOT

BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('PARKING_LOT', '(PARKING_LOT_ID NUMERIC PRIMARY KEY,
	NAME VARCHAR(50) NOT NULL,
	PRICING_PER_HOUR DECIMAL(5,2) NOT NULL,
	ADDRESS_ID NUMERIC REFERENCES ADDRESS(ADDRESS_ID),
	CONSTRAINT LOT_UNIQUE UNIQUE(NAME,ADDRESS_ID))
	');
END;
/








--To create table FLOOR

BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('FLOOR', '(FLOOR_ID NUMERIC PRIMARY KEY,
	FLOOR_LEVEL VARCHAR(5) NOT NULL,
	MAX_HEIGHT DECIMAL(5,2) NOT NULL,
	PARKING_LOT_ID NUMERIC REFERENCES PARKING_LOT(PARKING_LOT_ID),
	CONSTRAINT FLOOR_UNIQ UNIQUE(FLOOR_LEVEL,PARKING_LOT_ID))
	');
END;
/







--To create table PARKING_SLOT

BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('PARKING_SLOT', '(PARKING_SLOT_ID NUMERIC PRIMARY KEY,
	SLOT_NAME VARCHAR(5),
	FLOOR_ID NUMERIC REFERENCES FLOOR(FLOOR_ID),
	CONSTRAINT SLOT_UNIQ UNIQUE(SLOT_NAME,FLOOR_ID))
	');
END;
/








--To create table CUSTOMER

BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('CUSTOMER', '(CUSTOMER_ID NUMERIC PRIMARY KEY,
	FIRST_NAME VARCHAR(20) NOT NULL,
	LAST_NAME VARCHAR(20) NOT NULL,
	EMAIL VARCHAR(255) NOT NULL CONSTRAINT email_check CHECK (REGEXP_LIKE(EMAIL, ''^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'')),
	PASSWORD VARCHAR(255) NOT NULL,
	MOBILE_NO VARCHAR(12) NOT NULL,
	CONSTRAINT CUST_EMAIL_UNIQ UNIQUE(EMAIL),
	CONSTRAINT CUST_MOBILE_NO_UNIQ UNIQUE(MOBILE_NO))
	');
END;
/









--To create table VEHICLE
BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('VEHICLE', '(VEHICLE_ID NUMERIC PRIMARY KEY,
	REGISTRATION_NO VARCHAR(10) NOT NULL,
	CUSTOMER_ID NUMERIC REFERENCES CUSTOMER(CUSTOMER_ID),
	CONSTRAINT VEH_UNIQ UNIQUE(REGISTRATION_NO,CUSTOMER_ID))
	');
END;
/








--To create table PAYMENT
BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('PAYMENT', '(PAYMENT_ID NUMERIC PRIMARY KEY,
	TRANSACTION_TYPE VARCHAR(10) NOT NULL CONSTRAINT TRANS_CHECK CHECK(UPPER(TRANSACTION_TYPE) in (''CREDIT'',''DEBIT'')),
	TRANSACTION_DATE TIMESTAMP NOT NULL,
	AMOUNT DECIMAL(5,2) NOT NULL)
	');
END;
/










--To create table SLOT_BOOKING
BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('SLOT_BOOKING', '(SLOT_BOOKING_ID NUMERIC PRIMARY KEY,
	SCHEDULED_START_TIME TIMESTAMP NOT NULL,
	SCHEDULED_END_TIME TIMESTAMP NOT NULL,
	PAYMENT_ID NUMERIC REFERENCES PAYMENT(PAYMENT_ID),
	PARKING_SLOT_ID NUMERIC REFERENCES PARKING_SLOT(PARKING_SLOT_ID),
	VEHICLE_ID NUMERIC REFERENCES VEHICLE(VEHICLE_ID),
	CONSTRAINT BOOKING_UNIQ UNIQUE(SCHEDULED_START_TIME,SCHEDULED_END_TIME,PAYMENT_ID,PARKING_SLOT_ID,VEHICLE_ID),
	CONSTRAINT PAYMENT_UNIQ UNIQUE(PAYMENT_ID))
	');
END;
/








--To create table CHECK_IN
BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('CHECK_IN', '(CHECK_IN_ID NUMERIC PRIMARY KEY,
	ACTUAL_START_TIME TIMESTAMP NOT NULL,
	ACTUAL_END_TIME TIMESTAMP NOT NULL,
	SLOT_BOOKING_ID REFERENCES SLOT_BOOKING(SLOT_BOOKING_ID),
	CONSTRAINT CHECKIN_UNIQ UNIQUE(SLOT_BOOKING_ID))
	');
END;
/







--To create table FEEDBACK

BEGIN
	CREATE_TABLE_IF_NOT_EXISTS('FEEDBACK', '(FEEDBACK_ID NUMERIC PRIMARY KEY,
	RATING NUMERIC NOT NULL CONSTRAINT RATING_CHECK CHECK (RATING >= 1 AND RATING <= 5),
	COMMENTS VARCHAR(255),
	CHECK_IN_ID NUMERIC REFERENCES CHECK_IN(CHECK_IN_ID),
	CONSTRAINT FEEDBACK_UNIQ UNIQUE(CHECK_IN_ID))
	');
END;
/







----------------------------------------------------EXECUTE BELOW TO DROP AND RECREATE SEQUENCE------------------------------------------
/*NOTE :- IN OUR CURRENT VERSION OF DML STATEMENTS WE HAVE NOT USED SEQUENCE AS THEY ARE MANUAL INSERTS AND NEED TO REFERRED IN THE CHID TABLES AS FOREIGN KEYS. HENCE INSTEAD OF USING SEQ.CURR_VAL WE HAVE HARDCODED THE VALUES. MAYBE WHILE CREATING BUSINESS LOGIC FUNCTIONS WE MIGHT USE THIS*/

CREATE OR REPLACE PROCEDURE create_sequence (
    p_sequence_name IN VARCHAR
)
IS
    v_count NUMBER;
BEGIN
    -- Check if the sequence exists
    SELECT COUNT(*)
    INTO v_count
    FROM user_sequences
    WHERE sequence_name = p_sequence_name;

    -- If the count is 1, the sequence exist
    IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'DROP SEQUENCE ' || p_sequence_name;
		DBMS_OUTPUT.PUT_LINE('Sequence ' || p_sequence_name || ' dropped successfully.');
		END IF;
	
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || p_sequence_name || ' START WITH 100 INCREMENT BY 1';
    DBMS_OUTPUT.PUT_LINE('Sequence ' || p_sequence_name || ' created successfully.');

END create_sequence;
/





BEGIN
create_sequence('ADDRESS_VAL');
END;
/


BEGIN
create_sequence('PARKING_LOT_ID_VAL');
END;
/


BEGIN
create_sequence('FLOOR_ID_VAL');
END;
/


BEGIN
create_sequence('PARKING_SLOT_ID_VAL');
END;
/


BEGIN
create_sequence('CUST_VAL');
END;
/


BEGIN
create_sequence('VEHICLE_VAL');
END;
/


BEGIN
create_sequence('SLOT_BOOKING_VAL');
END;
/


BEGIN
create_sequence('PAYMENT_VAL');
END;
/



BEGIN
create_sequence('CHECKIN_VAL');
END;
/



BEGIN
create_sequence('FEEDBACK_VAL');
END;
/