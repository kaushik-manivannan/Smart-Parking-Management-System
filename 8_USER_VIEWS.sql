--LOGIN AS USER PL_USER1
--EXECUTION ORDER: 8




--To display the vehicles belonging to the customer
SELECT * FROM PLADMIN.CUSTOMER_VEHICLES;



--To display the booking details of the customer
select * from PLADMIN.BOOKING_DETAILS 
where customer_id=1;



--TO display the booking_history of the customer
select * from PLADMIN.BOOKING_HISTORY
where customer_id=1;



--To display the rating of all parking lots
select * from PLADMIN.PARKING_LOT_RATING;



-- To display the available slots on a particular day - time specified.

SELECT *
FROM PLADMIN.AVAILABLE_SLOTS
WHERE PARKING_SLOT_ID NOT IN (
    SELECT DISTINCT pb.PARKING_SLOT_ID
    FROM PLADMIN.SLOT_BOOKING pb
    WHERE 
        NOT (
            (TIMESTAMP '2021-03-21 18:00:00' <= pb.SCHEDULED_START_TIME) OR
            (TIMESTAMP '2021-03-21 20:00:00' >= pb.SCHEDULED_END_TIME)
        )
);




