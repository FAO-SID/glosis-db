-- <sld:ColorMapEntry color="#30123b" quantity="10" label="0 - 10"/>
-- <sld:ColorMapEntry color="#4662d8" quantity="20" label="10 - 20"/>
-- <sld:ColorMapEntry color="#35abf8" quantity="30" label="20 - 30"/>
-- <sld:ColorMapEntry color="#1be5b5" quantity="40" label="30 - 40"/>
-- <sld:ColorMapEntry color="#74fe5d" quantity="50" label="40 - 50"/>
-- <sld:ColorMapEntry color="#c9ef34" quantity="60" label="50 - 60"/>
-- <sld:ColorMapEntry color="#fbb938" quantity="70" label="60 - 70"/>
-- <sld:ColorMapEntry color="#f56918" quantity="80" label="70 - 80"/>
-- <sld:ColorMapEntry color="#c92903" quantity="90" label="80 - 90"/>
-- <sld:ColorMapEntry color="#7a0403" quantity="100" label="90 - 100"/>

SELECT * FROM (VALUES 
('layer_id', 10, '0-10', '#30123b', 1, true),
('layer_id', 20, '10-20', '#4662d8', 1, true),
('layer_id', 30, '20-30', '#35abf8', 1, true),
('layer_id', 40, '30-40', '#1be5b5', 1, true),
('layer_id', 50, '40-50', '#74fe5d', 1, true),
('layer_id', 60, '50-60', '#c9ef34', 1, true),
('layer_id', 70, '60-70', '#fbb938', 1, true),
('layer_id', 80, '70-80', '#f56918', 1, true),
('layer_id', 90, '80-90', '#c92903', 1, true),
('layer_id', 100, '90-100', '#7a0403', 1, true)
) AS temp_table(layer_id, value, label, color, opacity, publish);


DROP FUNCTION function_color(mapset TEXT);

CREATE OR REPLACE FUNCTION function_color(mapset TEXT)
RETURNS VOID AS $$
DECLARE
    min_value FLOAT;
    max_value FLOAT;
    range FLOAT;
    interval_size FLOAT;
    current_min FLOAT;
    current_max FLOAT;
    i INT := 1;
BEGIN
    -- Fetch min_value and max_value from the observations table for the given mapset_id
    SELECT avg(stats_minimum), avg(stats_maximum) INTO min_value, max_value
    FROM metadata.layer
    WHERE mapset_id = mapset
    GROUP BY mapset_id;

    -- Calculate the range and interval size
    range := max_value - min_value;
    interval_size := range / 10;
    current_min := min_value;
    current_max := min_value + interval_size;

    -- Loop to create 10 class intervals
    WHILE i <= 10 LOOP
        -- Generate the color ramp
        DECLARE
            light_brown TEXT := '#F4E7D3';
            dark_brown TEXT := '#5C4033';
            color TEXT;
        BEGIN
            -- Interpolate the color based on the interval index
            color := '#' || LPAD(TO_HEX((255 - (i-1)*25)::INT), 2, '0') || 
                            LPAD(TO_HEX((231 - (i-1)*23)::INT), 2, '0') || 
                            LPAD(TO_HEX((211 - (i-1)*21)::INT), 2, '0');

            -- Insert the class interval and color into the categories table
            INSERT INTO metadata.layer_category (mapset_id, value, code, "label", color, opacity, publish)
            VALUES (mapset, current_min::numeric(10,2), current_min::numeric(10,2)||' - '||current_max::numeric(10,2), current_min::numeric(10,2)||' - '||current_max::numeric(10,2), color, 1, 't');

            -- Update the current_min and current_max for the next interval
            current_min := current_max;
            current_max := current_max + interval_size;
            i := i + 1;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT function_color('PH-GSAS-EC-2024');







