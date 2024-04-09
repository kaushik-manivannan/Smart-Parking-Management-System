--Login as Admin user from SQL Developer and run below commands to create PARKINGLOT_ADMIN
--EXECUTION ORDER : 1
--Execute using Oracle Admin account login

CLEAR SCREEN;
set SERVEROUTPUT ON;

DECLARE
    V_active_sess INTEGER;
BEGIN
    SELECT COUNT(*) INTO V_active_sess FROM V$SESSION 
    WHERE USERNAME IN ('PLADMIN', 
                       'PL_USER1',
                       'PL_MANAGER1');
    IF (V_active_sess>=1) THEN
        FOR I IN (
            SELECT sid AS V_sid,serial# AS V_serial, username as usern FROM V$SESSION 
            WHERE USERNAME IN ('PLADMIN', 
							   'PL_USER1',
                               'PL_MANAGER1')
        ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ' || CHR(39) || I.V_sid || ',' || I.V_serial || CHR(39) || ' IMMEDIATE';
            DBMS_OUTPUT.PUT_LINE('Connections to '||I.usern||' terminated');
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE(SQLERRM);
        END;
        END LOOP;
    END IF;
    DBMS_LOCK.SLEEP(5);
    EXECUTE IMMEDIATE 'DROP USER PLADMIN CASCADE';
    DBMS_OUTPUT.PUT_LINE('USER PLADMIN DROPPED');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1918 THEN
            DBMS_OUTPUT.PUT_LINE('User does not exist.');
        ELSE
         -- Handle other exceptions
            DBMS_OUTPUT.PUT_LINE('The script failed. Please check the syntax');
        END IF;
END;
/

CREATE USER PLADMIN IDENTIFIED BY SParkingsystema1#;

ALTER USER PLADMIN DEFAULT TABLESPACE users QUOTA UNLIMITED ON data;

ALTER USER PLADMIN TEMPORARY TABLESPACE TEMP;

GRANT CONNECT,RESOURCE TO PLADMIN WITH ADMIN OPTION;

GRANT CREATE SESSION, CREATE VIEW, CREATE TABLE, ALTER SESSION, CREATE PROCEDURE, ALTER USER, CREATE SEQUENCE TO PLADMIN;
GRANT CREATE SYNONYM, CREATE DATABASE LINK, RESOURCE, UNLIMITED TABLESPACE TO PLADMIN;
GRANT EXECUTE ON DBMS_CRYPTO TO PLADMIN;

