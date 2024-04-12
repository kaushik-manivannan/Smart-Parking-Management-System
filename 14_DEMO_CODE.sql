------------------------------------------------------DEMO EXECUTION-------------------------------------------------------
--Execution Order: 
--Execute using user: AS USER
SET SERVEROUTPUT ON;
SET AUTOCOMMIT OFF;
--CUSTMER ONBOARDIGN AND MANAGEMENT

-- Customer Creation procedure Test cases
-- customer creation
EXEC spms_customer_management_pkg.spms_new_customer_insert ('Henrick','Klassen','henrickklassen12@gmail.com','Henrick123','8574059622');
-- customer creation with other email but same mobile number  
EXEC spms_customer_management_pkg.spms_new_customer_insert ('Henrick','Klassen','henrickklassen123@gmail.com','Henrick123q','8574059622');
-- check for duplicate customer with same email
EXEC spms_customer_management_pkg.spms_new_customer_insert ('Henrick1','Klassen','henrickklassen12@gmail.com','Henrick123q','6173932772');
-- customer with invalid names
EXEC spms_customer_management_pkg.spms_new_customer_insert ('','russ','andrerussell@gmail.com','andre123q','6173932772');
EXEC spms_customer_management_pkg.spms_new_customer_insert ('andre12','russ','andrerussell@gmail.com','andre123q','6173932772');
--customer with all corect values
EXEC spms_customer_management_pkg.spms_new_customer_insert ('andre','russ','andrerussell@gmail.com','andre123q','6173932772');
-- customer with invalid password
EXEC spms_customer_management_pkg.spms_new_customer_insert ('mayank','yadav','mayankyadav@gmail.com','may','6173932772');
-- customer with invalid phone-number
EXEC spms_customer_management_pkg.spms_new_customer_insert ('mayank','yadav','mayankyadav@gmail.com','mayyank1','12abc456');

-- vehicle addition procedure
-- invalid registration number
EXEC spms_customer_management_pkg.spms_add_vehicle('<script></script>','henrickklassen12@gmail.com');
-- add vehicle to the custumer
EXEC spms_customer_management_pkg.spms_add_vehicle('BEE-419','henrickklassen12@gmail.com');
-- check already the vehicle already registered
EXEC spms_customer_management_pkg.spms_add_vehicle('BEE-419','andrerussell@gmail.com');

--EXEC spms_customer_management_pkg.spms_add_vehicle('andrerussell@gmail.com');

-- Update the customer procedure
-- invalid email
EXEC spms_customer_management_pkg.spms_customer_update('','','kau@northeastern.edu','passw', 8574059622);
--  update passowrd and phone number with alrready existing phone numer - throws error
EXEC spms_customer_management_pkg.spms_customer_update('','','henrickklassen12@gmail.com','password', 6173932772);
-- update customer with all correct values 
EXEC spms_customer_management_pkg.spms_customer_update('','','henrickklassen12@gmail.com','password', 6173932773);
--EXEC spms_customer_management_pkg.spms_customer_update('','','henrickklassen12@gmail.com','password');

-- SLOT BOOKING MODULES:



/* 1st procedure */
--show available lots for boston

EXEC PLADMIN.spms_slot_booking_pkg.show_available_lots('BOSTON');

--whatever case we give it will work even with extra space:

EXEC PLADMIN.spms_slot_booking_pkg.show_available_lots('bOsToN');


EXEC PLADMIN.spms_slot_booking_pkg.show_available_lots(' bOsToN ');


--Incase parking lots not available in the dashboard

EXEC PLADMIN.spms_slot_booking_pkg.show_available_lots('New Haven');






/* 2nd procedure */
--available slots by lot and TIME

EXEC PLADMIN.spms_slot_booking_pkg.show_available_slots_by_lot_and_time('Downtown Parking','2024-Apr-11 08:30 AM','2024-April-11 10:30 PM');


--parking lot case and space 

EXEC PLADMIN.spms_slot_booking_pkg.show_available_slots_by_lot_and_time('downTown parking','2024-Apr-11 08:30 AM','2024-April-11 10:30 PM');



--Incase if parking lot is not found in database systems

EXEC PLADMIN.spms_slot_booking_pkg.show_available_slots_by_lot_and_time('Downtown Parkin','2024-Apr-11 08:30 AM','2024-April-11 10:30 PM');


--Changing date formats as input

EXEC PLADMIN.spms_slot_booking_pkg.show_available_slots_by_lot_and_time('Downtown Parking','2024-04-11 08:30 AM','2024-04-11 10:30 PM');


--Based on our business rule -> Booking time should be atleast 1hr, if the selected time is less than 1 hr - exception will be raised.

EXEC PLADMIN.spms_slot_booking_pkg.show_available_slots_by_lot_and_time('Downtown Parking','2024-04-11 08:30 AM','2024-04-11 9:00 AM');


--Based on our business rule slot start time and end time can either half hour or hour. Exception to handle that.

EXEC PLADMIN.spms_slot_booking_pkg.show_available_slots_by_lot_and_time('Downtown Parking','2024-04-11 08:30 AM','2024-04-11 9:40 AM');


