--Login as Admin user from SQL Developer and run below commands
--EXECUTION ORDER : 3
--Execute using Oracle Admin account login

SET SERVEROUTPUT ON
CLEAR SCREEN;

--Drop the user if already exist
BEGIN
    EXECUTE IMMEDIATE 'DROP USER PL_MANAGER1 CASCADE';
    dbms_output.put_line('USER PL_MANAGER1 DROPPED');
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('USER PL_MANAGER1 DOES NOT EXIST');
END;
/
--Create PL_MANAGER1
CREATE USER PL_MANAGER1 IDENTIFIED BY SParkingsystemm1#;


ALTER USER PL_MANAGER1 QUOTA UNLIMITED ON data;

ALTER USER PL_MANAGER1 TEMPORARY TABLESPACE TEMP;
GRANT CONNECT,RESOURCE TO PL_MANAGER1;



