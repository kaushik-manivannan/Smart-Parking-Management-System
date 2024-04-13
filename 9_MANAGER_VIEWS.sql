--LOGIN AS PL_MANAGER1 
--EXECUTION ORDER : 9
set SERVEROUTPUT on
CLEAR SCREEN;


--- To display parking_slots_filled at particular time. For View and testing purpose we have hardcoded a particular time interval

select * from PLADMIN.PARKING_SLOT;


-- To display vacant parking slot

select * from PLADMIN.parking_slots_vacant;


-- To display feedback

select * from PLADMIN.customer_feedback;


--To display the peak Hours

select * from PLADMIN.peak_hours;


--To display off_peak_hours

select * from PLADMIN.off_peak_hours;


--To display parking lot performance by day
select * from PLADMIN.parking_lot_performance_by_day;



--To display No show booking- who have booked a slot but haven't checked in
SELECT * FROM PLADMIN.NO_SHOW_BOOKINGS;