--Start time can not be greater than end time

EXEC PLADMIN.spms_slot_booking_pkg.show_available_slots_by_lot_and_time('Downtown Parking','2024-04-11 08:30 AM','2024-04-11 8:00 AM');


-- If given different date format

EXEC PLADMIN.spms_slot_booking_pkg.show_available_slots_by_lot_and_time('Downtown Parking','04-2024-11 08:30 AM','2024-04-11 8:00 AM');






/* 3rd procedure */

--Lot Name not found
EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown arking',p_floor_level => 'P2',p_slot_name => 'P2-S1',p_vehicle_reg_no => '215BG2',p_start_time => '2024-04-13 08:30',p_end_time => '2024-04-13 10:30',p_transaction_type => 'debit',p_amount => 7.00 );

--Floor not found
EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown Parking',p_floor_level => 'P23',p_slot_name => 'P2-S1',p_vehicle_reg_no => '215BG2',p_start_time => '2024-04-13 08:30',p_end_time => '2024-04-13 10:30',p_transaction_type => 'debit',p_amount => 7.00 );


--Slot name not found
EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown Parking',p_floor_level => 'P2',p_slot_name => 'P23-S1',p_vehicle_reg_no => '215BG2',p_start_time => '2024-04-13 08:30',p_end_time => '2024-04-13 10:30',p_transaction_type => 'debit',p_amount => 7.00 );


--Vehicle number not found


EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown Parking',p_floor_level => 'P2',p_slot_name => 'P2-S1',p_vehicle_reg_no => '215BG2',p_start_time => '2024-04-15 08:30',p_end_time => '2024-04-15 10:30',p_transaction_type => 'debit',p_amount => 7.00 );


--Transaction type other than credit or debit


EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown Parking',p_floor_level => 'P2',p_slot_name => 'P2-S1',p_vehicle_reg_no => '215BG2',p_start_time => '2024-04-15 08:30',p_end_time => '2024-04-15 10:30',p_transaction_type => 'cash',p_amount => 7.00 );




--Amount is not correct

EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown Parking',p_floor_level => 'P2',p_slot_name => 'P2-S1',p_vehicle_reg_no => '215BG2',p_start_time => '2024-04-15 08:30',p_end_time => '2024-04-15 10:30',p_transaction_type => 'debit',p_amount => 5.00 );




-- Slot Booking done successfully

EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown Parking',p_floor_level => 'P2',p_slot_name => 'P2-S1',p_vehicle_reg_no => '215BG2',p_start_time => '2024-04-15 08:30',p_end_time => '2024-04-15 10:30',p_transaction_type => 'debit',p_amount => 7.00 );


--Trying to book different slot for the same Vehicle
EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown Parking',p_floor_level => 'P2',p_slot_name => 'P2-S3',p_vehicle_reg_no => '215BG2',p_start_time => '2024-04-15 08:30',p_end_time => '2024-04-15 10:30',p_transaction_type => 'debit',p_amount => 7.00 );

--Trying to use the same slot for different Vehicle
EXEC PLADMIN.spms_slot_booking_pkg.book_parking_slot (p_lot_name => 'Downtown Parking',p_floor_level => 'P2',p_slot_name => 'P2-S1',p_vehicle_reg_no => 'JKLM1010',p_start_time => '2024-04-15 08:30',p_end_time => '2024-04-15 10:30',p_transaction_type => 'debit',p_amount => 7.00 );





/* 4th Procedure */
--show history of bookings

EXEC PLADMIN.spms_slot_booking_pkg.view_customer_booking_history('henrickklassen123@gmail.com');

--incase it email id wrong

EXEC PLADMIN.spms_slot_booking_pkg.view_customer_booking_history('henrickklasse12@gmail.com');





/*5th Procedure */

-- when start time is less than 2 hrs
EXEC PLADMIN.spms_slot_booking_pkg.cancel_booking('100','2024-04-15 9:30 AM');

-- cancelling earlier
EXEC PLADMIN.spms_slot_booking_pkg.cancel_booking('101','2024-04-14 1:30 AM');





/* 6th procedure */

--when trying to checkin before 30mins
EXEC PLADMIN.spms_slot_booking_pkg.perform_check_in (102,'2024-04-15 8:00 AM');


-- checkin
EXEC PLADMIN.spms_slot_booking_pkg.perform_check_in (102,'2024-04-15 8:30 AM');

--duplicate checkin 
EXEC PLADMIN.spms_slot_booking_pkg.perform_check_in (102,'2024-04-13 10:00 AM');





/* 7th procedure */

--when providing wrong slot booking id

EXEC PLADMIN.spms_slot_booking_pkg.perform_check_out(106,'2024-04-13 12:30 PM');


-- when providing correct 

EXEC PLADMIN.spms_slot_booking_pkg.perform_check_out(102,'2024-04-15 12:30 PM');

/* 8th procedure */

--feedback

EXEC PLADMIN.spms_slot_booking_pkg.submit_feedback(102,6,'Top notch');


EXEC PLADMIN.spms_slot_booking_pkg.submit_feedback(102,5,'Top notch');


