------------------------------------------------------EXECUTE THIS SCRIPT TO CREATE VIEWS-------------------------------------------------------
--Execution Order: 6
--Execute using user: PLADMIN

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
SET AUTOCOMMIT ON;
CLEAR SCREEN;
SET SERVEROUTPUT ON;



--1) Manager Views --> parking_slots_filled


-- Creating or replacing the parking_slots_filled view
CREATE OR REPLACE VIEW parking_slots_filled AS
SELECT 
    -- Selecting parking slot details along with related floor, parking lot, and customer information
    ps.PARKING_SLOT_ID, 
    ps.SLOT_NAME, 
    f.FLOOR_LEVEL, 
    pl.NAME AS PARKING_LOT_NAME, 
    a.STREET_ADDRESS, 
    a.CITY, 
    a.STATE, 
    a.COUNTRY, 
    v.REGISTRATION_NO, 
    -- Concatenating first name and last name for full customer name
    c.FIRST_NAME || ' ' || c.LAST_NAME AS CUSTOMER_NAME
FROM PARKING_SLOT ps
-- Joining with floors, parking lots, addresses, slot bookings, vehicles, and customers to get comprehensive details
JOIN FLOOR f ON ps.FLOOR_ID = f.FLOOR_ID
JOIN PARKING_LOT pl ON f.PARKING_LOT_ID = pl.PARKING_LOT_ID
JOIN ADDRESS a ON pl.ADDRESS_ID = a.ADDRESS_ID
JOIN SLOT_BOOKING sb ON ps.PARKING_SLOT_ID = sb.PARKING_SLOT_ID
JOIN VEHICLE v ON sb.VEHICLE_ID = v.VEHICLE_ID
JOIN CUSTOMER c ON v.CUSTOMER_ID = c.CUSTOMER_ID
-- Filtering for slots that are occupied within the hardcoded time
-- Note: For real-time data, replace the hardcoded date with SYSDATE
WHERE TO_DATE('2024-03-03 10:00:00', 'YYYY-MM-DD HH24:MI:SS') BETWEEN sb.SCHEDULED_START_TIME AND sb.SCHEDULED_END_TIME
ORDER BY ps.PARKING_SLOT_ID; -- Sorting results by parking slot ID for easier readability




--2) Manager Views --> parking_slot_vacant


-- Creating or replacing the parking_slots_vacant view
CREATE OR REPLACE VIEW parking_slots_vacant AS
SELECT DISTINCT
    -- Selecting distinct parking slot details along with related floor and parking lot information
    ps.PARKING_SLOT_ID, 
    ps.SLOT_NAME, 
    f.FLOOR_LEVEL, 
    pl.NAME AS PARKING_LOT_NAME, 
    a.STREET_ADDRESS, 
    a.CITY, 
    a.STATE, 
    a.COUNTRY
FROM PARKING_SLOT ps
-- Joining with floors, parking lots, and addresses to get comprehensive details
JOIN FLOOR f ON ps.FLOOR_ID = f.FLOOR_ID
JOIN PARKING_LOT pl ON f.PARKING_LOT_ID = pl.PARKING_LOT_ID
JOIN ADDRESS a ON pl.ADDRESS_ID = a.ADDRESS_ID
WHERE NOT EXISTS (
    -- Using a subquery to exclude slots that have bookings overlapping with the specified timestamp
    SELECT 1
    FROM SLOT_BOOKING sb
    WHERE sb.PARKING_SLOT_ID = ps.PARKING_SLOT_ID
    -- Note: For real-time data, replace the hardcoded date with SYSDATE
    AND TO_DATE('2024-03-03 10:00:00', 'YYYY-MM-DD HH24:MI:SS') BETWEEN sb.SCHEDULED_START_TIME AND sb.SCHEDULED_END_TIME
)
ORDER BY ps.PARKING_SLOT_ID; -- Sorting results by parking slot ID to ensure a consistent order





