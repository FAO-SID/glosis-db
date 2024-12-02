-- OBJECT: core.observation_desc_specimen, property_desc_specimen, thesaurus_desc_specimen
-- ISSUE: redundancy between these two tables


ALTER TABLE IF EXISTS core.observation_desc_element DROP CONSTRAINT fk_property_desc_element;
ALTER TABLE IF EXISTS core.observation_desc_element DROP CONSTRAINT fk_thesaurus_desc_element;

ALTER TABLE IF EXISTS core.property_desc_element RENAME TO property_desc;
ALTER TABLE IF EXISTS core.property_desc RENAME COLUMN property_desc_element_id TO property_desc_id;
ALTER TABLE IF EXISTS core.property_desc DROP CONSTRAINT property_desc_element_pkey;
ALTER TABLE IF EXISTS core.property_desc ADD PRIMARY KEY (property_desc_id);

ALTER TABLE IF EXISTS core.thesaurus_desc_element RENAME TO thesaurus_desc;
ALTER TABLE IF EXISTS core.thesaurus_desc RENAME COLUMN thesaurus_desc_element_id TO thesaurus_desc_id;
ALTER TABLE IF EXISTS core.thesaurus_desc DROP CONSTRAINT thesaurus_desc_element_pkey;
ALTER TABLE IF EXISTS core.thesaurus_desc ADD PRIMARY KEY (thesaurus_desc_id);

ALTER TABLE IF EXISTS core.observation_desc_element RENAME TO observation_desc;
ALTER TABLE IF EXISTS core.observation_desc RENAME COLUMN property_desc_element_id TO property_desc_id;
ALTER TABLE IF EXISTS core.observation_desc RENAME COLUMN thesaurus_desc_element_id TO thesaurus_desc_id;
ALTER TABLE IF EXISTS core.observation_desc ADD FOREIGN KEY (property_desc_id) REFERENCES core.property_desc(property_desc_id);
ALTER TABLE IF EXISTS core.observation_desc ADD FOREIGN KEY (thesaurus_desc_id) REFERENCES core.thesaurus_desc(thesaurus_desc_id);

ALTER TABLE IF EXISTS core.result_desc_specimen DROP CONSTRAINT result_desc_specimen_property_desc_specimen_id_thesaurus_d_fkey;
ALTER TABLE IF EXISTS core.result_desc_specimen RENAME COLUMN property_desc_specimen_id TO property_desc_id;
ALTER TABLE IF EXISTS core.result_desc_specimen RENAME COLUMN thesaurus_desc_specimen_id TO thesaurus_desc_id;

ALTER TABLE IF EXISTS core.result_desc_element DROP CONSTRAINT result_desc_element_property_desc_element_id_thesaurus_des_fkey;
ALTER TABLE IF EXISTS core.result_desc_element RENAME COLUMN property_desc_element_id TO property_desc_id;
ALTER TABLE IF EXISTS core.result_desc_element RENAME COLUMN thesaurus_desc_element_id TO thesaurus_desc_id;

ALTER TABLE IF EXISTS core.result_desc_specimen ADD FOREIGN KEY (property_desc_id,thesaurus_desc_id) REFERENCES core.observation_desc(property_desc_id,thesaurus_desc_id);
ALTER TABLE IF EXISTS core.result_desc_element  ADD FOREIGN KEY (property_desc_id,thesaurus_desc_id) REFERENCES core.observation_desc(property_desc_id,thesaurus_desc_id);

DROP TABLE IF EXISTS core.observation_desc_specimen;
DROP TABLE IF EXISTS core.property_desc_specimen;
DROP TABLE IF EXISTS core.thesaurus_desc_specimen;
