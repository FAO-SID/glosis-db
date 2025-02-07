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