--3) Manager Views --> customer_feedback
-- Creating or replacing the customer_feedback view
-- This view aggregates customer feedback along with detailed information about the parking slots and lots involved.
CREATE OR REPLACE VIEW customer_feedback AS
SELECT 
    -- Concatenating first name and last name to get the full customer name.
    c.FIRST_NAME || ' ' || c.LAST_NAME AS CUSTOMER_NAME, 
    -- Including customer's email and mobile number for potential contact.
    c.EMAIL, 
    c.MOBILE_NO,
    -- Feedback details: rating and comments.
    f.RATING, 
    f.COMMENTS,
    -- Details of the parking lot where the feedback is associated.
    pl.NAME AS PARKING_LOT_NAME, 
    -- The specific parking slot that the feedback pertains to.
    ps.SLOT_NAME, 
    -- The floor level of the parking slot, adding another layer of specificity.
    fl.FLOOR_LEVEL,
    -- Formatting the actual start and end times of the parking usage for readability.
    -- These times are fetched from the CHECK_IN table, providing real usage data.
    TO_CHAR(ci.ACTUAL_START_TIME, 'DD-MON-YYYY HH:MI AM') AS ACTUAL_START_TIME,
    TO_CHAR(ci.ACTUAL_END_TIME, 'DD-MON-YYYY HH:MI AM') AS ACTUAL_END_TIME
FROM CUSTOMER c
JOIN VEHICLE v ON c.CUSTOMER_ID = v.CUSTOMER_ID
JOIN SLOT_BOOKING sb ON v.VEHICLE_ID = sb.VEHICLE_ID
JOIN PARKING_SLOT ps ON sb.PARKING_SLOT_ID = ps.PARKING_SLOT_ID
JOIN FLOOR fl ON ps.FLOOR_ID = fl.FLOOR_ID
JOIN PARKING_LOT pl ON fl.PARKING_LOT_ID = pl.PARKING_LOT_ID
JOIN CHECK_IN ci ON sb.SLOT_BOOKING_ID = ci.SLOT_BOOKING_ID
JOIN FEEDBACK f ON ci.CHECK_IN_ID = f.CHECK_IN_ID;







--4) Manager Views --> peak_hours


-- Create or replace the existing view named peak_hours
CREATE OR REPLACE VIEW peak_hours AS
SELECT
  -- Select parking lot ID, name, and pricing per hour from the parking_lot table
  pl.NAME AS parking_lot_name,
  -- Format and select the start time of the peak hour by truncating the scheduled start time to the nearest hour
  TO_CHAR(TRUNC(sb.SCHEDULED_START_TIME, 'HH24'), 'HH:MI AM') AS peak_hour_start_time,
  -- Calculate and format the end time of the peak hour by adding 1 hour to the start time and subtracting 1 second
  TO_CHAR(TRUNC(sb.SCHEDULED_START_TIME, 'HH24') + INTERVAL '1' HOUR - INTERVAL '1' SECOND, 'HH:MI AM') AS peak_hour_end_time,
  -- Count the number of bookings for each time slot
  COUNT(*) AS booking_count
FROM
  SLOT_BOOKING sb
  JOIN PARKING_SLOT ps ON sb.PARKING_SLOT_ID = ps.PARKING_SLOT_ID
  JOIN FLOOR f ON ps.FLOOR_ID = f.FLOOR_ID
  JOIN PARKING_LOT pl ON f.PARKING_LOT_ID = pl.PARKING_LOT_ID
GROUP BY
  -- Group the results by parking lot ID and the hour of the booking start time
  pl.PARKING_LOT_ID, pl.NAME, pl.PRICING_PER_HOUR, TRUNC(sb.SCHEDULED_START_TIME, 'HH24')
ORDER BY
  -- Order the results first by parking lot ID, and then by the number of bookings in descending order
  pl.PARKING_LOT_ID, COUNT(*) DESC;




