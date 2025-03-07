-- OBJECT: procedure_phys_chem
-- ISSUE: add data from https://github.com/glosis-ld/glosis/blob/master/csv_codelists/glosis_procedure.csv


DROP TABLE IF EXISTS core.procedure_phys_chem_tmp;
CREATE TABLE IF NOT EXISTS core.procedure_phys_chem_tmp (
	attribute text,
    instance text,
    parent_instance text,
    notation text,
    label text,
    definition text,
    reference text,
    citation text,
    isproperty text,
    concept_definition text,
    pub_chem text,
    inchi_key text,
    inchi text,
	CONSTRAINT procedure_phys_chem_tmp_pkey PRIMARY KEY (attribute, instance)
    );

COPY core.procedure_phys_chem_tmp FROM '/tmp/glosis_procedure.csv' WITH (FORMAT CSV, HEADER, NULL ''); --275
SELECT count(*) FROM core.procedure_phys_chem; --298

ALTER TABLE core.procedure_phys_chem ADD COLUMN definition text;
ALTER TABLE core.procedure_phys_chem ADD COLUMN reference text;
ALTER TABLE core.procedure_phys_chem ADD COLUMN citation text;

UPDATE core.procedure_phys_chem SET definition = t.definition FROM core.procedure_phys_chem_tmp t WHERE procedure_phys_chem_id = t.instance;
UPDATE core.procedure_phys_chem SET reference = t.reference FROM core.procedure_phys_chem_tmp t WHERE procedure_phys_chem_id = t.instance;
UPDATE core.procedure_phys_chem SET citation = t.citation FROM core.procedure_phys_chem_tmp t WHERE procedure_phys_chem_id = t.instance;

SELECT procedure_phys_chem_id FROM core.procedure_phys_chem
 EXCEPT
SELECT instance FROM core.procedure_phys_chem_tmp; --48
-- SaSiCl_2-20-2000u-nodisp
-- SaSiCl_2-50-2000u-disp-hydrometer
-- SaSiCl_2-20-2000u-disp-hydrometer
-- SaSiCl_2-50-2000u-nodisp-pipette
-- SaSiCl_2-64-2000u-disp-beaker
-- SaSiCl_2-64-2000u-nodisp-hydrometer-bouy
-- SaSiCl_2-20-2000u-fld
-- SaSiCl_2-20-2000u-disp-beaker
-- SaSiCl_2-50-2000u
-- SaSiCl_2-20-2000u-nodisp-pipette
-- SaSiCl_2-64-2000u-adj100
-- SaSiCl_2-64-2000u
-- SaSiCl_2-20-2000u-disp-hydrometer-bouy
-- SaSiCl_2-50-2000u-nodisp
-- SaSiCl_2-50-2000u-disp-beaker
-- SaSiCl_2-20-2000u-disp-pipette
-- SaSiCl_2-64-2000u-disp-hydrometer-bouy
-- SaSiCl_2-64-2000u-disp-hydrometer
-- SaSiCl_2-64-2000u-nodisp-pipette
-- SaSiCl_2-64-2000u-nodisp-hydrometer
-- SaSiCl_2-50-2000u-fld
-- SaSiCl_2-20-2000u
-- SaSiCl_2-64-2000u-nodisp-laser
-- SaSiCl_2-64-2000u-disp
-- SaSiCl_2-50-2000u-disp-hydrometer-bouy
-- SaSiCl_2-64-2000u-fld
-- SaSiCl_2-50-2000u-disp-spec
-- SaSiCl_2-64-2000u-nodisp
-- SaSiCl_2-20-2000u-disp-spec
-- SaSiCl_2-50-2000u-disp-pipette
-- SaSiCl_2-20-2000u-nodisp-laser
-- SaSiCl_2-64-2000u-nodisp-spec
-- SaSiCl_2-50-2000u-adj100
-- SaSiCl_2-20-2000u-adj100
-- SaSiCl_2-64-2000u-disp-spec
-- SaSiCl_2-20-2000u-nodisp-hydrometer-bouy
-- SaSiCl_2-20-2000u-disp-laser
-- SaSiCl_2-20-2000u-disp
-- SaSiCl_2-50-2000u-nodisp-hydrometer-bouy
-- SaSiCl_2-50-2000u-disp
-- SaSiCl_2-20-2000u-nodisp-spec
-- SaSiCl_2-50-2000u-nodisp-spec
-- SaSiCl_2-50-2000u-disp-laser
-- SaSiCl_2-64-2000u-disp-laser
-- SaSiCl_2-50-2000u-nodisp-hydrometer
-- SaSiCl_2-64-2000u-disp-pipette
-- SaSiCl_2-50-2000u-nodisp-laser
-- SaSiCl_2-20-2000u-nodisp-hydrometer

SELECT instance FROM core.procedure_phys_chem_tmp
 EXCEPT
SELECT procedure_phys_chem_id FROM core.procedure_phys_chem; --25
-- hydrometer-disp
-- hydrometer-disp-spec
-- laser-nodisp
-- fldest
-- beaker-unkdisp-spec
-- laser-unkdisp
-- pipette-unkdisp-spec
-- hydrometer-nodisp-spec
-- beaker-nodisp
-- beaker-nodisp-spec
-- beaker-disp-spec
-- laser-unkdisp-spec
-- pipette-nodisp-spec
-- pipette-disp
-- hydrometer-unkdisp-spec
-- hydrometer-unkdisp
-- beaker-unkdisp
-- pipette-unkdisp
-- laser-disp-spec
-- laser-nodisp-spec
-- hydrometer-nodisp
-- pipette-disp-spec
-- beaker-disp
-- laser-disp
-- pipette-nodisp

SELECT instance FROM core. procedure_phys_chem_tmp
 INTERSECT
SELECT procedure_phys_chem_id FROM core. procedure_phys_chem;--250
