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


DROP FUNCTION public.create_category(text, int4, text, text);

CREATE OR REPLACE FUNCTION create_category(
    mapset TEXT, 
    num_intervals INT DEFAULT 10, 
    start_color TEXT DEFAULT '#F4E7D3', 
    end_color TEXT DEFAULT '#5C4033'
)
RETURNS VOID AS $$
DECLARE
    min_value FLOAT;
    max_value FLOAT;
    range FLOAT;
    interval_size FLOAT;
    current_min FLOAT;
    current_max FLOAT;
    i INT := 1;
    start_r INT;
    start_g INT;
    start_b INT;
    end_r INT;
    end_g INT;
    end_b INT;
    color TEXT;
BEGIN
    -- Validate num_intervals
    IF num_intervals <= 0 THEN
        RAISE EXCEPTION 'Number of intervals must be greater than 0.';
    END IF;

    -- Validate start_color and end_color
    IF start_color NOT LIKE '#______' OR end_color NOT LIKE '#______' THEN
        RAISE EXCEPTION 'Colors must be in HEX format (e.g., #F4E7D3).';
    END IF;

    -- Fetch min_value and max_value from the observations table for the given mapset_id
    SELECT avg(stats_minimum), avg(stats_maximum) INTO min_value, max_value
    FROM metadata.layer
    WHERE mapset_id = mapset
    GROUP BY mapset_id;

    -- Check if mapset_id exists
    IF min_value IS NULL OR max_value IS NULL THEN
        RAISE EXCEPTION 'mapset_id % does not exist or has no data.', mapset;
    END IF;

    -- Calculate the range and interval size
    range := max_value - min_value;
    IF range = 0 THEN
        RAISE EXCEPTION 'Range is 0. Cannot create intervals for mapset_id %.', mapset;
    END IF;
    interval_size := range / num_intervals;
    current_min := min_value;
    current_max := min_value + interval_size;

    -- Extract RGB components from start_color and end_color
    start_r := ('x' || SUBSTRING(start_color FROM 2 FOR 2))::BIT(8)::INT;
    start_g := ('x' || SUBSTRING(start_color FROM 4 FOR 2))::BIT(8)::INT;
    start_b := ('x' || SUBSTRING(start_color FROM 6 FOR 2))::BIT(8)::INT;
    end_r := ('x' || SUBSTRING(end_color FROM 2 FOR 2))::BIT(8)::INT;
    end_g := ('x' || SUBSTRING(end_color FROM 4 FOR 2))::BIT(8)::INT;
    end_b := ('x' || SUBSTRING(end_color FROM 6 FOR 2))::BIT(8)::INT;

    -- Loop to create intervals
    WHILE i <= num_intervals LOOP
        -- Interpolate the color based on the interval index
        color := '#' || 
                 LPAD(TO_HEX(start_r + (end_r - start_r) * (i - 1) / (num_intervals - 1)), 2, '0') ||
                 LPAD(TO_HEX(start_g + (end_g - start_g) * (i - 1) / (num_intervals - 1)), 2, '0') ||
                 LPAD(TO_HEX(start_b + (end_b - start_b) * (i - 1) / (num_intervals - 1)), 2, '0');

        -- Insert the class interval and color into the categories table
        INSERT INTO metadata.layer_category (mapset_id, value, code, "label", color, opacity, publish)
        VALUES (mapset, current_min::numeric(10,2), 
               current_min::numeric(10,2) || ' - ' || current_max::numeric(10,2), 
               current_min::numeric(10,2) || ' - ' || current_max::numeric(10,2), 
               color, 1, 't');

        -- Update the current_min and current_max for the next interval
        current_min := current_max;
        current_max := current_max + interval_size;
        i := i + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT create_category('PH-GSAS-EC-2024', 10, '#F4E7D3', '#5C4033');
SELECT create_category('PH-GSAS-EC-2024', 10, '#000249', '#DD1717');