--5) Manager Views --> Off_peak_hours


CREATE OR REPLACE VIEW off_peak_hours AS
SELECT
    date_range."DATE",
    hour_of_day.hour,
    ps.parking_slot_id,
    ps.slot_name
FROM
         (
        SELECT
            trunc(sysdate - level) AS "DATE"
        FROM
            dual
        CONNECT BY level <= 24
                   AND trunc(sysdate - level) >= trunc(sysdate - INTERVAL '1' MONTH)
    ) date_range
    CROSS JOIN (
        SELECT
            level - 1 AS hour
        FROM
            dual
        CONNECT BY
            level <= 24
    )            hour_of_day
    CROSS JOIN parking_slot ps
    LEFT JOIN slot_booking sb ON ps.parking_slot_id = sb.parking_slot_id
                                 AND date_range."DATE" = trunc(sb.scheduled_start_time)
                                 AND hour_of_day.hour = EXTRACT(HOUR FROM sb.scheduled_start_time)
WHERE
    sb.slot_booking_id IS NULL
    AND NOT EXISTS (
        SELECT
            1
        FROM
            slot_booking sb2
        WHERE
                ps.parking_slot_id = sb2.parking_slot_id
            AND trunc(date_range."DATE") = trunc(sb2.scheduled_start_time)
            AND hour_of_day.hour >= EXTRACT(HOUR FROM sb2.scheduled_start_time)
            AND hour_of_day.hour < EXTRACT(HOUR FROM sb2.scheduled_end_time)
    )
ORDER BY
    ps.parking_slot_id,
    hour_of_day.hour;









--6) Manager Views --> parking_lot_performance



CREATE OR REPLACE VIEW parking_lot_performance_by_day AS
SELECT
    pl.parking_lot_id,
    pl.name                            AS parking_lot_name,
    nvl(to_char(sb.scheduled_start_time, 'YYYY-MM-DD'),
        'No Booking')                  AS booking_date,
    COUNT(DISTINCT sb.slot_booking_id) AS total_bookings,
    nvl(SUM(EXTRACT(HOUR FROM(sb.scheduled_end_time - sb.scheduled_start_time))),
        0)                             AS total_hours,
    nvl(SUM(EXTRACT(HOUR FROM(sb.scheduled_end_time - sb.scheduled_start_time)) * pl.pricing_per_hour),
        0)                             AS total_amount
FROM
    parking_lot  pl
    LEFT JOIN floor        fl ON pl.parking_lot_id = fl.parking_lot_id
    LEFT JOIN parking_slot ps ON fl.floor_id = ps.floor_id
    LEFT JOIN slot_booking sb ON ps.parking_slot_id = sb.parking_slot_id
GROUP BY
    pl.parking_lot_id,
    pl.name,
    nvl(to_char(sb.scheduled_start_time, 'YYYY-MM-DD'),
        'No Booking')
ORDER BY
    pl.parking_lot_id,
    booking_date;
	



--7) Manager Views --> no_show_bookings

CREATE OR REPLACE VIEW NO_SHOW_BOOKINGS AS
SELECT 
    sb.SLOT_BOOKING_ID,
    sb.SCHEDULED_START_TIME AS BOOKED_START_TIME,
    sb.SCHEDULED_END_TIME AS BOOKED_END_TIME,
    v.REGISTRATION_NO AS VEHICLE_REGISTRATION,
    c.CUSTOMER_ID,
    c.FIRST_NAME,
    c.LAST_NAME,
    c.EMAIL,
    c.MOBILE_NO
FROM 
    SLOT_BOOKING sb
JOIN 
    VEHICLE v ON sb.VEHICLE_ID = v.VEHICLE_ID
JOIN 
    CUSTOMER c ON v.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN 
    CHECK_IN ci ON sb.SLOT_BOOKING_ID = ci.SLOT_BOOKING_ID
WHERE 
    ci.CHECK_IN_ID IS NULL;