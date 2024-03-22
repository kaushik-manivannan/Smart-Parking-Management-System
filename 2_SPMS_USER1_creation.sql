--Login as Admin user from SQL Developer and run below commands
--EXECUTION ORDER : 2
--Execute using Oracle Admin account login

set SERVEROUTPUT on
CLEAR SCREEN;

--Drop the user if already exist
BEGIN
    EXECUTE IMMEDIATE 'DROP USER PL_USER1 CASCADE';
    dbms_output.put_line('USER PL_USER1 DROPPED');
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('USER PL_USER1 DOES NOT EXIST');
END;
/
--Create PL_USER1
CREATE USER PL_USER1 IDENTIFIED BY SParkingsystemu1#;


ALTER USER PL_USER1 QUOTA UNLIMITED ON data;

ALTER USER PL_USER1 TEMPORARY TABLESPACE TEMP;
GRANT CONNECT,RESOURCE TO PL_USER1;



