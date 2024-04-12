SET SERVEROUTPUT ON;
SET AUTOCOMMIT OFF;
CLEAR SCREEN;


CREATE OR REPLACE PACKAGE spms_slot_booking_pkg AS

  -- Check available parking slots in nearby parking lots
    FUNCTION available_lots (
        p_city VARCHAR
    ) RETURN SYS_REFCURSOR;

    PROCEDURE show_available_lots (
        p_city VARCHAR
    );
	
	
    -- Function to standardize Dates
    FUNCTION flexiblenormalizetimestamp (
        p_timestamp VARCHAR2
    ) RETURN VARCHAR2;
 
 -- Check available slots in a specific parking lot for a given time
    FUNCTION available_slots_by_lot_and_time (
        p_name       VARCHAR,
        p_start_time TIMESTAMP,
        p_end_time   TIMESTAMP
    ) RETURN SYS_REFCURSOR;

    PROCEDURE show_available_slots_by_lot_and_time (
        p_name       VARCHAR,
        p_start_time VARCHAR,
        p_end_time   VARCHAR
    );

	-- Book a parking slot
    PROCEDURE book_parking_slot (
        p_slot_name        VARCHAR,
        p_floor_level      VARCHAR,
        p_lot_name         VARCHAR,
        p_vehicle_reg_no   VARCHAR,
        p_start_time       VARCHAR,
        p_end_time         VARCHAR,
        p_transaction_type VARCHAR,
        p_amount           NUMBER
    );

 -- View history of booked slots
    PROCEDURE view_customer_booking_history (
        p_email VARCHAR
    );

-- cancel booking
    PROCEDURE cancel_booking (
        p_booking_id         NUMBER,
        cancel_initiate_time VARCHAR
    );

-- Check-in procedure
    PROCEDURE perform_check_in (
        p_slot_booking_id   NUMBER,
        p_actual_start_time VARCHAR
    );

--check-out procedure
    PROCEDURE perform_check_out (
        p_slot_booking_id NUMBER,
        p_actual_end_time VARCHAR
    );

--submit_feedback
    PROCEDURE submit_feedback (
        p_slot_booking_id NUMBER,
        p_rating          NUMBER,
        p_comments        VARCHAR2
    );

END spms_slot_booking_pkg;
/

CREATE OR REPLACE PACKAGE BODY spms_slot_booking_pkg AS

    FUNCTION available_lots (
        p_city VARCHAR
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR SELECT
                                                l.name AS parking_slot_name,
                                                a.street_address,
                                                a.city,
                                                a.state,
                                                l.pricing_per_hour
                                            FROM
                                                     parking_lot l
                                                JOIN address a ON a.address_id = l.address_id
                          WHERE
                              upper(a.city) = TRIM(upper(p_city));

        RETURN v_cursor;
    END available_lots;

    PROCEDURE show_available_lots (
        p_city VARCHAR
    ) IS

        v_cursor            SYS_REFCURSOR;
        v_parking_slot_name VARCHAR2(50);
        v_street_address    VARCHAR2(50);
        v_city              VARCHAR2(50);
        v_state             VARCHAR2(50);
        v_pricing_per_hour  VARCHAR2(50);
        v_found             BOOLEAN := FALSE;
    BEGIN
    -- Call the function
        v_cursor := available_lots(p_city => p_city);

    -- Print column headers
        dbms_output.put_line(rpad('Slot Name', 52)
                             || rpad('Street Address', 52)
                             || rpad('City', 52)
                             || rpad('State', 52)
                             || rpad('Price/Hour', 15));

        dbms_output.put_line(rpad('-', 50, '-')
                             || rpad('-', 50, '-')
                             || rpad('-', 50, '-')
                             || rpad('-', 50, '-')
                             || rpad('-', 15, '-'));

    -- Fetch and process the cursor as needed
        LOOP
            FETCH v_cursor INTO
                v_parking_slot_name,
                v_street_address,
                v_city,
                v_state,
                v_pricing_per_hour;
            EXIT WHEN v_cursor%notfound;
		
		-- Set found flag as true if data is fetched
            v_found := TRUE;
        
        -- Format each column to align text and ensure the table looks tidy
            dbms_output.put_line(rpad(v_parking_slot_name, 50)
                                 || ' '
                                 || rpad(v_street_address, 50)
                                 || ' '
                                 || rpad(v_city, 50)
                                 || ' '
                                 || rpad(v_state, 50)
                                 || ' '
                                 || rpad(v_pricing_per_hour, 15));

        END LOOP;

    -- Close the cursor
        CLOSE v_cursor;
 -- Handle no data found
        IF NOT v_found THEN
            dbms_output.put_line('No available parking slots found for the city: ' || p_city);
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('No parking slots available for the specified city: ' || p_city);
        WHEN OTHERS THEN
            dbms_output.put_line('An unexpected error occurred');
        -- Optionally re-raise the exception to ensure it can be logged or handled further up the call stack
            RAISE;
    END show_available_lots;

    FUNCTION available_slots_by_lot_and_time (
        p_name       VARCHAR,
        p_start_time TIMESTAMP,
        p_end_time   TIMESTAMP
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR SELECT
                                                ps.slot_name,
                                                f.floor_level,
                                                f.max_height,
                                                pl.name AS lot_name,
                                                pl.pricing_per_hour
                                            FROM
                                                     parking_lot pl
                                                JOIN floor        f ON pl.parking_lot_id = f.parking_lot_id
                                                JOIN parking_slot ps ON f.floor_id = ps.floor_id
                          WHERE
                                  upper(TRIM(pl.name)) = upper(TRIM(p_name))
                              AND NOT EXISTS (
                                  SELECT
                                      1
                                  FROM
                                      slot_booking sb
                                  WHERE
                                          sb.parking_slot_id = ps.parking_slot_id
                                      AND sb.scheduled_start_time < p_end_time
                                      AND sb.scheduled_end_time > p_start_time
                              );

        RETURN v_cursor;
    END available_slots_by_lot_and_time;

    FUNCTION flexiblenormalizetimestamp (
        p_timestamp VARCHAR2
    ) RETURN VARCHAR2 AS
        v_normalized_timestamp TIMESTAMP WITH TIME ZONE; -- Use TIMESTAMP WITH TIME ZONE when necessary
    BEGIN
        BEGIN
        -- Try converting using a format without time zone first
            v_normalized_timestamp := TO_TIMESTAMP ( p_timestamp, 'DD-MM-YYYY HH12:MI AM' );
        EXCEPTION
            WHEN OTHERS THEN
                BEGIN
                -- Another format, also without time zone
                    v_normalized_timestamp := TO_TIMESTAMP ( p_timestamp, 'YYYY-MM-DD HH12:MI AM' );
                EXCEPTION
                    WHEN OTHERS THEN
                        BEGIN
                        -- Include formats that might have full month names
                            v_normalized_timestamp := TO_TIMESTAMP ( p_timestamp, 'YYYY-Month-DD HH12:MI AM' );
                        EXCEPTION
                            WHEN OTHERS THEN
                                BEGIN
                                -- Include different date arrangements
                                    v_normalized_timestamp := TO_TIMESTAMP ( p_timestamp, 'MM-DD-YYYY HH12:MI AM' );
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        BEGIN
                                        -- Assume time zone information is included
                                            v_normalized_timestamp := TO_TIMESTAMP_TZ ( p_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS TZH:TZM'
                                            );
                                        -- Return the formatted string directly here
                                            RETURN to_char(v_normalized_timestamp AT TIME ZONE 'UTC', 'DD-MM-YYYY HH12:MI AM');
                                        END;
                                END;
                        END;
                END;
        END;

    -- Convert and return in standard 'DD-MM-YYYY HH12:MI AM' format
    -- Since the last case directly returns, this line only executes if no time zone was involved
        RETURN to_char(v_normalized_timestamp, 'DD-MM-YYYY HH12:MI AM');
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20002, 'Unexpected error while normalizing timestamp: ');
    END flexiblenormalizetimestamp;

    PROCEDURE show_available_slots_by_lot_and_time (
        p_name       VARCHAR,
        p_start_time VARCHAR,
        p_end_time   VARCHAR
    ) IS

        v_start_time        TIMESTAMP;
        v_end_time          TIMESTAMP;
        v_cursor            SYS_REFCURSOR;
        v_parking_slot_name VARCHAR2(50);
        v_floor_level       VARCHAR2(50);
        v_max_height        NUMBER;
        v_lot_name          VARCHAR2(50);
        v_price_per_hour    NUMBER;
        v_duration_hours    NUMBER;
        v_approx_cost       NUMBER;
        v_lot_count         NUMBER;
        v_duration_minutes  NUMBER;
        v_same_day          BOOLEAN;
    -- Define an exception for invalid date formats
        e_invalid_date_format EXCEPTION;
    BEGIN
	
	IF ( p_start_time is NULL )OR (p_end_time is NULL ) THEN
            dbms_output.put_line('Start time and End time must be provided.');
            RETURN;
        END IF;
    -- Attempt to convert string dates to TIMESTAMP
        BEGIN
            v_start_time := TO_TIMESTAMP ( p_start_time, 'YYYY-MM-DD HH:MI AM' );
            v_end_time := TO_TIMESTAMP ( p_end_time, 'YYYY-MM-DD HH:MI AM' );
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Date format is not correct. Accepted formats: YYYY-MM-DD HH:MI AM/PM');
                RETURN;
        END;
		
		-- Check if start and end times are on the same day
        v_same_day := trunc(v_start_time) = trunc(v_end_time);
        IF NOT v_same_day THEN
            dbms_output.put_line('Start and end times must be on the same day.');
            RETURN;
        END IF;
        IF v_start_time > v_end_time THEN
            dbms_output.put_line('Start time cannot be greater than end time.');
            RETURN;
        END IF;

    -- Validate time increments (on the hour or half-hour)
        IF ( EXTRACT(MINUTE FROM v_start_time) NOT IN ( 0, 30 ) ) THEN
            dbms_output.put_line('Start time must be on the hour or half-hour.');
            RETURN;
        END IF;

        IF ( EXTRACT(MINUTE FROM v_end_time) NOT IN ( 0, 30 ) ) THEN
            dbms_output.put_line('End time must be on the hour or half-hour.');
            RETURN;
        END IF;

    -- Validate minimum duration (at least 1 hour)
        v_duration_hours := extract(HOUR FROM ( v_end_time - v_start_time )) + round(extract(MINUTE FROM(v_end_time - v_start_time)) / 60.0
        );
	
	
    -- Calculate the duration between start time and end time in minutes
        v_duration_minutes := extract(HOUR FROM ( v_end_time - v_start_time )) * 60 + extract(MINUTE FROM ( v_end_time - v_start_time
        ));

-- Validate minimum booking duration (at least 1 hour)
        IF v_duration_minutes < 60 THEN
            dbms_output.put_line('The minimum slot booking duration is 1 hour.');
            RETURN;
        END IF;

    -- Check if the lot name exists
        SELECT
            COUNT(*)
        INTO v_lot_count
        FROM
            parking_lot
        WHERE
            upper(name) = upper(p_name);

        IF v_lot_count = 0 THEN
            dbms_output.put_line('Please enter the correct lot name. No lot name matched as per the input');
            RETURN;
        END IF;

    -- Fetch available slots
        v_cursor := available_slots_by_lot_and_time(p_name, v_start_time, v_end_time);

    -- Print column headers
        dbms_output.put_line(rpad('Parking Slot Name', 20)
                             || rpad('Floor Level', 15)
                             || rpad('Max Height', 16)
                             || rpad('Lot Name', 26)
                             || rpad('Estimated Price', 15));

        dbms_output.put_line(rpad('-', 20, '-')
                             || rpad('-', 30, '-')
                             || rpad('-', 15, '-')
                             || rpad('-', 15, '-')
                             || rpad('-', 15, '-'));

    -- Display results
        LOOP
            FETCH v_cursor INTO
                v_parking_slot_name,
                v_floor_level,
                v_max_height,
                v_lot_name,
                v_price_per_hour;
            EXIT WHEN v_cursor%notfound;
        
        -- Calculate the approximate cost
            v_approx_cost := v_duration_hours * v_price_per_hour;
        
        -- Format each column to align text and ensure the table looks tidy
            dbms_output.put_line(rpad(v_parking_slot_name, 20)
                                 || rpad(v_floor_level, 12)
                                 || rpad(to_char(v_max_height, '999.99'), 15)
                                 || lpad(v_lot_name, 20)
                                 || lpad(to_char(v_approx_cost, 'FM99990.00'), 15));

        END LOOP;

    -- Close the cursor
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('No Data Found for lot or other error: ' || sqlerrm);
        -- Close cursor if open and error occurs
            IF v_cursor%isopen THEN
                CLOSE v_cursor;
            END IF;
            RAISE;
    END show_available_slots_by_lot_and_time;

    PROCEDURE book_parking_slot (
        p_slot_name        VARCHAR,
        p_floor_level      VARCHAR,
        p_lot_name         VARCHAR,
        p_vehicle_reg_no   VARCHAR,
        p_start_time       VARCHAR,
        p_end_time         VARCHAR,
        p_transaction_type VARCHAR,
        p_amount           NUMBER
    ) IS

        v_parking_slot_id  NUMBER;
        v_price_per_hour   NUMBER;
        v_hours            NUMBER;
        v_hours_1          NUMBER;
        v_hours_2          NUMBER;
        v_payment_id       NUMBER;
        v_expected_amount  NUMBER;
        v_duration_hours   NUMBER;
        v_duration_minutes NUMBER;
        v_start_time       TIMESTAMP;
        v_end_time         TIMESTAMP;
        v_lot_count        NUMBER;
        v_floor_count      NUMBER;
        v_booking_id       NUMBER;
        v_same_day         BOOLEAN;
		

    -- Define an exception for invalid date formats
        e_invalid_date_format EXCEPTION;
    BEGIN
	
	
		IF ( p_start_time is NULL )OR (p_end_time is NULL ) THEN
            dbms_output.put_line('Start time and End time must be provided.');
            RETURN;
        END IF;
		
        BEGIN
            v_start_time := TO_TIMESTAMP ( p_start_time, 'YYYY-MM-DD HH:MI AM' );
            v_end_time := TO_TIMESTAMP ( p_end_time, 'YYYY-MM-DD HH:MI AM' );
			--dbms_output.put_line('The start time is done' || v_start_time);
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Date format is not correct. Accepted formats: YYYY-MM-DD HH:MI AM/PM');
                RETURN;
        END;

		 -- Check if start and end times are on the same day
        v_same_day := trunc(v_start_time) = trunc(v_end_time);
        IF NOT v_same_day THEN
            dbms_output.put_line('Start and end times must be on the same day.');
            RETURN;
        END IF;
        IF v_start_time > v_end_time THEN
            dbms_output.put_line('Start time cannot be greater than end time.');
            RETURN;
        END IF;

    -- Validate time increments (on the hour or half-hour)
        IF ( EXTRACT(MINUTE FROM v_start_time) NOT IN ( 0, 30 ) ) THEN
            dbms_output.put_line('Start time must be on the hour or half-hour.');
            RETURN;
        END IF;

        IF ( EXTRACT(MINUTE FROM v_end_time) NOT IN ( 0, 30 ) ) THEN
            dbms_output.put_line('End time must be on the hour or half-hour.');
            RETURN;
        END IF;

    -- Validate minimum duration (at least 1 hour)
        v_duration_hours := extract(HOUR FROM ( v_end_time - v_start_time )) + round(extract(MINUTE FROM(v_end_time - v_start_time)) / 60.0
        );

        --dbms_output.put_line('The booking duration is ' || v_duration_hours);
	
	
    -- Calculate the duration between start time and end time in minutes
        v_duration_minutes := extract(HOUR FROM ( v_end_time - v_start_time )) * 60 + extract(MINUTE FROM ( v_end_time - v_start_time
        ));

-- Validate minimum booking duration (at least 1 hour)
        IF v_duration_minutes < 60 THEN
            dbms_output.put_line('The minimum slot booking duration is 1 hour.');
            RETURN;
        END IF;

    -- Check if the lot name exists
        SELECT
            COUNT(*)
        INTO v_lot_count
        FROM
            parking_lot
        WHERE
            upper(name) = upper(p_lot_name);

        IF v_lot_count = 0 THEN
            dbms_output.put_line('Please enter the correct lot name. No lot name matched as per the input');
            RETURN;
        END IF;
		
		-- Check if the floor name exists
        SELECT
            COUNT(*)
        INTO v_floor_count
        FROM
            floor
        WHERE
            upper(floor_level) = upper(p_floor_level);

        IF v_floor_count = 0 THEN
            dbms_output.put_line('Please enter the correct Floor level name. No floor name matched as per the input');
            RETURN;
        END IF;
		
		
    -- Validate transaction type
        IF TRIM(lower(p_transaction_type)) NOT IN ( 'debit', 'credit' ) THEN
            dbms_output.put_line('Transaction type must be "debit" or "credit".');
            RETURN;
        END IF;

 
    -- Lookup slot ID and pricing
        SELECT
            ps.parking_slot_id,
            pl.pricing_per_hour
        INTO
            v_parking_slot_id,
            v_price_per_hour
        FROM
                 parking_slot ps
            JOIN floor       f ON f.floor_id = ps.floor_id
            JOIN parking_lot pl ON pl.parking_lot_id = f.parking_lot_id
        WHERE
                upper(TRIM(ps.slot_name)) = upper(TRIM(p_slot_name))
            AND upper(TRIM(f.floor_level)) = upper(TRIM(p_floor_level))
            AND upper(TRIM(pl.name)) = upper(TRIM(p_lot_name));

        --dbms_output.put_line('Slot ID selected' || v_parking_slot_id);

    -- Calculate the expected payment amount
        v_expected_amount := v_duration_hours * v_price_per_hour;
        IF p_amount != v_expected_amount THEN
            dbms_output.put_line('Incorrect payment amount. Price doesnt match ');
            RETURN;
        END IF;

    -- Insert payment information first
        INSERT INTO payment (
            payment_id,
            transaction_type,
            transaction_date,
            amount
        ) VALUES (
            payment_val.NEXTVAL,
            p_transaction_type,
            systimestamp,
            p_amount
        ) RETURNING payment_id INTO v_payment_id;
		--dbms_output.put_line('Payment successful');
		
		-- Check if the vehicle is present 
        SELECT
            COUNT(*)
        INTO v_hours_2
        FROM
            vehicle
        WHERE
            registration_no = p_vehicle_reg_no;

        IF v_hours_2 = 0 THEN
            dbms_output.put_line('Vehicle not found. Please add vehicle first.');
            RETURN;
        END IF;
		
		
		-- Check if the slot is already booked for the requested time for the same vehicle ID
        SELECT
            COUNT(*)
        INTO v_hours_1
        FROM
            slot_booking
        WHERE
                vehicle_id = (
                    SELECT
                        vehicle_id
                    FROM
                        vehicle
                    WHERE
                        registration_no = p_vehicle_reg_no
                )
            AND NOT ( scheduled_end_time <= v_start_time
                      OR scheduled_start_time >= v_end_time );

        IF v_hours_1 > 0 THEN
            dbms_output.put_line('The slot is already booked for the requested time for the same vehicle.');
            RETURN;
        END IF;

    -- Check slot availability
        SELECT
            COUNT(*)
        INTO v_hours
        FROM
            slot_booking
        WHERE
                parking_slot_id = v_parking_slot_id
            AND NOT ( scheduled_end_time <= v_start_time
                      OR scheduled_start_time >= v_end_time );
		--dbms_output.put_line('Slot booking count is ' || v_hours);
        IF v_hours > 0 THEN
            dbms_output.put_line('The slot is already booked for the requested time. Please check for a different slot');
            RETURN;
        END IF;
		
		--dbms_output.put_line('Scheduled start time is' || v_start_time);
		--dbms_output.put_line('Schedule end time is' || v_end_time);
	
    -- Insert booking details
        INSERT INTO slot_booking (
            slot_booking_id,
            parking_slot_id,
            scheduled_start_time,
            scheduled_end_time,
            payment_id,
            vehicle_id
        ) VALUES (
            slot_booking_val.NEXTVAL,
            v_parking_slot_id,
            v_start_time,
            v_end_time,
            v_payment_id,
            (
                SELECT
                    vehicle_id
                FROM
                    vehicle
                WHERE
                    registration_no = p_vehicle_reg_no
            )
        ) RETURNING slot_booking_id INTO v_booking_id;

-- Display the slot_booking_id
        dbms_output.put_line('Booking successful. Slot Booking ID: ' || v_booking_id || '. Please use this ID to check in and check out your vehicle as well as to submit your feedback.');

    -- Commit the transaction to save the booking and payment
        COMMIT;
    EXCEPTION
        WHEN no_data_found THEN
            ROLLBACK;
            dbms_output.put_line('Invalid slot, floor, lot name, or vehicle registration number or payment amount provided.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END book_parking_slot;

    PROCEDURE view_customer_booking_history (
        p_email VARCHAR
    ) IS
        v_booking_count NUMBER;
    BEGIN
        SELECT
            COUNT(*)
        INTO v_booking_count
        FROM
                 slot_booking sb
            JOIN vehicle  v ON sb.vehicle_id = v.vehicle_id
            JOIN customer c ON v.customer_id = c.customer_id
        WHERE
            c.email = p_email;

        -- If no bookings found, raise no_data_found exception
        IF v_booking_count = 0 THEN
            RAISE no_data_found;
        END IF;
        FOR r IN (
            SELECT
                c.email,
                v.registration_no,
                pl.name  AS lot_name,
                f.floor_level,
                ps.slot_name,
                sb.slot_booking_id,
                p.amount AS paid_amount,
                ci.actual_start_time,
                ci.actual_end_time,
                sb.scheduled_start_time,
                sb.scheduled_end_time
            FROM
                     customer c
                JOIN vehicle      v ON c.customer_id = v.customer_id
                JOIN slot_booking sb ON v.vehicle_id = sb.vehicle_id
                JOIN parking_slot ps ON sb.parking_slot_id = ps.parking_slot_id
                JOIN floor        f ON ps.floor_id = f.floor_id
                JOIN parking_lot  pl ON f.parking_lot_id = pl.parking_lot_id
                JOIN payment      p ON sb.payment_id = p.payment_id
                LEFT JOIN check_in     ci ON sb.slot_booking_id = ci.slot_booking_id
            WHERE
                c.email = p_email
            ORDER BY
                sb.scheduled_start_time DESC
        ) LOOP
        -- Display booking details and check-in status
            dbms_output.put_line('Email: '
                                 || r.email
                                 || ', Vehicle: '
                                 || r.registration_no
                                 || ', Lot: '
                                 || r.lot_name
                                 || ', Floor: '
                                 || r.floor_level
                                 || ', Slot: '
                                 || r.slot_name
                                 || ', Booking ID: '
                                 || r.slot_booking_id
                                 || ', Paid Amount: $'
                                 || r.paid_amount
                                 || ', Start: '
                                 || r.scheduled_start_time
                                 || ', End: '
                                 || r.scheduled_end_time
                                 || ', Status: '
                                 || CASE
                WHEN r.actual_start_time IS NOT NULL THEN
                    'Checked in at '
                    || r.actual_start_time
                    || ', Checked out at '
                    ||(
                        CASE
                            WHEN r.actual_end_time IS NOT NULL THEN
                                to_char(r.actual_end_time)
                            ELSE 'Still checked in'
                        END
                    )
                WHEN
                    systimestamp > r.scheduled_start_time
                    AND r.actual_start_time IS NULL
                THEN
                    'Missed check-in'
                ELSE 'Yet to check in'
            END);
        END LOOP;

    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('No bookings found for the specified email.');
        WHEN OTHERS THEN
            dbms_output.put_line('Error occurred');
        -- Re-raise the exception
            RAISE;
    END view_customer_booking_history;

    PROCEDURE cancel_booking (
        p_booking_id         NUMBER,
        cancel_initiate_time VARCHAR
    ) IS
        v_checked_in    NUMBER;
        v_payment_id    NUMBER;
        v_booking_count NUMBER;
        v_start_time    TIMESTAMP;
        v_time_diff     NUMBER;
        v_cancel_time   TIMESTAMP;
    BEGIN
    -- Check if the booking ID exists
        SELECT
            COUNT(*)
        INTO v_checked_in
        FROM
            check_in
        WHERE
            slot_booking_id = p_booking_id;

        BEGIN
            v_cancel_time := TO_TIMESTAMP ( cancel_initiate_time, 'YYYY-MM-DD HH:MI AM' );
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Date format is not correct. Accepted formats: YYYY-MM-DD HH:MI AM/PM');
                RETURN;
        END;

        IF v_checked_in > 0 THEN
        -- Booking has been checked in, cannot cancel
            dbms_output.put_line('Cannot cancel booking because check-in has already occurred.');
            RETURN;
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO v_booking_count
                FROM
                    slot_booking
                WHERE
                    slot_booking_id = p_booking_id;

                IF v_booking_count = 0 THEN
                -- Slot booking ID does not exist
                    dbms_output.put_line('Invalid slot booking ID provided.');
                    RETURN;
                ELSE
                -- Retrieve the start time of the booking
                    SELECT
                        scheduled_start_time,
                        payment_id
                    INTO
                        v_start_time,
                        v_payment_id
                    FROM
                        slot_booking
                    WHERE
                        slot_booking_id = p_booking_id;

                -- Calculate the difference in minutes between start time and cancellation time
                    v_time_diff := extract(DAY FROM ( v_start_time - v_cancel_time )) * 1440 + extract(HOUR FROM ( v_start_time - v_cancel_time
                    )) * 60 + extract(MINUTE FROM ( v_start_time - v_cancel_time ));

                -- Check if the cancellation is initiated less than 120 minutes before start time
                    IF v_time_diff <= 120 THEN
                        dbms_output.put_line('Cancellation must be initiated at least 120 minutes before the start time.');
                        RETURN;
                    END IF;

                -- Delete the entry from the slot_booking table
                    DELETE FROM slot_booking
                    WHERE
                        slot_booking_id = p_booking_id;

                -- Delete the entry from the payment table
                    DELETE FROM payment
                    WHERE
                        payment_id = v_payment_id;

                -- Commit the transaction
                    COMMIT;

                -- Display success message
                    dbms_output.put_line('Booking with ID '
                                         || p_booking_id
                                         || ' has been canceled successfully.');
                END IF;

            EXCEPTION
                WHEN no_data_found THEN
                    dbms_output.put_line('Booking with ID '
                                         || p_booking_id
                                         || ' not found.');
                    RETURN;
            END;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error occurred while canceling the booking.');
        -- Rollback the transaction
            ROLLBACK;
        -- Re-raise the exception
            RAISE;
    END cancel_booking;

    PROCEDURE perform_check_in (
        p_slot_booking_id   NUMBER,
        p_actual_start_time VARCHAR
    ) IS
        v_scheduled_start_time TIMESTAMP;
        v_scheduled_end_time   TIMESTAMP;
        v_actual_start_time    TIMESTAMP;
        v_count                NUMBER;
		v_count_1              NUMBER;
    BEGIN
        BEGIN
            v_actual_start_time := TO_TIMESTAMP ( p_actual_start_time, 'YYYY-MM-DD HH:MI AM' );
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Date format is not correct. Accepted formats: YYYY-MM-DD HH:MI AM/PM');
                RETURN;
        END;
    -- Check existence and retrieve the scheduled start time
        SELECT
            scheduled_start_time,
            scheduled_end_time
        INTO
            v_scheduled_start_time,
            v_scheduled_end_time
        FROM
            slot_booking
        WHERE
                slot_booking_id = p_slot_booking_id
            AND ROWNUM = 1; -- Ensure we only get one record in case of unexpected duplicates

        IF v_actual_start_time < v_scheduled_start_time OR v_actual_start_time > v_scheduled_end_time THEN
            dbms_output.put_line('Check-in time is not within the scheduled time window.');
            RETURN;
        END IF;
		

    -- Ensure there is no prior incomplete check-in (no check-out)
        SELECT
            COUNT(*)
        INTO v_count
        FROM
            check_in
        WHERE
                slot_booking_id = p_slot_booking_id
            AND actual_end_time IS NULL;

        IF v_count > 0 THEN
            dbms_output.put_line('A check-in without a check-out already exists for this booking.');
            RETURN;
        END IF;
		
	--Ensure there is no duplicate check in 
		SELECT
            COUNT(*)
        INTO v_count_1
        FROM
            check_in
        WHERE
                slot_booking_id = p_slot_booking_id
        ;

        IF v_count_1 > 0 THEN
            dbms_output.put_line('A check-in for this slot book id has already occurred.');
            RETURN;
        END IF;

    -- Perform the check-in
        INSERT INTO check_in (
            check_in_id,
            slot_booking_id,
            actual_start_time,
            actual_end_time
        ) VALUES (
            checkin_val.NEXTVAL,
            p_slot_booking_id,
            v_actual_start_time,
            NULL
        );

        COMMIT;
        -- Display success message
        dbms_output.put_line('You have checked in successfully!');
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('Slot booking ID not found. Please provide a correct booking ID.');
            RETURN;
        WHEN OTHERS THEN
            dbms_output.put_line('Error occurred: ' || sqlerrm);
            ROLLBACK;
            RAISE;
    END perform_check_in;

    PROCEDURE perform_check_out (
        p_slot_booking_id NUMBER,
        p_actual_end_time VARCHAR
    ) IS
        v_scheduled_end_time    TIMESTAMP;
        v_actual_end_time       TIMESTAMP;
        v_actual_end_time_check TIMESTAMP;
        v_additional_time       INTERVAL DAY TO SECOND;
        v_check_in_time         TIMESTAMP;
    BEGIN
    -- Convert actual end time from string to TIMESTAMP
        BEGIN
            v_actual_end_time := TO_TIMESTAMP ( p_actual_end_time, 'YYYY-MM-DD HH:MI AM' );
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Date format is not correct. Accepted formats: YYYY-MM-DD HH:MI AM/PM');
                RETURN;
        END;

    -- Check existence and retrieve the scheduled end time and check-in time
        SELECT
            scheduled_end_time,
            actual_start_time
        INTO
            v_scheduled_end_time,
            v_check_in_time
        FROM
                 slot_booking
            JOIN check_in ON slot_booking.slot_booking_id = check_in.slot_booking_id
        WHERE
            slot_booking.slot_booking_id = p_slot_booking_id;

    -- Check if the slot booking ID is not available
        IF v_scheduled_end_time IS NULL THEN
            dbms_output.put_line('Slot booking ID not found.');
            RETURN;
        END IF;

    -- Check if actual end time is already populated
        SELECT
            actual_end_time
        INTO v_actual_end_time_check
        FROM
            check_in
        WHERE
            slot_booking_id = p_slot_booking_id;

        IF v_actual_end_time_check IS NOT NULL THEN
            dbms_output.put_line('End time already populated. This is duplicate check out.');
            RETURN;
        END IF;

    -- Validate if checkout time is greater than check-in time
        IF v_actual_end_time <= v_check_in_time THEN
            dbms_output.put_line('Check out time must be greater than check in time.');
            RETURN;
        END IF;

    -- Calculate additional time if actual end time is greater than scheduled end time
        IF v_actual_end_time > v_scheduled_end_time THEN
            v_additional_time := v_actual_end_time - v_scheduled_end_time;
            dbms_output.put_line('You have checked out successfully!');
            dbms_output.put_line('Additional time: '
                                 || extract(HOUR FROM v_additional_time)
                                 || ' Hours '
                                 || extract(MINUTE FROM v_additional_time)
                                 || ' Minutes');

        END IF;

    -- Update the check-in record with check-out time
        UPDATE check_in
        SET
            actual_end_time = v_actual_end_time
        WHERE
            slot_booking_id = p_slot_booking_id;

        COMMIT;
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('Slot booking ID or Check-in record not found.');
            RETURN;
        WHEN OTHERS THEN
            dbms_output.put_line('Error occurred');
            ROLLBACK;
            RAISE;
    END perform_check_out;

    PROCEDURE submit_feedback (
        p_slot_booking_id NUMBER,
        p_rating          NUMBER,
        p_comments        VARCHAR2
    ) AS
        v_check_in_id     NUMBER;
        v_word_count      INT;
        v_feedback_exists NUMBER;
    BEGIN

-- Check if the customer has checked in
        SELECT
            check_in_id
        INTO v_check_in_id
        FROM
            check_in
        WHERE
                slot_booking_id = p_slot_booking_id
            AND actual_end_time IS NOT NULL
            AND ROWNUM = 1;  -- Ensures only one row is returned

-- If no check-in record is found, print an error message
        IF v_check_in_id IS NULL THEN
            dbms_output.put_line('No check-in record found for the provided booking ID. Only checked-in customers can provide feedback.'
            );
            RETURN;
        END IF;

-- Check if feedback has already been provided
        SELECT
            COUNT(*)
        INTO v_feedback_exists
        FROM
            feedback
        WHERE
            check_in_id = v_check_in_id;

        IF v_feedback_exists > 0 THEN
            dbms_output.put_line('Feedback has already been provided for this booking.');
            RETURN;
        END IF;

-- Validate the rating
        IF p_rating < 1 OR p_rating > 5 THEN
            dbms_output.put_line('Rating must be between 1 and 5.');
            RETURN;
        END IF;

-- Validate the comment word count
        SELECT
            length(regexp_replace(p_comments, '\s+', ' ')) - length(replace(regexp_replace(p_comments, '\s+', ' '),
                                                                            ' ',
                                                                            '')) + 1
        INTO v_word_count
        FROM
            dual;

        IF v_word_count > 255 THEN
            dbms_output.put_line('Comments should not exceed 255 words.');
            RETURN;
        END IF;

-- Insert the feedback
        INSERT INTO feedback (
            feedback_id,
            rating,
            comments,
            check_in_id
        ) VALUES (
            feedback_val.NEXTVAL,
            p_rating,
            p_comments,
            v_check_in_id
        );

        COMMIT;  -- Ensure changes are committed

        dbms_output.put_line('Feedback submitted successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Unexpected error: ');
            ROLLBACK;  -- Rollback changes on error
    END submit_feedback;

END spms_slot_booking_pkg;
/