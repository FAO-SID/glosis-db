--
-- PostgreSQL database dump
--

-- Dumped from database version 12.22 (Ubuntu 12.22-2.pgdg22.04+1)
-- Dumped by pg_dump version 17.4 (Ubuntu 17.4-1.pgdg22.04+2)

-- Started on 2025-03-11 11:30:01 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 9 (class 2615 OID 54021813)
-- Name: core; Type: SCHEMA; Schema: -; Owner: glosis
--

CREATE SCHEMA core;


ALTER SCHEMA core OWNER TO glosis;

--
-- TOC entry 4425 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA core; Type: COMMENT; Schema: -; Owner: glosis
--

COMMENT ON SCHEMA core IS 'Core entities and relations from the ISO-28258 domain model';


--
-- TOC entry 10 (class 2615 OID 54021814)
-- Name: metadata; Type: SCHEMA; Schema: -; Owner: glosis
--

CREATE SCHEMA metadata;


ALTER SCHEMA metadata OWNER TO glosis;

--
-- TOC entry 4426 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA metadata; Type: COMMENT; Schema: -; Owner: glosis
--

COMMENT ON SCHEMA metadata IS 'Meta-data model based on VCard: https://www.w3.org/TR/vcard-rdf';


--
-- TOC entry 7 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 54020728)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 4428 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 1036 (class 1255 OID 54023266)
-- Name: check_result_value(); Type: FUNCTION; Schema: core; Owner: glosis
--

CREATE FUNCTION core.check_result_value() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    observation core.observation_phys_chem%ROWTYPE;
BEGIN
    SELECT * 
      INTO observation
      FROM core.observation_phys_chem
     WHERE observation_phys_chem_id = NEW.observation_phys_chem_id;
    
    IF NEW.value < observation.value_min OR NEW.value > observation.value_max THEN
        RAISE EXCEPTION 'Result value outside admissable bounds for the related observation.';
    ELSE
        RETURN NEW;
    END IF; 
END;
$$;


ALTER FUNCTION core.check_result_value() OWNER TO glosis;

--
-- TOC entry 4429 (class 0 OID 0)
-- Dependencies: 1036
-- Name: FUNCTION check_result_value(); Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON FUNCTION core.check_result_value() IS 'Checks if the value assigned to a result record is within the numerical bounds declared in the related observations (fields value_min and value_max).';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 210 (class 1259 OID 54021823)
-- Name: element; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.element (
    element_id integer NOT NULL,
    profile_id integer NOT NULL,
    order_element integer,
    upper_depth integer NOT NULL,
    lower_depth integer NOT NULL,
    type text NOT NULL,
    CONSTRAINT element_check CHECK ((lower_depth > upper_depth)),
    CONSTRAINT element_order_element_check CHECK ((order_element > 0)),
    CONSTRAINT element_type_check CHECK ((type = ANY (ARRAY['Horizon'::text, 'Layer'::text]))),
    CONSTRAINT element_upper_depth_check CHECK ((upper_depth >= 0)),
    CONSTRAINT element_upper_depth_check1 CHECK ((upper_depth <= 500))
);


ALTER TABLE core.element OWNER TO glosis;

--
-- TOC entry 4430 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE element; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.element IS 'ProfileElement is the super-class of Horizon and Layer, which share the same basic properties. Horizons develop in a layer, which in turn have been developed throught geogenesis or anthropogenic action. Layers can be used to describe common characteristics of a set of adjoining horizons. For the time being no assocation is previewed between Horizon and Layer.';


--
-- TOC entry 4431 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN element.element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.element.element_id IS 'Synthetic primary key.';


--
-- TOC entry 4432 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN element.profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.element.profile_id IS 'Reference to the Profile to which this element belongs';


--
-- TOC entry 4433 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN element.order_element; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.element.order_element IS 'Order of this element within the Profile';


--
-- TOC entry 4434 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN element.upper_depth; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.element.upper_depth IS 'Upper depth of this profile element in centimetres.';


--
-- TOC entry 4435 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN element.lower_depth; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.element.lower_depth IS 'Lower depth of this profile element in centimetres.';


--
-- TOC entry 4436 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN element.type; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.element.type IS 'Type of profile element, Horizon or Layer';


--
-- TOC entry 211 (class 1259 OID 54021829)
-- Name: element_element_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.element ALTER COLUMN element_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.element_element_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 212 (class 1259 OID 54021831)
-- Name: observation_desc_element; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.observation_desc_element (
    procedure_desc_id text NOT NULL,
    property_desc_element_id text NOT NULL,
    thesaurus_desc_element_id integer NOT NULL
);


ALTER TABLE core.observation_desc_element OWNER TO glosis;

--
-- TOC entry 4437 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE observation_desc_element; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.observation_desc_element IS 'Descriptive properties for the Surface feature of interest';


--
-- TOC entry 4438 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN observation_desc_element.procedure_desc_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_element.procedure_desc_id IS 'Foreign key to the corresponding procedure.';


--
-- TOC entry 4439 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN observation_desc_element.property_desc_element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_element.property_desc_element_id IS 'Foreign key to the corresponding property';


--
-- TOC entry 4440 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN observation_desc_element.thesaurus_desc_element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_element.thesaurus_desc_element_id IS 'Foreign key to the corresponding thesaurus entry';


--
-- TOC entry 213 (class 1259 OID 54021834)
-- Name: observation_desc_plot; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.observation_desc_plot (
    procedure_desc_id text NOT NULL,
    property_desc_plot_id text NOT NULL,
    thesaurus_desc_plot_id integer NOT NULL
);


ALTER TABLE core.observation_desc_plot OWNER TO glosis;

--
-- TOC entry 4441 (class 0 OID 0)
-- Dependencies: 213
-- Name: TABLE observation_desc_plot; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.observation_desc_plot IS 'Descriptive properties for the Surface feature of interest';


--
-- TOC entry 4442 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN observation_desc_plot.procedure_desc_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_plot.procedure_desc_id IS 'Foreign key to the corresponding procedure.';


--
-- TOC entry 4443 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN observation_desc_plot.property_desc_plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_plot.property_desc_plot_id IS 'Foreign key to the corresponding property';


--
-- TOC entry 4444 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN observation_desc_plot.thesaurus_desc_plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_plot.thesaurus_desc_plot_id IS 'Foreign key to the corresponding thesaurus entry';


--
-- TOC entry 214 (class 1259 OID 54021837)
-- Name: observation_desc_profile; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.observation_desc_profile (
    procedure_desc_id text NOT NULL,
    property_desc_profile_id text NOT NULL,
    thesaurus_desc_profile_id integer NOT NULL
);


ALTER TABLE core.observation_desc_profile OWNER TO glosis;

--
-- TOC entry 4445 (class 0 OID 0)
-- Dependencies: 214
-- Name: TABLE observation_desc_profile; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.observation_desc_profile IS 'Descriptive properties for the Surface feature of interest';


--
-- TOC entry 4446 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN observation_desc_profile.procedure_desc_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_profile.procedure_desc_id IS 'Foreign key to the corresponding procedure.';


--
-- TOC entry 4447 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN observation_desc_profile.property_desc_profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_profile.property_desc_profile_id IS 'Foreign key to the corresponding property';


--
-- TOC entry 4448 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN observation_desc_profile.thesaurus_desc_profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_desc_profile.thesaurus_desc_profile_id IS 'Foreign key to the corresponding thesaurus entry';


--
-- TOC entry 215 (class 1259 OID 54021854)
-- Name: observation_phys_chem; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.observation_phys_chem (
    observation_phys_chem_id integer NOT NULL,
    property_phys_chem_id text NOT NULL,
    procedure_phys_chem_id text NOT NULL,
    unit_of_measure_id text NOT NULL,
    value_min real,
    value_max real
);


ALTER TABLE core.observation_phys_chem OWNER TO glosis;

--
-- TOC entry 4449 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE observation_phys_chem; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.observation_phys_chem IS 'Physio-chemical observations for the Element feature of interest';


--
-- TOC entry 4450 (class 0 OID 0)
-- Dependencies: 215
-- Name: COLUMN observation_phys_chem.observation_phys_chem_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_phys_chem.observation_phys_chem_id IS 'Synthetic primary key for the observation';


--
-- TOC entry 4451 (class 0 OID 0)
-- Dependencies: 215
-- Name: COLUMN observation_phys_chem.property_phys_chem_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_phys_chem.property_phys_chem_id IS 'Foreign key to the corresponding property';


--
-- TOC entry 4452 (class 0 OID 0)
-- Dependencies: 215
-- Name: COLUMN observation_phys_chem.procedure_phys_chem_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_phys_chem.procedure_phys_chem_id IS 'Foreign key to the corresponding procedure';


--
-- TOC entry 4453 (class 0 OID 0)
-- Dependencies: 215
-- Name: COLUMN observation_phys_chem.unit_of_measure_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_phys_chem.unit_of_measure_id IS 'Foreign key to the corresponding unit of measure (if applicable)';


--
-- TOC entry 4454 (class 0 OID 0)
-- Dependencies: 215
-- Name: COLUMN observation_phys_chem.value_min; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_phys_chem.value_min IS 'Minimum admissable value for this combination of property, procedure and unit of measure';


--
-- TOC entry 4455 (class 0 OID 0)
-- Dependencies: 215
-- Name: COLUMN observation_phys_chem.value_max; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.observation_phys_chem.value_max IS 'Maximum admissable value for this combination of property, procedure and unit of measure';


--
-- TOC entry 266 (class 1259 OID 54022873)
-- Name: observation_phys_chem_element_observation_phys_chem_element_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.observation_phys_chem ALTER COLUMN observation_phys_chem_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.observation_phys_chem_element_observation_phys_chem_element_seq
    START WITH 1008
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 216 (class 1259 OID 54021862)
-- Name: plot; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.plot (
    plot_id integer NOT NULL,
    site_id integer NOT NULL,
    plot_code text,
    altitude smallint,
    time_stamp date,
    map_sheet_code text,
    positional_accuracy smallint,
    "position" public.geometry(Point,4326),
    type text,
    CONSTRAINT plot_altitude_check CHECK (((altitude)::numeric > ('-100'::integer)::numeric)),
    CONSTRAINT plot_altitude_check1 CHECK (((altitude)::numeric < (8000)::numeric)),
    CONSTRAINT plot_time_stamp_check CHECK ((time_stamp > '1900-01-01'::date)),
    CONSTRAINT plot_type_check CHECK ((type = ANY (ARRAY['TrialPit'::text, 'Borehole'::text])))
);


ALTER TABLE core.plot OWNER TO glosis;

--
-- TOC entry 4456 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE plot; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.plot IS 'Elementary area or location where individual observations are made and/or samples are taken. Plot is the main spatial feature of interest in ISO-28258. Plot has three sub-classes: Borehole, Pit and Surface. Surface features its own table since it has its own properties and a different geometry.';


--
-- TOC entry 4457 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot.plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot.plot_id IS 'Synthetic primary key.';


--
-- TOC entry 4458 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot.site_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot.site_id IS 'Foreign key to Site table.';


--
-- TOC entry 4459 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot.plot_code; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot.plot_code IS 'Natural key, can be null.';


--
-- TOC entry 4460 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot.altitude; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot.altitude IS 'Altitude at the plot in metres, if known. Property re-used from GloSIS.';


--
-- TOC entry 4461 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot.time_stamp; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot.time_stamp IS 'Time stamp of the plot, if known. Property re-used from GloSIS.';


--
-- TOC entry 4462 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot.map_sheet_code; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot.map_sheet_code IS 'Code identifying the map sheet where the plot may be positioned. Property re-used from GloSIS.';


--
-- TOC entry 4463 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot.positional_accuracy; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot.positional_accuracy IS 'Accuracy in meters of the GPS position.';


--
-- TOC entry 4464 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot."position"; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot."position" IS 'Geodetic coordinates of the spatial position of the plot. Note the uncertainty associated with the WGS84 datum ensemble.';


--
-- TOC entry 4465 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN plot.type; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot.type IS 'Type of plot, TrialPit or Borehole.';


--
-- TOC entry 217 (class 1259 OID 54021871)
-- Name: plot_individual; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.plot_individual (
    plot_id integer NOT NULL,
    individual_id integer NOT NULL
);


ALTER TABLE core.plot_individual OWNER TO glosis;

--
-- TOC entry 4466 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE plot_individual; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.plot_individual IS 'Identifies the individual(s) responsible for surveying a plot';


--
-- TOC entry 4467 (class 0 OID 0)
-- Dependencies: 217
-- Name: COLUMN plot_individual.plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot_individual.plot_id IS 'Foreign key to the plot table, identifies the plot surveyed';


--
-- TOC entry 4468 (class 0 OID 0)
-- Dependencies: 217
-- Name: COLUMN plot_individual.individual_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.plot_individual.individual_id IS 'Foreign key to the individual table, indicates the individual responsible for surveying the plot.';


--
-- TOC entry 218 (class 1259 OID 54021874)
-- Name: plot_plot_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.plot ALTER COLUMN plot_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.plot_plot_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 219 (class 1259 OID 54021876)
-- Name: procedure_desc; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.procedure_desc (
    procedure_desc_id text NOT NULL,
    reference text,
    uri text NOT NULL
);


ALTER TABLE core.procedure_desc OWNER TO glosis;

--
-- TOC entry 4469 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE procedure_desc; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.procedure_desc IS 'Descriptive Procedures for all features of interest. In most cases the procedure is described in a document such as the FAO Guidelines for Soil Description or the World Reference Base of Soil Resources.';


--
-- TOC entry 4470 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN procedure_desc.procedure_desc_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.procedure_desc.procedure_desc_id IS 'Synthetic primary key.';


--
-- TOC entry 4471 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN procedure_desc.reference; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.procedure_desc.reference IS 'Long and human readable reference to the publication.';


--
-- TOC entry 4472 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN procedure_desc.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.procedure_desc.uri IS 'URI to the corresponding publication, optimally a DOI. Follow this URI for the full definition of the procedure.';


--
-- TOC entry 220 (class 1259 OID 54021884)
-- Name: procedure_phys_chem; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.procedure_phys_chem (
    procedure_phys_chem_id text NOT NULL,
    broader_id text,
    uri text NOT NULL,
    definition text,
    reference text,
    citation text
);


ALTER TABLE core.procedure_phys_chem OWNER TO glosis;

--
-- TOC entry 4473 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE procedure_phys_chem; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.procedure_phys_chem IS 'Physio-chemical Procedures for the Profile Element feature of interest';


--
-- TOC entry 4474 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN procedure_phys_chem.procedure_phys_chem_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.procedure_phys_chem.procedure_phys_chem_id IS 'Synthetic primary key.';


--
-- TOC entry 4475 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN procedure_phys_chem.broader_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.procedure_phys_chem.broader_id IS 'Foreign key to brader procedure in the hierarchy';


--
-- TOC entry 4476 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN procedure_phys_chem.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.procedure_phys_chem.uri IS 'URI to the corresponding in a controlled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this procedure';


--
-- TOC entry 221 (class 1259 OID 54021892)
-- Name: profile; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.profile (
    profile_id integer NOT NULL,
    plot_id integer,
    surface_id integer,
    profile_code text,
    CONSTRAINT site_mandatory_foi CHECK ((((plot_id IS NOT NULL) OR (surface_id IS NOT NULL)) AND (NOT ((plot_id IS NOT NULL) AND (surface_id IS NOT NULL)))))
);


ALTER TABLE core.profile OWNER TO glosis;

--
-- TOC entry 4477 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE profile; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.profile IS 'An abstract, ordered set of soil horizons and/or layers.';


--
-- TOC entry 4478 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN profile.profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.profile.profile_id IS 'Synthetic primary key.';


--
-- TOC entry 4479 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN profile.plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.profile.plot_id IS 'Foreign key to Plot feature of interest';


--
-- TOC entry 4480 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN profile.surface_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.profile.surface_id IS 'Foreign key to Surface feature of interest';


--
-- TOC entry 4481 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN profile.profile_code; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.profile.profile_code IS 'Natural primary key, if existing';


--
-- TOC entry 222 (class 1259 OID 54021899)
-- Name: profile_profile_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.profile ALTER COLUMN profile_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.profile_profile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 223 (class 1259 OID 54021901)
-- Name: project; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.project (
    project_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE core.project OWNER TO glosis;

--
-- TOC entry 4482 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE project; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.project IS 'Provides the context of the data collection as a prerequisite for the proper use or reuse of these data.';


--
-- TOC entry 4483 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN project.project_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.project.project_id IS 'Synthetic primary key.';


--
-- TOC entry 4484 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN project.name; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.project.name IS 'Natural key with project name.';


--
-- TOC entry 225 (class 1259 OID 54021910)
-- Name: project_project_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.project ALTER COLUMN project_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.project_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 226 (class 1259 OID 54021912)
-- Name: project_related; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.project_related (
    project_source_id integer NOT NULL,
    project_target_id integer NOT NULL,
    role text NOT NULL
);


ALTER TABLE core.project_related OWNER TO glosis;

--
-- TOC entry 4485 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE project_related; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.project_related IS 'Relationship between two projects, e.g. project B being a sub-project of project A.';


--
-- TOC entry 4486 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN project_related.project_source_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.project_related.project_source_id IS 'Foreign key to source project.';


--
-- TOC entry 4487 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN project_related.project_target_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.project_related.project_target_id IS 'Foreign key to targe project.';


--
-- TOC entry 4488 (class 0 OID 0)
-- Dependencies: 226
-- Name: COLUMN project_related.role; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.project_related.role IS 'Role of source project in target project. This intended to be a code-list but no codes are given in the standard';


--
-- TOC entry 237 (class 1259 OID 54022004)
-- Name: project_site; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.project_site (
    project_id integer NOT NULL,
    site_id integer NOT NULL
);


ALTER TABLE core.project_site OWNER TO glosis;

--
-- TOC entry 4489 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE project_site; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.project_site IS 'Many to many relation between Site and Project.';


--
-- TOC entry 4490 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN project_site.project_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.project_site.project_id IS 'Foreign key to Project table';


--
-- TOC entry 4491 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN project_site.site_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.project_site.site_id IS 'Foreign key to Site table';


--
-- TOC entry 227 (class 1259 OID 54021918)
-- Name: property_desc_element; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.property_desc_element (
    property_desc_element_id text NOT NULL,
    uri text NOT NULL
);


ALTER TABLE core.property_desc_element OWNER TO glosis;

--
-- TOC entry 4492 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE property_desc_element; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.property_desc_element IS 'Descriptive properties for the Element feature of interest';


--
-- TOC entry 4493 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN property_desc_element.property_desc_element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.property_desc_element.property_desc_element_id IS 'Synthetic primary key.';


--
-- TOC entry 4494 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN property_desc_element.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.property_desc_element.uri IS 'URI to the corresponding code in a controled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this property';


--
-- TOC entry 228 (class 1259 OID 54021926)
-- Name: property_desc_plot; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.property_desc_plot (
    property_desc_plot_id text NOT NULL,
    uri text NOT NULL
);


ALTER TABLE core.property_desc_plot OWNER TO glosis;

--
-- TOC entry 4495 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE property_desc_plot; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.property_desc_plot IS 'Descriptive properties for the Plot feature of interest';


--
-- TOC entry 4496 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN property_desc_plot.property_desc_plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.property_desc_plot.property_desc_plot_id IS 'Synthetic primary key.';


--
-- TOC entry 4497 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN property_desc_plot.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.property_desc_plot.uri IS 'URI to the corresponding code in a controled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this property';


--
-- TOC entry 229 (class 1259 OID 54021934)
-- Name: property_desc_profile; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.property_desc_profile (
    property_desc_profile_id text NOT NULL,
    uri text NOT NULL
);


ALTER TABLE core.property_desc_profile OWNER TO glosis;

--
-- TOC entry 4498 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE property_desc_profile; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.property_desc_profile IS 'Descriptive properties for the Profile feature of interest';


--
-- TOC entry 4499 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN property_desc_profile.property_desc_profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.property_desc_profile.property_desc_profile_id IS 'Synthetic primary key.';


--
-- TOC entry 4500 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN property_desc_profile.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.property_desc_profile.uri IS 'URI to the corresponding code in a controled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this property';


--
-- TOC entry 230 (class 1259 OID 54021958)
-- Name: property_phys_chem; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.property_phys_chem (
    property_phys_chem_id text NOT NULL,
    uri text NOT NULL
);


ALTER TABLE core.property_phys_chem OWNER TO glosis;

--
-- TOC entry 4501 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE property_phys_chem; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.property_phys_chem IS 'Physio-chemical properties for the Element feature of interest';


--
-- TOC entry 4502 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN property_phys_chem.property_phys_chem_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.property_phys_chem.property_phys_chem_id IS 'Synthetic primary key.';


--
-- TOC entry 4503 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN property_phys_chem.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.property_phys_chem.uri IS 'URI to the corresponding code in a controled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this property';


--
-- TOC entry 231 (class 1259 OID 54021966)
-- Name: result_desc_element; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.result_desc_element (
    element_id integer NOT NULL,
    property_desc_element_id text NOT NULL,
    thesaurus_desc_element_id integer NOT NULL
);


ALTER TABLE core.result_desc_element OWNER TO glosis;

--
-- TOC entry 4504 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE result_desc_element; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.result_desc_element IS 'Descriptive results for the Element feature interest.';


--
-- TOC entry 4505 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN result_desc_element.element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_element.element_id IS 'Foreign key to the corresponding Element feature of interest.';


--
-- TOC entry 4506 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN result_desc_element.property_desc_element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_element.property_desc_element_id IS 'Foreign key to property_desc_element table.';


--
-- TOC entry 4507 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN result_desc_element.thesaurus_desc_element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_element.thesaurus_desc_element_id IS 'Foreign key to thesaurus_desc_element table.';


--
-- TOC entry 232 (class 1259 OID 54021969)
-- Name: result_desc_plot; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.result_desc_plot (
    plot_id integer NOT NULL,
    property_desc_plot_id text NOT NULL,
    thesaurus_desc_plot_id integer NOT NULL
);


ALTER TABLE core.result_desc_plot OWNER TO glosis;

--
-- TOC entry 4508 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE result_desc_plot; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.result_desc_plot IS 'Descriptive results for the Plot feature interest.';


--
-- TOC entry 4509 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN result_desc_plot.plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_plot.plot_id IS 'Foreign key to the corresponding Plot feature of interest.';


--
-- TOC entry 4510 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN result_desc_plot.property_desc_plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_plot.property_desc_plot_id IS 'Foreign key to property_desc_plot table.';


--
-- TOC entry 4511 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN result_desc_plot.thesaurus_desc_plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_plot.thesaurus_desc_plot_id IS 'Foreign key to thesaurus_desc_plot table.';


--
-- TOC entry 233 (class 1259 OID 54021972)
-- Name: result_desc_profile; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.result_desc_profile (
    profile_id integer NOT NULL,
    property_desc_profile_id text NOT NULL,
    thesaurus_desc_profile_id integer NOT NULL
);


ALTER TABLE core.result_desc_profile OWNER TO glosis;

--
-- TOC entry 4512 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE result_desc_profile; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.result_desc_profile IS 'Descriptive results for the Profile feature interest.';


--
-- TOC entry 4513 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN result_desc_profile.profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_profile.profile_id IS 'Foreign key to the corresponding Profile feature of interest.';


--
-- TOC entry 4514 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN result_desc_profile.property_desc_profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_profile.property_desc_profile_id IS 'Foreign key to property_desc_profile table.';


--
-- TOC entry 4515 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN result_desc_profile.thesaurus_desc_profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_profile.thesaurus_desc_profile_id IS 'Foreign key to thesaurus_desc_profile table.';


--
-- TOC entry 234 (class 1259 OID 54021978)
-- Name: result_desc_surface; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.result_desc_surface (
    surface_id integer NOT NULL,
    property_desc_plot_id text NOT NULL,
    thesaurus_desc_plot_id integer NOT NULL
);


ALTER TABLE core.result_desc_surface OWNER TO glosis;

--
-- TOC entry 4516 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE result_desc_surface; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.result_desc_surface IS 'Descriptive results for the Surface feature interest.';


--
-- TOC entry 4517 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN result_desc_surface.surface_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_surface.surface_id IS 'Foreign key to the corresponding Surface feature of interest.';


--
-- TOC entry 4518 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN result_desc_surface.property_desc_plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_surface.property_desc_plot_id IS 'Foreign key to property_desc_surface table.';


--
-- TOC entry 4519 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN result_desc_surface.thesaurus_desc_plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_desc_surface.thesaurus_desc_plot_id IS 'Foreign key to thesaurus_desc_surface table.';


--
-- TOC entry 235 (class 1259 OID 54021981)
-- Name: result_phys_chem; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.result_phys_chem (
    result_phys_chem_id integer NOT NULL,
    observation_phys_chem_id integer NOT NULL,
    specimen_id integer NOT NULL,
    individual_id integer,
    value real NOT NULL
);


ALTER TABLE core.result_phys_chem OWNER TO glosis;

--
-- TOC entry 4520 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE result_phys_chem; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.result_phys_chem IS 'Numerical results for the Specimen feature interest.';


--
-- TOC entry 4521 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN result_phys_chem.result_phys_chem_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_phys_chem.result_phys_chem_id IS 'Synthetic primary key.';


--
-- TOC entry 4522 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN result_phys_chem.observation_phys_chem_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_phys_chem.observation_phys_chem_id IS 'Foreign key to the corresponding numerical observation.';


--
-- TOC entry 4523 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN result_phys_chem.specimen_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_phys_chem.specimen_id IS 'Foreign key to the corresponding Specimen instance.';


--
-- TOC entry 4524 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN result_phys_chem.individual_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_phys_chem.individual_id IS 'Individual that is responsible for, or carried out, the process that produced this result.';


--
-- TOC entry 4525 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN result_phys_chem.value; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.result_phys_chem.value IS 'Numerical value resulting from applying the refered observation to the refered specimen.';


--
-- TOC entry 267 (class 1259 OID 54022879)
-- Name: result_phys_chem_specimen_result_phys_chem_specimen_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.result_phys_chem ALTER COLUMN result_phys_chem_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.result_phys_chem_specimen_result_phys_chem_specimen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 269 (class 1259 OID 54023246)
-- Name: result_spectrum; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.result_spectrum (
    result_spectrum_id integer NOT NULL,
    specimen_id integer NOT NULL,
    individual_id integer,
    spectrum jsonb
);


ALTER TABLE core.result_spectrum OWNER TO glosis;

--
-- TOC entry 268 (class 1259 OID 54023244)
-- Name: result_spectrum_result_spectrum_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.result_spectrum ALTER COLUMN result_spectrum_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.result_spectrum_result_spectrum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 236 (class 1259 OID 54021997)
-- Name: site; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.site (
    site_id integer NOT NULL,
    site_code text,
    typical_profile integer,
    "position" public.geometry(Point,4326),
    extent public.geometry(Polygon,4326),
    CONSTRAINT site_mandatory_geometry CHECK (((("position" IS NOT NULL) OR (extent IS NOT NULL)) AND (NOT (("position" IS NOT NULL) AND (extent IS NOT NULL)))))
);


ALTER TABLE core.site OWNER TO glosis;

--
-- TOC entry 4527 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE site; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.site IS 'Defined area which is subject to a soil quality investigation. Site is not a spatial feature of interest, but provides the link between the spatial features of interest (Plot) to the Project. The geometry can either be a location (point) or extent (polygon) but not both at the same time.';


--
-- TOC entry 4528 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN site.site_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.site.site_id IS 'Synthetic primary key.';


--
-- TOC entry 4529 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN site.site_code; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.site.site_code IS 'Natural key, can be null.';


--
-- TOC entry 4530 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN site.typical_profile; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.site.typical_profile IS 'Foreign key to a profile providing a typical characterisation of this site.';


--
-- TOC entry 4531 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN site."position"; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.site."position" IS 'Geodetic coordinates of the spatial position of the site. Note the uncertainty associated with the WGS84 datum ensemble.';


--
-- TOC entry 4532 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN site.extent; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.site.extent IS 'Site extent expressed with geodetic coordinates of the site. Note the uncertainty associated with the WGS84 datum ensemble.';


--
-- TOC entry 238 (class 1259 OID 54022007)
-- Name: site_site_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.site ALTER COLUMN site_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.site_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 239 (class 1259 OID 54022009)
-- Name: specimen; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.specimen (
    specimen_id integer NOT NULL,
    element_id integer NOT NULL,
    specimen_prep_process_id integer,
    organisation_id integer,
    code text
);


ALTER TABLE core.specimen OWNER TO glosis;

--
-- TOC entry 4533 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE specimen; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.specimen IS 'Soil Specimen is defined in ISO-28258 as: "a subtype of SF_Specimen. Soil Specimen may be taken in the Site, Plot, Profile, or ProfileElement including their subtypes." In this database Specimen is for now only associated to Plot for simplification.';


--
-- TOC entry 4534 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN specimen.specimen_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen.specimen_id IS 'Synthetic primary key.';


--
-- TOC entry 4535 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN specimen.element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen.element_id IS 'Foreign key to the associated soil Plot';


--
-- TOC entry 4536 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN specimen.specimen_prep_process_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen.specimen_prep_process_id IS 'Foreign key to the preparation process used on this soil Specimen.';


--
-- TOC entry 4537 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN specimen.organisation_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen.organisation_id IS 'Organisation that is responsible for, or carried out, the process that produced this result.';


--
-- TOC entry 4538 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN specimen.code; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen.code IS 'External code used to identify the soil Specimen (if used).';


--
-- TOC entry 240 (class 1259 OID 54022015)
-- Name: specimen_prep_process; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.specimen_prep_process (
    specimen_prep_process_id integer NOT NULL,
    specimen_transport_id integer,
    specimen_storage_id integer,
    definition text NOT NULL
);


ALTER TABLE core.specimen_prep_process OWNER TO glosis;

--
-- TOC entry 4539 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE specimen_prep_process; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.specimen_prep_process IS 'Describes the preparation process of a soil Specimen. Contains information that does not result from observation(s).';


--
-- TOC entry 4540 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN specimen_prep_process.specimen_prep_process_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_prep_process.specimen_prep_process_id IS 'Synthetic primary key.';


--
-- TOC entry 4541 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN specimen_prep_process.specimen_transport_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_prep_process.specimen_transport_id IS 'Foreign key for the corresponding mode of transport';


--
-- TOC entry 4542 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN specimen_prep_process.specimen_storage_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_prep_process.specimen_storage_id IS 'Foreign key for the corresponding mode of storage';


--
-- TOC entry 4543 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN specimen_prep_process.definition; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_prep_process.definition IS 'Further details necessary to define the preparation process.';


--
-- TOC entry 241 (class 1259 OID 54022021)
-- Name: specimen_prep_process_specimen_prep_process_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.specimen_prep_process ALTER COLUMN specimen_prep_process_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.specimen_prep_process_specimen_prep_process_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 242 (class 1259 OID 54022023)
-- Name: specimen_specimen_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.specimen ALTER COLUMN specimen_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.specimen_specimen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 243 (class 1259 OID 54022025)
-- Name: specimen_storage; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.specimen_storage (
    specimen_storage_id integer NOT NULL,
    label text NOT NULL,
    definition text
);


ALTER TABLE core.specimen_storage OWNER TO glosis;

--
-- TOC entry 4544 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE specimen_storage; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.specimen_storage IS 'Modes of storage of a soil Specimen, part of the Specimen preparation process.';


--
-- TOC entry 4545 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN specimen_storage.specimen_storage_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_storage.specimen_storage_id IS 'Synthetic primary key.';


--
-- TOC entry 4546 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN specimen_storage.label; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_storage.label IS 'Short label for the storage mode.';


--
-- TOC entry 4547 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN specimen_storage.definition; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_storage.definition IS 'Long definition providing all the necessary details for the storage mode.';


--
-- TOC entry 244 (class 1259 OID 54022031)
-- Name: specimen_storage_specimen_storage_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.specimen_storage ALTER COLUMN specimen_storage_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.specimen_storage_specimen_storage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 245 (class 1259 OID 54022033)
-- Name: specimen_transport; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.specimen_transport (
    specimen_transport_id integer NOT NULL,
    label text NOT NULL,
    definition text
);


ALTER TABLE core.specimen_transport OWNER TO glosis;

--
-- TOC entry 4548 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE specimen_transport; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.specimen_transport IS 'Modes of transport of a soil Specimen, part of the Specimen preparation process.';


--
-- TOC entry 4549 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN specimen_transport.specimen_transport_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_transport.specimen_transport_id IS 'Synthetic primary key.';


--
-- TOC entry 4550 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN specimen_transport.label; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_transport.label IS 'Short label for the transport mode.';


--
-- TOC entry 4551 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN specimen_transport.definition; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.specimen_transport.definition IS 'Long definition providing all the necessary details for the transport mode.';


--
-- TOC entry 246 (class 1259 OID 54022039)
-- Name: specimen_transport_specimen_transport_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.specimen_transport ALTER COLUMN specimen_transport_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.specimen_transport_specimen_transport_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 247 (class 1259 OID 54022041)
-- Name: surface; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.surface (
    surface_id integer NOT NULL,
    super_surface_id integer,
    site_id integer NOT NULL,
    shape public.geometry(Polygon,4326),
    time_stamp date
);


ALTER TABLE core.surface OWNER TO glosis;

--
-- TOC entry 4552 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE surface; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.surface IS 'Surface is a subtype of Plot with a shape geometry. Surfaces may be located within other
surfaces.';


--
-- TOC entry 4553 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN surface.surface_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.surface.surface_id IS 'Synthetic primary key.';


--
-- TOC entry 4554 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN surface.super_surface_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.surface.super_surface_id IS 'Hierarchical relation between surfaces.';


--
-- TOC entry 4555 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN surface.site_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.surface.site_id IS 'Foreign key to Site table';


--
-- TOC entry 4556 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN surface.shape; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.surface.shape IS 'Site extent expressed with geodetic coordinates of the site. Note the uncertainty associated with the WGS84 datum ensemble.';


--
-- TOC entry 4557 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN surface.time_stamp; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.surface.time_stamp IS 'Time stamp of the plot, if known. Property re-used from GloSIS.';


--
-- TOC entry 248 (class 1259 OID 54022047)
-- Name: surface_individual; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.surface_individual (
    surface_id integer NOT NULL,
    individual_id integer NOT NULL
);


ALTER TABLE core.surface_individual OWNER TO glosis;

--
-- TOC entry 4558 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE surface_individual; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.surface_individual IS 'Identifies the individual(s) responsible for surveying a surface';


--
-- TOC entry 4559 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN surface_individual.surface_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.surface_individual.surface_id IS 'Foreign key to the surface table, identifies the surface surveyed';


--
-- TOC entry 4560 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN surface_individual.individual_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.surface_individual.individual_id IS 'Foreign key to the individual table, indicates the individual responsible for surveying the surface.';


--
-- TOC entry 249 (class 1259 OID 54022050)
-- Name: surface_surface_id_seq; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.surface ALTER COLUMN surface_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.surface_surface_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 250 (class 1259 OID 54022052)
-- Name: thesaurus_desc_element; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.thesaurus_desc_element (
    thesaurus_desc_element_id integer NOT NULL,
    label text NOT NULL,
    uri text NOT NULL
);


ALTER TABLE core.thesaurus_desc_element OWNER TO glosis;

--
-- TOC entry 4561 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE thesaurus_desc_element; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.thesaurus_desc_element IS 'Vocabularies for the descriptive properties associated with the Element feature of interest. Corresponds to all GloSIS code-lists associated with the Horizon and Layer.';


--
-- TOC entry 4562 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN thesaurus_desc_element.thesaurus_desc_element_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_element.thesaurus_desc_element_id IS 'Synthetic primary key.';


--
-- TOC entry 4563 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN thesaurus_desc_element.label; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_element.label IS 'Short label for this term';


--
-- TOC entry 4564 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN thesaurus_desc_element.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_element.uri IS 'URI to the corresponding code in a controled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this term';


--
-- TOC entry 251 (class 1259 OID 54022058)
-- Name: thesaurus_desc_element_thesaurus_desc_element_id_seq1; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.thesaurus_desc_element ALTER COLUMN thesaurus_desc_element_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.thesaurus_desc_element_thesaurus_desc_element_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 252 (class 1259 OID 54022060)
-- Name: thesaurus_desc_plot; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.thesaurus_desc_plot (
    thesaurus_desc_plot_id integer NOT NULL,
    label text NOT NULL,
    uri text NOT NULL
);


ALTER TABLE core.thesaurus_desc_plot OWNER TO glosis;

--
-- TOC entry 4565 (class 0 OID 0)
-- Dependencies: 252
-- Name: TABLE thesaurus_desc_plot; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.thesaurus_desc_plot IS 'Descriptive properties for the Plot feature of interest';


--
-- TOC entry 4566 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN thesaurus_desc_plot.thesaurus_desc_plot_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_plot.thesaurus_desc_plot_id IS 'Synthetic primary key.';


--
-- TOC entry 4567 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN thesaurus_desc_plot.label; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_plot.label IS 'Short label for this term';


--
-- TOC entry 4568 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN thesaurus_desc_plot.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_plot.uri IS 'URI to the corresponding code in a controled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this term';


--
-- TOC entry 253 (class 1259 OID 54022066)
-- Name: thesaurus_desc_plot_thesaurus_desc_plot_id_seq1; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.thesaurus_desc_plot ALTER COLUMN thesaurus_desc_plot_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.thesaurus_desc_plot_thesaurus_desc_plot_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 254 (class 1259 OID 54022068)
-- Name: thesaurus_desc_profile; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.thesaurus_desc_profile (
    thesaurus_desc_profile_id integer NOT NULL,
    label text NOT NULL,
    uri text NOT NULL
);


ALTER TABLE core.thesaurus_desc_profile OWNER TO glosis;

--
-- TOC entry 4569 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE thesaurus_desc_profile; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.thesaurus_desc_profile IS 'Vocabularies for the descriptive properties associated with the Profile feature of interest. Contains the GloSIS code-lists for Profile.';


--
-- TOC entry 4570 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN thesaurus_desc_profile.thesaurus_desc_profile_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_profile.thesaurus_desc_profile_id IS 'Synthetic primary key.';


--
-- TOC entry 4571 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN thesaurus_desc_profile.label; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_profile.label IS 'Short label for this term';


--
-- TOC entry 4572 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN thesaurus_desc_profile.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.thesaurus_desc_profile.uri IS 'URI to the corresponding code in a controled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this term';


--
-- TOC entry 255 (class 1259 OID 54022074)
-- Name: thesaurus_desc_profile_thesaurus_desc_profile_id_seq1; Type: SEQUENCE; Schema: core; Owner: glosis
--

ALTER TABLE core.thesaurus_desc_profile ALTER COLUMN thesaurus_desc_profile_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME core.thesaurus_desc_profile_thesaurus_desc_profile_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 256 (class 1259 OID 54022092)
-- Name: unit_of_measure; Type: TABLE; Schema: core; Owner: glosis
--

CREATE TABLE core.unit_of_measure (
    unit_of_measure_id text NOT NULL,
    label text NOT NULL,
    uri text NOT NULL
);


ALTER TABLE core.unit_of_measure OWNER TO glosis;

--
-- TOC entry 4573 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE unit_of_measure; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TABLE core.unit_of_measure IS 'Unit of measure';


--
-- TOC entry 4574 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN unit_of_measure.unit_of_measure_id; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.unit_of_measure.unit_of_measure_id IS 'Synthetic primary key.';


--
-- TOC entry 4575 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN unit_of_measure.label; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.unit_of_measure.label IS 'Short label for this unit of measure';


--
-- TOC entry 4576 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN unit_of_measure.uri; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON COLUMN core.unit_of_measure.uri IS 'URI to the corresponding unit of measuree in a controled vocabulary (e.g. GloSIS). Follow this URI for the full definition and semantics of this unit of measure';


--
-- TOC entry 257 (class 1259 OID 54022100)
-- Name: address; Type: TABLE; Schema: metadata; Owner: glosis
--

CREATE TABLE metadata.address (
    address_id integer NOT NULL,
    street_address text NOT NULL,
    postal_code text NOT NULL,
    locality text NOT NULL,
    country text NOT NULL
);


ALTER TABLE metadata.address OWNER TO glosis;

--
-- TOC entry 4577 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE address; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON TABLE metadata.address IS 'Equivalent to the Address class in VCard, defined as delivery address for the associated object.';


--
-- TOC entry 4578 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN address.address_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.address.address_id IS 'Synthetic primary key.';


--
-- TOC entry 4579 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN address.street_address; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.address.street_address IS 'Street address data property in VCard, including house number, e.g. "Generaal Foulkesweg 108".';


--
-- TOC entry 4580 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN address.postal_code; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.address.postal_code IS 'Equivalent to the postal-code data property in VCard, e.g. "6701 PB".';


--
-- TOC entry 4581 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN address.locality; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.address.locality IS 'Locality data property in VCard, referring to a village, town, city, etc, e.g. "Wageningen".';


--
-- TOC entry 4582 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN address.country; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.address.country IS 'Equivalent to the country data property in VCard, e.g. "The Netherlands".';


--
-- TOC entry 258 (class 1259 OID 54022106)
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: metadata; Owner: glosis
--

ALTER TABLE metadata.address ALTER COLUMN address_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME metadata.address_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 259 (class 1259 OID 54022108)
-- Name: individual; Type: TABLE; Schema: metadata; Owner: glosis
--

CREATE TABLE metadata.individual (
    individual_id integer NOT NULL,
    address_id integer,
    name text NOT NULL,
    honorific_title text,
    email text,
    telephone text,
    url text
);


ALTER TABLE metadata.individual OWNER TO glosis;

--
-- TOC entry 4583 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE individual; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON TABLE metadata.individual IS 'Equivalent to the Individual class in VCard, defined as a single person or entity.';


--
-- TOC entry 4584 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN individual.individual_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.individual.individual_id IS 'Synthetic primary key.';


--
-- TOC entry 4585 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN individual.address_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.individual.address_id IS 'Foreign key to address associated with the individual.';


--
-- TOC entry 4586 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN individual.name; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.individual.name IS 'Name of the individual, encompasses the data properties additional-name, given-name and family-name in VCard.';


--
-- TOC entry 4587 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN individual.honorific_title; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.individual.honorific_title IS 'Academic title or honorific rank associated to the individual. Encompasses the data properties honorific-prefix, honorific-suffix and title in VCard.';


--
-- TOC entry 4588 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN individual.email; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.individual.email IS 'Electronic mail address of the individual.';


--
-- TOC entry 4589 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN individual.telephone; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.individual.telephone IS 'Equivalent to the telephone data property in VCard, e.g. "0031 961000789".';


--
-- TOC entry 4590 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN individual.url; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.individual.url IS 'Locator to a web page associated with the individual.';


--
-- TOC entry 260 (class 1259 OID 54022114)
-- Name: individual_individual_id_seq; Type: SEQUENCE; Schema: metadata; Owner: glosis
--

ALTER TABLE metadata.individual ALTER COLUMN individual_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME metadata.individual_individual_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 261 (class 1259 OID 54022116)
-- Name: organisation; Type: TABLE; Schema: metadata; Owner: glosis
--

CREATE TABLE metadata.organisation (
    organisation_id integer NOT NULL,
    parent_id integer,
    address_id integer,
    name text NOT NULL,
    email text,
    telephone text,
    url text
);


ALTER TABLE metadata.organisation OWNER TO glosis;

--
-- TOC entry 4591 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE organisation; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON TABLE metadata.organisation IS 'Equivalent to the Organisation class in VCard, defined as a single entity, might also represent a business or government, a department or division within a business or government, a club, an association, or the like.';


--
-- TOC entry 4592 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN organisation.organisation_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation.organisation_id IS 'Synthetic primary key.';


--
-- TOC entry 4593 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN organisation.parent_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation.parent_id IS 'Foreign key to the parent organisation, in case of a department or division of a larger organisation.';


--
-- TOC entry 4594 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN organisation.address_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation.address_id IS 'Foreign key to address associated with the organisation.';


--
-- TOC entry 4595 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN organisation.name; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation.name IS 'Name of the organisation.';


--
-- TOC entry 4596 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN organisation.email; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation.email IS 'Electronic mail address of the organisation.';


--
-- TOC entry 4597 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN organisation.telephone; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation.telephone IS 'Equivalent to the telephone data property in VCard, e.g. "0031 961000787".';


--
-- TOC entry 4598 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN organisation.url; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation.url IS 'Locator to a web page associated with the organisation.';


--
-- TOC entry 262 (class 1259 OID 54022122)
-- Name: organisation_individual; Type: TABLE; Schema: metadata; Owner: glosis
--

CREATE TABLE metadata.organisation_individual (
    organisation_id integer NOT NULL,
    organisation_unit_id integer,
    individual_id integer NOT NULL,
    role text
);


ALTER TABLE metadata.organisation_individual OWNER TO glosis;

--
-- TOC entry 4599 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE organisation_individual; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON TABLE metadata.organisation_individual IS 'Relation between Individual and Organisation. Captures the object properties hasOrganisationName, org and organisation-name in VCard. In most cases means that the individual works at the organisation in the unit specified.';


--
-- TOC entry 4600 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN organisation_individual.organisation_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_individual.organisation_id IS 'Foreign key to the related organisation.';


--
-- TOC entry 4601 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN organisation_individual.organisation_unit_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_individual.organisation_unit_id IS 'Foreign key to the organisational unit associating the individual with the organisation.';


--
-- TOC entry 4602 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN organisation_individual.individual_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_individual.individual_id IS 'Foreign key to the related individual.';


--
-- TOC entry 4603 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN organisation_individual.role; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_individual.role IS 'Role of the individual within the organisation and respective organisational unit, e.g. "director", "secretary".';


--
-- TOC entry 263 (class 1259 OID 54022128)
-- Name: organisation_organisation_id_seq; Type: SEQUENCE; Schema: metadata; Owner: glosis
--

ALTER TABLE metadata.organisation ALTER COLUMN organisation_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME metadata.organisation_organisation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 224 (class 1259 OID 54021907)
-- Name: organisation_project; Type: TABLE; Schema: metadata; Owner: glosis
--

CREATE TABLE metadata.organisation_project (
    organisation_id integer NOT NULL,
    project_id integer NOT NULL
);


ALTER TABLE metadata.organisation_project OWNER TO glosis;

--
-- TOC entry 4604 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN organisation_project.organisation_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_project.organisation_id IS 'Foreign key to Organisation table.';


--
-- TOC entry 4605 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN organisation_project.project_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_project.project_id IS 'Foreign key to Project table.';


--
-- TOC entry 264 (class 1259 OID 54022130)
-- Name: organisation_unit; Type: TABLE; Schema: metadata; Owner: glosis
--

CREATE TABLE metadata.organisation_unit (
    organisation_unit_id integer NOT NULL,
    organisation_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE metadata.organisation_unit OWNER TO glosis;

--
-- TOC entry 4606 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE organisation_unit; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON TABLE metadata.organisation_unit IS 'Captures the data property organisation-unit and object property hasOrganisationUnit in VCard. Defines the internal structure of the organisation, apart from the departmental hierarchy.';


--
-- TOC entry 4607 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN organisation_unit.organisation_unit_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_unit.organisation_unit_id IS 'Synthetic primary key.';


--
-- TOC entry 4608 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN organisation_unit.organisation_id; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_unit.organisation_id IS 'Foreign key to the enclosing organisation, in case of a department or division of a larger organisation.';


--
-- TOC entry 4609 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN organisation_unit.name; Type: COMMENT; Schema: metadata; Owner: glosis
--

COMMENT ON COLUMN metadata.organisation_unit.name IS 'Name of the organisation unit.';


--
-- TOC entry 265 (class 1259 OID 54022136)
-- Name: organisation_unit_organisation_unit_id_seq; Type: SEQUENCE; Schema: metadata; Owner: glosis
--

ALTER TABLE metadata.organisation_unit ALTER COLUMN organisation_unit_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME metadata.organisation_unit_organisation_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 4360 (class 0 OID 54021823)
-- Dependencies: 210
-- Data for Name: element; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.element (element_id, profile_id, order_element, upper_depth, lower_depth, type) FROM stdin;
\.


--
-- TOC entry 4362 (class 0 OID 54021831)
-- Dependencies: 212
-- Data for Name: observation_desc_element; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.observation_desc_element (procedure_desc_id, property_desc_element_id, thesaurus_desc_element_id) FROM stdin;
FAO GfSD 2006	biologicalAbundanceProperty	1
FAO GfSD 2006	biologicalAbundanceProperty	2
FAO GfSD 2006	biologicalAbundanceProperty	3
FAO GfSD 2006	biologicalAbundanceProperty	4
FAO GfSD 2006	biologicalFeaturesProperty	5
FAO GfSD 2006	biologicalFeaturesProperty	6
FAO GfSD 2006	biologicalFeaturesProperty	7
FAO GfSD 2006	biologicalFeaturesProperty	8
FAO GfSD 2006	biologicalFeaturesProperty	9
FAO GfSD 2006	biologicalFeaturesProperty	10
FAO GfSD 2006	biologicalFeaturesProperty	11
FAO GfSD 2006	biologicalFeaturesProperty	12
FAO GfSD 2006	biologicalFeaturesProperty	13
FAO GfSD 2006	boundaryDistinctnessProperty	17
FAO GfSD 2006	boundaryDistinctnessProperty	18
FAO GfSD 2006	boundaryDistinctnessProperty	19
FAO GfSD 2006	boundaryDistinctnessProperty	20
FAO GfSD 2006	boundaryTopographyProperty	21
FAO GfSD 2006	boundaryTopographyProperty	22
FAO GfSD 2006	boundaryTopographyProperty	23
FAO GfSD 2006	boundaryTopographyProperty	24
FAO GfSD 2006	bulkDensityMineralProperty	25
FAO GfSD 2006	bulkDensityMineralProperty	26
FAO GfSD 2006	bulkDensityMineralProperty	27
FAO GfSD 2006	bulkDensityMineralProperty	28
FAO GfSD 2006	bulkDensityMineralProperty	29
FAO GfSD 2006	bulkDensityPeatProperty	30
FAO GfSD 2006	bulkDensityPeatProperty	31
FAO GfSD 2006	bulkDensityPeatProperty	32
FAO GfSD 2006	bulkDensityPeatProperty	33
FAO GfSD 2006	bulkDensityPeatProperty	34
FAO GfSD 2006	carbonatesContentProperty	35
FAO GfSD 2006	carbonatesContentProperty	36
FAO GfSD 2006	carbonatesContentProperty	37
FAO GfSD 2006	carbonatesContentProperty	38
FAO GfSD 2006	carbonatesContentProperty	39
FAO GfSD 2006	carbonatesFormsProperty	40
FAO GfSD 2006	carbonatesFormsProperty	41
FAO GfSD 2006	carbonatesFormsProperty	42
FAO GfSD 2006	carbonatesFormsProperty	43
FAO GfSD 2006	carbonatesFormsProperty	44
FAO GfSD 2006	carbonatesFormsProperty	45
FAO GfSD 2006	carbonatesFormsProperty	46
FAO GfSD 2006	cementationContinuityProperty	47
FAO GfSD 2006	cementationContinuityProperty	48
FAO GfSD 2006	cementationContinuityProperty	49
FAO GfSD 2006	cementationDegreeProperty	50
FAO GfSD 2006	cementationDegreeProperty	51
FAO GfSD 2006	cementationDegreeProperty	52
FAO GfSD 2006	cementationDegreeProperty	53
FAO GfSD 2006	cementationDegreeProperty	54
FAO GfSD 2006	cementationDegreeProperty	55
FAO GfSD 2006	cementationFabricProperty	56
FAO GfSD 2006	cementationFabricProperty	57
FAO GfSD 2006	cementationFabricProperty	58
FAO GfSD 2006	cementationFabricProperty	59
FAO GfSD 2006	cementationNatureProperty	60
FAO GfSD 2006	cementationNatureProperty	61
FAO GfSD 2006	cementationNatureProperty	62
FAO GfSD 2006	cementationNatureProperty	63
FAO GfSD 2006	cementationNatureProperty	64
FAO GfSD 2006	cementationNatureProperty	65
FAO GfSD 2006	cementationNatureProperty	66
FAO GfSD 2006	cementationNatureProperty	67
FAO GfSD 2006	cementationNatureProperty	68
FAO GfSD 2006	cementationNatureProperty	69
FAO GfSD 2006	cementationNatureProperty	70
FAO GfSD 2006	cementationNatureProperty	71
FAO GfSD 2006	cementationNatureProperty	72
FAO GfSD 2006	coatingAbundanceProperty	73
FAO GfSD 2006	coatingAbundanceProperty	74
FAO GfSD 2006	coatingAbundanceProperty	75
FAO GfSD 2006	coatingAbundanceProperty	76
FAO GfSD 2006	coatingAbundanceProperty	77
FAO GfSD 2006	coatingAbundanceProperty	78
FAO GfSD 2006	coatingAbundanceProperty	79
FAO GfSD 2006	coatingContrastProperty	80
FAO GfSD 2006	coatingContrastProperty	81
FAO GfSD 2006	coatingContrastProperty	82
FAO GfSD 2006	coatingFormProperty	83
FAO GfSD 2006	coatingFormProperty	84
FAO GfSD 2006	coatingFormProperty	85
FAO GfSD 2006	coatingFormProperty	86
FAO GfSD 2006	coatingFormProperty	87
FAO GfSD 2006	coatingFormProperty	88
FAO GfSD 2006	coatingLocationProperty	89
FAO GfSD 2006	coatingLocationProperty	90
FAO GfSD 2006	coatingLocationProperty	91
FAO GfSD 2006	coatingLocationProperty	92
FAO GfSD 2006	coatingLocationProperty	93
FAO GfSD 2006	coatingLocationProperty	94
FAO GfSD 2006	coatingLocationProperty	95
FAO GfSD 2006	coatingLocationProperty	96
FAO GfSD 2006	coatingNatureProperty	97
FAO GfSD 2006	coatingNatureProperty	98
FAO GfSD 2006	coatingNatureProperty	99
FAO GfSD 2006	coatingNatureProperty	100
FAO GfSD 2006	coatingNatureProperty	101
FAO GfSD 2006	coatingNatureProperty	102
FAO GfSD 2006	coatingNatureProperty	103
FAO GfSD 2006	coatingNatureProperty	104
FAO GfSD 2006	coatingNatureProperty	105
FAO GfSD 2006	coatingNatureProperty	106
FAO GfSD 2006	coatingNatureProperty	107
FAO GfSD 2006	coatingNatureProperty	108
FAO GfSD 2006	coatingNatureProperty	109
FAO GfSD 2006	coatingNatureProperty	110
FAO GfSD 2006	coatingNatureProperty	111
FAO GfSD 2006	coatingNatureProperty	112
FAO GfSD 2006	coatingNatureProperty	113
FAO GfSD 2006	coatingNatureProperty	114
FAO GfSD 2006	consistenceDryProperty	115
FAO GfSD 2006	consistenceDryProperty	116
FAO GfSD 2006	consistenceDryProperty	117
FAO GfSD 2006	consistenceDryProperty	118
FAO GfSD 2006	consistenceDryProperty	119
FAO GfSD 2006	consistenceDryProperty	120
FAO GfSD 2006	consistenceDryProperty	121
FAO GfSD 2006	consistenceDryProperty	122
FAO GfSD 2006	consistenceDryProperty	123
FAO GfSD 2006	consistenceMoistProperty	124
FAO GfSD 2006	consistenceMoistProperty	125
FAO GfSD 2006	consistenceMoistProperty	126
FAO GfSD 2006	consistenceMoistProperty	127
FAO GfSD 2006	consistenceMoistProperty	128
FAO GfSD 2006	consistenceMoistProperty	129
FAO GfSD 2006	gypsumContentProperty	133
FAO GfSD 2006	gypsumContentProperty	134
FAO GfSD 2006	gypsumContentProperty	135
FAO GfSD 2006	gypsumContentProperty	136
FAO GfSD 2006	gypsumContentProperty	137
FAO GfSD 2006	gypsumFormsProperty	138
FAO GfSD 2006	gypsumFormsProperty	139
FAO GfSD 2006	gypsumFormsProperty	140
FAO GfSD 2006	gypsumFormsProperty	141
FAO GfSD 2006	mineralConcColourProperty	142
FAO GfSD 2006	mineralConcColourProperty	143
FAO GfSD 2006	mineralConcColourProperty	144
FAO GfSD 2006	mineralConcColourProperty	145
FAO GfSD 2006	mineralConcColourProperty	146
FAO GfSD 2006	mineralConcColourProperty	147
FAO GfSD 2006	porosityClassProperty	244
FAO GfSD 2006	mineralConcColourProperty	148
FAO GfSD 2006	mineralConcColourProperty	149
FAO GfSD 2006	mineralConcColourProperty	150
FAO GfSD 2006	mineralConcColourProperty	151
FAO GfSD 2006	mineralConcColourProperty	152
FAO GfSD 2006	mineralConcColourProperty	153
FAO GfSD 2006	mineralConcColourProperty	154
FAO GfSD 2006	mineralConcColourProperty	155
FAO GfSD 2006	mineralConcColourProperty	156
FAO GfSD 2006	mineralConcColourProperty	157
FAO GfSD 2006	mineralConcColourProperty	158
FAO GfSD 2006	mineralConcHardnessProperty	159
FAO GfSD 2006	mineralConcHardnessProperty	160
FAO GfSD 2006	mineralConcHardnessProperty	161
FAO GfSD 2006	mineralConcKindProperty	162
FAO GfSD 2006	mineralConcKindProperty	163
FAO GfSD 2006	mineralConcKindProperty	164
FAO GfSD 2006	mineralConcKindProperty	165
FAO GfSD 2006	mineralConcKindProperty	166
FAO GfSD 2006	mineralConcKindProperty	167
FAO GfSD 2006	mineralConcKindProperty	168
FAO GfSD 2006	mineralConcKindProperty	169
FAO GfSD 2006	mineralConcKindProperty	170
FAO GfSD 2006	mineralConcNatureProperty	171
FAO GfSD 2006	mineralConcNatureProperty	172
FAO GfSD 2006	mineralConcNatureProperty	173
FAO GfSD 2006	mineralConcNatureProperty	174
FAO GfSD 2006	mineralConcNatureProperty	175
FAO GfSD 2006	mineralConcNatureProperty	176
FAO GfSD 2006	mineralConcNatureProperty	177
FAO GfSD 2006	mineralConcNatureProperty	178
FAO GfSD 2006	mineralConcNatureProperty	179
FAO GfSD 2006	mineralConcNatureProperty	180
FAO GfSD 2006	mineralConcNatureProperty	181
FAO GfSD 2006	mineralConcNatureProperty	182
FAO GfSD 2006	mineralConcNatureProperty	183
FAO GfSD 2006	mineralConcNatureProperty	184
FAO GfSD 2006	mineralConcShapeProperty	185
FAO GfSD 2006	mineralConcShapeProperty	186
FAO GfSD 2006	mineralConcShapeProperty	187
FAO GfSD 2006	mineralConcShapeProperty	188
FAO GfSD 2006	mineralConcShapeProperty	189
FAO GfSD 2006	mineralConcSizeeProperty	190
FAO GfSD 2006	mineralConcSizeeProperty	191
FAO GfSD 2006	mineralConcSizeeProperty	192
FAO GfSD 2006	mineralConcSizeeProperty	193
FAO GfSD 2006	mineralConcVolumeProperty	194
FAO GfSD 2006	mineralConcVolumeProperty	195
FAO GfSD 2006	mineralConcVolumeProperty	196
FAO GfSD 2006	mineralConcVolumeProperty	197
FAO GfSD 2006	mineralConcVolumeProperty	198
FAO GfSD 2006	mineralConcVolumeProperty	199
FAO GfSD 2006	mineralConcVolumeProperty	200
FAO GfSD 2006	mineralFragmentsProperty	201
FAO GfSD 2006	mineralFragmentsProperty	202
FAO GfSD 2006	mineralFragmentsProperty	203
FAO GfSD 2006	mottlesAbundanceProperty	204
FAO GfSD 2006	mottlesAbundanceProperty	205
FAO GfSD 2006	mottlesAbundanceProperty	206
FAO GfSD 2006	mottlesAbundanceProperty	207
FAO GfSD 2006	mottlesAbundanceProperty	208
FAO GfSD 2006	mottlesAbundanceProperty	209
FAO GfSD 2006	mottlesBoundaryClassificationProperty	14
FAO GfSD 2006	mottlesBoundaryClassificationProperty	15
FAO GfSD 2006	mottlesBoundaryClassificationProperty	16
FAO GfSD 2006	mottlesContrastProperty	130
FAO GfSD 2006	mottlesContrastProperty	131
FAO GfSD 2006	mottlesContrastProperty	132
FAO GfSD 2006	mottlesSizeProperty	210
FAO GfSD 2006	mottlesSizeProperty	211
FAO GfSD 2006	mottlesSizeProperty	212
FAO GfSD 2006	mottlesSizeProperty	213
FAO GfSD 2006	peatDecompostionProperty	214
FAO GfSD 2006	peatDecompostionProperty	215
FAO GfSD 2006	peatDecompostionProperty	216
FAO GfSD 2006	peatDecompostionProperty	217
FAO GfSD 2006	peatDecompostionProperty	218
FAO GfSD 2006	peatDecompostionProperty	219
FAO GfSD 2006	peatDecompostionProperty	220
FAO GfSD 2006	peatDecompostionProperty	221
FAO GfSD 2006	peatDecompostionProperty	222
FAO GfSD 2006	peatDrainageProperty	223
FAO GfSD 2006	peatDrainageProperty	224
FAO GfSD 2006	peatDrainageProperty	225
FAO GfSD 2006	peatDrainageProperty	226
FAO GfSD 2006	peatVolumeProperty	227
FAO GfSD 2006	peatVolumeProperty	228
FAO GfSD 2006	peatVolumeProperty	229
FAO GfSD 2006	peatVolumeProperty	230
FAO GfSD 2006	peatVolumeProperty	231
FAO GfSD 2006	plasticityProperty	232
FAO GfSD 2006	plasticityProperty	233
FAO GfSD 2006	plasticityProperty	234
FAO GfSD 2006	plasticityProperty	235
FAO GfSD 2006	plasticityProperty	236
FAO GfSD 2006	plasticityProperty	237
FAO GfSD 2006	poresAbundanceProperty	238
FAO GfSD 2006	poresAbundanceProperty	239
FAO GfSD 2006	poresAbundanceProperty	240
FAO GfSD 2006	poresAbundanceProperty	241
FAO GfSD 2006	poresAbundanceProperty	242
FAO GfSD 2006	poresSizeProperty	291
FAO GfSD 2006	poresSizeProperty	292
FAO GfSD 2006	poresSizeProperty	293
FAO GfSD 2006	poresSizeProperty	294
FAO GfSD 2006	poresSizeProperty	295
FAO GfSD 2006	poresSizeProperty	296
FAO GfSD 2006	poresSizeProperty	297
FAO GfSD 2006	poresSizeProperty	298
FAO GfSD 2006	porosityClassProperty	243
FAO GfSD 2006	porosityClassProperty	245
FAO GfSD 2006	porosityClassProperty	246
FAO GfSD 2006	porosityClassProperty	247
FAO GfSD 2006	rootsAbundanceProperty	248
FAO GfSD 2006	rootsAbundanceProperty	249
FAO GfSD 2006	rootsAbundanceProperty	250
FAO GfSD 2006	rootsAbundanceProperty	251
FAO GfSD 2006	rootsAbundanceProperty	252
FAO GfSD 2006	saltContentProperty	253
FAO GfSD 2006	saltContentProperty	254
FAO GfSD 2006	saltContentProperty	255
FAO GfSD 2006	saltContentProperty	256
FAO GfSD 2006	saltContentProperty	257
FAO GfSD 2006	saltContentProperty	258
FAO GfSD 2006	sandyTextureProperty	259
FAO GfSD 2006	sandyTextureProperty	260
FAO GfSD 2006	sandyTextureProperty	261
FAO GfSD 2006	sandyTextureProperty	262
FAO GfSD 2006	sandyTextureProperty	263
FAO GfSD 2006	sandyTextureProperty	264
FAO GfSD 2006	sandyTextureProperty	265
FAO GfSD 2006	sandyTextureProperty	266
FAO GfSD 2006	sandyTextureProperty	267
FAO GfSD 2006	sandyTextureProperty	268
FAO GfSD 2006	stickinessProperty	269
FAO GfSD 2006	stickinessProperty	270
FAO GfSD 2006	stickinessProperty	271
FAO GfSD 2006	stickinessProperty	272
FAO GfSD 2006	stickinessProperty	273
FAO GfSD 2006	stickinessProperty	274
FAO GfSD 2006	structureGradeProperty	275
FAO GfSD 2006	structureGradeProperty	276
FAO GfSD 2006	structureGradeProperty	277
FAO GfSD 2006	structureGradeProperty	278
FAO GfSD 2006	structureGradeProperty	279
FAO GfSD 2006	structureSizeProperty	280
FAO GfSD 2006	structureSizeProperty	281
FAO GfSD 2006	structureSizeProperty	282
FAO GfSD 2006	structureSizeProperty	283
FAO GfSD 2006	structureSizeProperty	284
FAO GfSD 2006	structureSizeProperty	285
FAO GfSD 2006	VoidsClassificationProperty	286
FAO GfSD 2006	VoidsClassificationProperty	287
FAO GfSD 2006	VoidsClassificationProperty	288
FAO GfSD 2006	VoidsClassificationProperty	289
FAO GfSD 2006	VoidsClassificationProperty	290
FAO GfSD 2006	voidsDiameterProperty	291
FAO GfSD 2006	voidsDiameterProperty	292
FAO GfSD 2006	voidsDiameterProperty	293
FAO GfSD 2006	voidsDiameterProperty	294
FAO GfSD 2006	voidsDiameterProperty	295
FAO GfSD 2006	voidsDiameterProperty	296
FAO GfSD 2006	voidsDiameterProperty	297
FAO GfSD 2006	voidsDiameterProperty	298
FAO GfSD 2006	cracksDepthProperty	299
FAO GfSD 2006	cracksDepthProperty	300
FAO GfSD 2006	cracksDepthProperty	301
FAO GfSD 2006	cracksDepthProperty	302
FAO GfSD 2006	cracksDistanceProperty	303
FAO GfSD 2006	cracksDistanceProperty	304
FAO GfSD 2006	cracksDistanceProperty	305
FAO GfSD 2006	cracksDistanceProperty	306
FAO GfSD 2006	cracksDistanceProperty	307
FAO GfSD 2006	cracksWidthProperty	308
FAO GfSD 2006	cracksWidthProperty	309
FAO GfSD 2006	cracksWidthProperty	310
FAO GfSD 2006	cracksWidthProperty	311
FAO GfSD 2006	cracksWidthProperty	312
FAO GfSD 2006	fragmentCoverProperty	313
FAO GfSD 2006	fragmentCoverProperty	314
FAO GfSD 2006	fragmentCoverProperty	315
FAO GfSD 2006	fragmentCoverProperty	316
FAO GfSD 2006	fragmentCoverProperty	317
FAO GfSD 2006	fragmentCoverProperty	318
FAO GfSD 2006	fragmentCoverProperty	319
FAO GfSD 2006	fragmentSizeProperty	320
FAO GfSD 2006	fragmentSizeProperty	321
FAO GfSD 2006	fragmentSizeProperty	322
FAO GfSD 2006	fragmentSizeProperty	323
FAO GfSD 2006	fragmentSizeProperty	324
FAO GfSD 2006	fragmentSizeProperty	325
FAO GfSD 2006	rockAbundanceProperty	326
FAO GfSD 2006	rockAbundanceProperty	327
FAO GfSD 2006	rockAbundanceProperty	328
FAO GfSD 2006	rockAbundanceProperty	329
FAO GfSD 2006	rockAbundanceProperty	330
FAO GfSD 2006	rockAbundanceProperty	331
FAO GfSD 2006	rockAbundanceProperty	332
FAO GfSD 2006	rockAbundanceProperty	333
FAO GfSD 2006	rockShapeProperty	334
FAO GfSD 2006	rockShapeProperty	335
FAO GfSD 2006	rockShapeProperty	336
FAO GfSD 2006	rockShapeProperty	337
FAO GfSD 2006	rockSizeProperty	338
FAO GfSD 2006	rockSizeProperty	339
FAO GfSD 2006	rockSizeProperty	340
FAO GfSD 2006	rockSizeProperty	341
FAO GfSD 2006	rockSizeProperty	342
FAO GfSD 2006	rockSizeProperty	343
FAO GfSD 2006	rockSizeProperty	344
FAO GfSD 2006	rockSizeProperty	345
FAO GfSD 2006	rockSizeProperty	346
FAO GfSD 2006	rockSizeProperty	347
FAO GfSD 2006	rockSizeProperty	348
FAO GfSD 2006	rockSizeProperty	349
FAO GfSD 2006	rockSizeProperty	350
FAO GfSD 2006	rockSizeProperty	351
FAO GfSD 2006	rockSizeProperty	352
FAO GfSD 2006	rockSizeProperty	353
FAO GfSD 2006	rockSizeProperty	354
FAO GfSD 2006	rockSizeProperty	355
FAO GfSD 2006	weatheringFragmentsProperty	356
FAO GfSD 2006	weatheringFragmentsProperty	357
FAO GfSD 2006	weatheringFragmentsProperty	358
\.


--
-- TOC entry 4363 (class 0 OID 54021834)
-- Dependencies: 213
-- Data for Name: observation_desc_plot; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.observation_desc_plot (procedure_desc_id, property_desc_plot_id, thesaurus_desc_plot_id) FROM stdin;
FAO GfSD 2006	erosionActivityPeriodProperty	58
FAO GfSD 2006	erosionActivityPeriodProperty	59
FAO GfSD 2006	erosionActivityPeriodProperty	60
FAO GfSD 2006	erosionActivityPeriodProperty	61
FAO GfSD 2006	erosionActivityPeriodProperty	62
FAO GfSD 2006	erosionCategoryProperty	63
FAO GfSD 2006	erosionCategoryProperty	64
FAO GfSD 2006	erosionCategoryProperty	65
FAO GfSD 2006	erosionCategoryProperty	66
FAO GfSD 2006	erosionCategoryProperty	67
FAO GfSD 2006	erosionCategoryProperty	68
FAO GfSD 2006	erosionCategoryProperty	69
FAO GfSD 2006	erosionCategoryProperty	70
FAO GfSD 2006	erosionCategoryProperty	71
FAO GfSD 2006	erosionCategoryProperty	72
FAO GfSD 2006	erosionCategoryProperty	73
FAO GfSD 2006	erosionCategoryProperty	74
FAO GfSD 2006	erosionCategoryProperty	75
FAO GfSD 2006	erosionCategoryProperty	76
FAO GfSD 2006	erosionCategoryProperty	77
FAO GfSD 2006	erosionDegreeProperty	78
FAO GfSD 2006	erosionDegreeProperty	79
FAO GfSD 2006	erosionDegreeProperty	80
FAO GfSD 2006	erosionDegreeProperty	81
FAO GfSD 2006	erosionTotalAreaAffectedProperty	82
FAO GfSD 2006	erosionTotalAreaAffectedProperty	83
FAO GfSD 2006	erosionTotalAreaAffectedProperty	84
FAO GfSD 2006	erosionTotalAreaAffectedProperty	85
FAO GfSD 2006	erosionTotalAreaAffectedProperty	86
FAO GfSD 2006	erosionTotalAreaAffectedProperty	87
FAO GfSD 2006	geologyProperty	182
FAO GfSD 2006	geologyProperty	183
FAO GfSD 2006	geologyProperty	184
FAO GfSD 2006	geologyProperty	185
FAO GfSD 2006	geologyProperty	186
FAO GfSD 2006	geologyProperty	187
FAO GfSD 2006	geologyProperty	188
FAO GfSD 2006	geologyProperty	189
FAO GfSD 2006	geologyProperty	190
FAO GfSD 2006	geologyProperty	191
FAO GfSD 2006	geologyProperty	192
FAO GfSD 2006	geologyProperty	193
FAO GfSD 2006	geologyProperty	194
FAO GfSD 2006	geologyProperty	195
FAO GfSD 2006	geologyProperty	196
FAO GfSD 2006	geologyProperty	197
FAO GfSD 2006	geologyProperty	198
FAO GfSD 2006	geologyProperty	199
FAO GfSD 2006	geologyProperty	200
FAO GfSD 2006	geologyProperty	201
FAO GfSD 2006	geologyProperty	202
FAO GfSD 2006	geologyProperty	203
FAO GfSD 2006	geologyProperty	204
FAO GfSD 2006	geologyProperty	205
FAO GfSD 2006	geologyProperty	206
FAO GfSD 2006	geologyProperty	207
FAO GfSD 2006	geologyProperty	208
FAO GfSD 2006	geologyProperty	209
FAO GfSD 2006	geologyProperty	210
FAO GfSD 2006	geologyProperty	211
FAO GfSD 2006	geologyProperty	212
FAO GfSD 2006	geologyProperty	213
FAO GfSD 2006	geologyProperty	214
FAO GfSD 2006	geologyProperty	215
FAO GfSD 2006	geologyProperty	216
FAO GfSD 2006	geologyProperty	217
FAO GfSD 2006	geologyProperty	218
FAO GfSD 2006	geologyProperty	219
FAO GfSD 2006	geologyProperty	220
FAO GfSD 2006	geologyProperty	221
FAO GfSD 2006	geologyProperty	222
FAO GfSD 2006	geologyProperty	223
FAO GfSD 2006	geologyProperty	224
FAO GfSD 2006	geologyProperty	225
FAO GfSD 2006	geologyProperty	226
FAO GfSD 2006	geologyProperty	227
FAO GfSD 2006	geologyProperty	228
FAO GfSD 2006	geologyProperty	229
FAO GfSD 2006	geologyProperty	230
FAO GfSD 2006	geologyProperty	231
FAO GfSD 2006	geologyProperty	232
FAO GfSD 2006	geologyProperty	233
FAO GfSD 2006	geologyProperty	234
FAO GfSD 2006	geologyProperty	235
FAO GfSD 2006	geologyProperty	236
FAO GfSD 2006	geologyProperty	237
FAO GfSD 2006	geologyProperty	238
FAO GfSD 2006	geologyProperty	239
FAO GfSD 2006	geologyProperty	240
FAO GfSD 2006	geologyProperty	241
FAO GfSD 2006	geologyProperty	242
FAO GfSD 2006	geologyProperty	243
FAO GfSD 2006	geologyProperty	244
FAO GfSD 2006	geologyProperty	245
FAO GfSD 2006	geologyProperty	246
FAO GfSD 2006	geologyProperty	247
FAO GfSD 2006	geologyProperty	248
FAO GfSD 2006	geologyProperty	249
FAO GfSD 2006	geologyProperty	250
FAO GfSD 2006	geologyProperty	251
FAO GfSD 2006	geologyProperty	252
FAO GfSD 2006	geologyProperty	253
FAO GfSD 2006	geologyProperty	254
FAO GfSD 2006	geologyProperty	255
FAO GfSD 2006	geologyProperty	256
FAO GfSD 2006	geologyProperty	257
FAO GfSD 2006	geologyProperty	258
FAO GfSD 2006	geologyProperty	259
FAO GfSD 2006	geologyProperty	260
FAO GfSD 2006	geologyProperty	261
FAO GfSD 2006	geologyProperty	262
FAO GfSD 2006	geologyProperty	263
FAO GfSD 2006	geologyProperty	264
FAO GfSD 2006	geologyProperty	265
FAO GfSD 2006	geologyProperty	266
FAO GfSD 2006	geologyProperty	267
FAO GfSD 2006	geologyProperty	268
FAO GfSD 2006	geologyProperty	269
FAO GfSD 2006	humanInfluenceClassProperty	88
FAO GfSD 2006	humanInfluenceClassProperty	89
FAO GfSD 2006	humanInfluenceClassProperty	90
FAO GfSD 2006	humanInfluenceClassProperty	91
FAO GfSD 2006	humanInfluenceClassProperty	92
FAO GfSD 2006	humanInfluenceClassProperty	93
FAO GfSD 2006	humanInfluenceClassProperty	94
FAO GfSD 2006	humanInfluenceClassProperty	95
FAO GfSD 2006	humanInfluenceClassProperty	96
FAO GfSD 2006	humanInfluenceClassProperty	97
FAO GfSD 2006	humanInfluenceClassProperty	98
FAO GfSD 2006	humanInfluenceClassProperty	99
FAO GfSD 2006	humanInfluenceClassProperty	100
FAO GfSD 2006	humanInfluenceClassProperty	101
FAO GfSD 2006	humanInfluenceClassProperty	102
FAO GfSD 2006	humanInfluenceClassProperty	103
FAO GfSD 2006	humanInfluenceClassProperty	104
FAO GfSD 2006	humanInfluenceClassProperty	105
FAO GfSD 2006	humanInfluenceClassProperty	106
FAO GfSD 2006	humanInfluenceClassProperty	107
FAO GfSD 2006	humanInfluenceClassProperty	108
FAO GfSD 2006	humanInfluenceClassProperty	109
FAO GfSD 2006	humanInfluenceClassProperty	110
FAO GfSD 2006	humanInfluenceClassProperty	111
FAO GfSD 2006	humanInfluenceClassProperty	112
FAO GfSD 2006	humanInfluenceClassProperty	113
FAO GfSD 2006	humanInfluenceClassProperty	114
FAO GfSD 2006	humanInfluenceClassProperty	115
FAO GfSD 2006	humanInfluenceClassProperty	116
FAO GfSD 2006	humanInfluenceClassProperty	117
FAO GfSD 2006	humanInfluenceClassProperty	118
FAO GfSD 2006	humanInfluenceClassProperty	119
FAO GfSD 2006	humanInfluenceClassProperty	120
FAO GfSD 2006	humanInfluenceClassProperty	121
FAO GfSD 2006	humanInfluenceClassProperty	122
FAO GfSD 2006	landUseClassProperty	123
FAO GfSD 2006	landUseClassProperty	124
FAO GfSD 2006	landUseClassProperty	125
FAO GfSD 2006	landUseClassProperty	126
FAO GfSD 2006	landUseClassProperty	127
FAO GfSD 2006	landUseClassProperty	128
FAO GfSD 2006	landUseClassProperty	129
FAO GfSD 2006	landUseClassProperty	130
FAO GfSD 2006	landUseClassProperty	131
FAO GfSD 2006	landUseClassProperty	132
FAO GfSD 2006	landUseClassProperty	133
FAO GfSD 2006	landUseClassProperty	134
FAO GfSD 2006	landUseClassProperty	135
FAO GfSD 2006	landUseClassProperty	136
FAO GfSD 2006	landUseClassProperty	137
FAO GfSD 2006	landUseClassProperty	138
FAO GfSD 2006	landUseClassProperty	139
FAO GfSD 2006	landUseClassProperty	140
FAO GfSD 2006	landUseClassProperty	141
FAO GfSD 2006	landUseClassProperty	142
FAO GfSD 2006	landUseClassProperty	143
FAO GfSD 2006	landUseClassProperty	144
FAO GfSD 2006	landUseClassProperty	145
FAO GfSD 2006	landUseClassProperty	146
FAO GfSD 2006	landUseClassProperty	147
FAO GfSD 2006	landUseClassProperty	148
FAO GfSD 2006	landUseClassProperty	149
FAO GfSD 2006	landUseClassProperty	150
FAO GfSD 2006	landUseClassProperty	151
FAO GfSD 2006	landUseClassProperty	152
FAO GfSD 2006	landUseClassProperty	153
FAO GfSD 2006	landUseClassProperty	154
FAO GfSD 2006	landUseClassProperty	155
FAO GfSD 2006	landUseClassProperty	156
FAO GfSD 2006	landUseClassProperty	157
FAO GfSD 2006	landUseClassProperty	158
FAO GfSD 2006	landUseClassProperty	159
FAO GfSD 2006	landUseClassProperty	160
FAO GfSD 2006	landUseClassProperty	161
FAO GfSD 2006	landUseClassProperty	162
FAO GfSD 2006	landUseClassProperty	163
FAO GfSD 2006	landUseClassProperty	164
FAO GfSD 2006	landUseClassProperty	165
FAO GfSD 2006	landUseClassProperty	166
FAO GfSD 2006	landUseClassProperty	167
FAO GfSD 2006	landUseClassProperty	168
FAO GfSD 2006	landUseClassProperty	169
FAO GfSD 2006	landUseClassProperty	170
FAO GfSD 2006	landUseClassProperty	171
FAO GfSD 2006	landUseClassProperty	172
FAO GfSD 2006	LandformComplexProperty	173
FAO GfSD 2006	LandformComplexProperty	174
FAO GfSD 2006	LandformComplexProperty	175
FAO GfSD 2006	LandformComplexProperty	176
FAO GfSD 2006	LandformComplexProperty	177
FAO GfSD 2006	LandformComplexProperty	178
FAO GfSD 2006	LandformComplexProperty	179
FAO GfSD 2006	LandformComplexProperty	180
FAO GfSD 2006	LandformComplexProperty	181
FAO GfSD 2006	lithologyProperty	182
FAO GfSD 2006	lithologyProperty	183
FAO GfSD 2006	lithologyProperty	184
FAO GfSD 2006	lithologyProperty	185
FAO GfSD 2006	lithologyProperty	186
FAO GfSD 2006	lithologyProperty	187
FAO GfSD 2006	lithologyProperty	188
FAO GfSD 2006	lithologyProperty	189
FAO GfSD 2006	lithologyProperty	190
FAO GfSD 2006	lithologyProperty	191
FAO GfSD 2006	lithologyProperty	192
FAO GfSD 2006	lithologyProperty	193
FAO GfSD 2006	lithologyProperty	194
FAO GfSD 2006	lithologyProperty	195
FAO GfSD 2006	lithologyProperty	196
FAO GfSD 2006	lithologyProperty	197
FAO GfSD 2006	lithologyProperty	198
FAO GfSD 2006	lithologyProperty	199
FAO GfSD 2006	lithologyProperty	200
FAO GfSD 2006	lithologyProperty	201
FAO GfSD 2006	lithologyProperty	202
FAO GfSD 2006	lithologyProperty	203
FAO GfSD 2006	lithologyProperty	204
FAO GfSD 2006	lithologyProperty	205
FAO GfSD 2006	lithologyProperty	206
FAO GfSD 2006	lithologyProperty	207
FAO GfSD 2006	lithologyProperty	208
FAO GfSD 2006	lithologyProperty	209
FAO GfSD 2006	lithologyProperty	210
FAO GfSD 2006	lithologyProperty	211
FAO GfSD 2006	lithologyProperty	212
FAO GfSD 2006	lithologyProperty	213
FAO GfSD 2006	lithologyProperty	214
FAO GfSD 2006	lithologyProperty	215
FAO GfSD 2006	lithologyProperty	216
FAO GfSD 2006	lithologyProperty	217
FAO GfSD 2006	lithologyProperty	218
FAO GfSD 2006	lithologyProperty	219
FAO GfSD 2006	lithologyProperty	220
FAO GfSD 2006	lithologyProperty	221
FAO GfSD 2006	lithologyProperty	222
FAO GfSD 2006	lithologyProperty	223
FAO GfSD 2006	lithologyProperty	224
FAO GfSD 2006	lithologyProperty	225
FAO GfSD 2006	lithologyProperty	226
FAO GfSD 2006	lithologyProperty	227
FAO GfSD 2006	lithologyProperty	228
FAO GfSD 2006	lithologyProperty	229
FAO GfSD 2006	lithologyProperty	230
FAO GfSD 2006	lithologyProperty	231
FAO GfSD 2006	lithologyProperty	232
FAO GfSD 2006	lithologyProperty	233
FAO GfSD 2006	lithologyProperty	234
FAO GfSD 2006	lithologyProperty	235
FAO GfSD 2006	lithologyProperty	236
FAO GfSD 2006	lithologyProperty	237
FAO GfSD 2006	lithologyProperty	238
FAO GfSD 2006	lithologyProperty	239
FAO GfSD 2006	lithologyProperty	240
FAO GfSD 2006	lithologyProperty	241
FAO GfSD 2006	lithologyProperty	242
FAO GfSD 2006	lithologyProperty	243
FAO GfSD 2006	lithologyProperty	244
FAO GfSD 2006	lithologyProperty	245
FAO GfSD 2006	lithologyProperty	246
FAO GfSD 2006	lithologyProperty	247
FAO GfSD 2006	lithologyProperty	248
FAO GfSD 2006	lithologyProperty	249
FAO GfSD 2006	lithologyProperty	250
FAO GfSD 2006	lithologyProperty	251
FAO GfSD 2006	lithologyProperty	252
FAO GfSD 2006	lithologyProperty	253
FAO GfSD 2006	lithologyProperty	254
FAO GfSD 2006	lithologyProperty	255
FAO GfSD 2006	lithologyProperty	256
FAO GfSD 2006	lithologyProperty	257
FAO GfSD 2006	lithologyProperty	258
FAO GfSD 2006	lithologyProperty	259
FAO GfSD 2006	lithologyProperty	260
FAO GfSD 2006	lithologyProperty	261
FAO GfSD 2006	lithologyProperty	262
FAO GfSD 2006	lithologyProperty	263
FAO GfSD 2006	lithologyProperty	264
FAO GfSD 2006	lithologyProperty	265
FAO GfSD 2006	lithologyProperty	266
FAO GfSD 2006	lithologyProperty	267
FAO GfSD 2006	lithologyProperty	268
FAO GfSD 2006	lithologyProperty	269
FAO GfSD 2006	MajorLandFormProperty	270
FAO GfSD 2006	MajorLandFormProperty	271
FAO GfSD 2006	MajorLandFormProperty	272
FAO GfSD 2006	MajorLandFormProperty	273
FAO GfSD 2006	MajorLandFormProperty	274
FAO GfSD 2006	MajorLandFormProperty	275
FAO GfSD 2006	MajorLandFormProperty	276
FAO GfSD 2006	MajorLandFormProperty	277
FAO GfSD 2006	MajorLandFormProperty	278
FAO GfSD 2006	MajorLandFormProperty	279
FAO GfSD 2006	MajorLandFormProperty	280
FAO GfSD 2006	MajorLandFormProperty	281
FAO GfSD 2006	MajorLandFormProperty	282
FAO GfSD 2006	MajorLandFormProperty	283
FAO GfSD 2006	MajorLandFormProperty	284
FAO GfSD 2006	MajorLandFormProperty	285
FAO GfSD 2006	ParentDepositionProperty	63
FAO GfSD 2006	ParentDepositionProperty	64
FAO GfSD 2006	ParentDepositionProperty	65
FAO GfSD 2006	ParentDepositionProperty	66
FAO GfSD 2006	ParentDepositionProperty	67
FAO GfSD 2006	ParentDepositionProperty	68
FAO GfSD 2006	ParentDepositionProperty	69
FAO GfSD 2006	ParentDepositionProperty	70
FAO GfSD 2006	ParentDepositionProperty	71
FAO GfSD 2006	ParentDepositionProperty	72
FAO GfSD 2006	ParentDepositionProperty	73
FAO GfSD 2006	ParentDepositionProperty	74
FAO GfSD 2006	ParentDepositionProperty	75
FAO GfSD 2006	ParentDepositionProperty	76
FAO GfSD 2006	ParentDepositionProperty	77
FAO GfSD 2006	parentLithologyProperty	182
FAO GfSD 2006	parentLithologyProperty	183
FAO GfSD 2006	parentLithologyProperty	184
FAO GfSD 2006	parentLithologyProperty	185
FAO GfSD 2006	parentLithologyProperty	186
FAO GfSD 2006	parentLithologyProperty	187
FAO GfSD 2006	parentLithologyProperty	188
FAO GfSD 2006	parentLithologyProperty	189
FAO GfSD 2006	parentLithologyProperty	190
FAO GfSD 2006	parentLithologyProperty	191
FAO GfSD 2006	parentLithologyProperty	192
FAO GfSD 2006	parentLithologyProperty	193
FAO GfSD 2006	parentLithologyProperty	194
FAO GfSD 2006	parentLithologyProperty	195
FAO GfSD 2006	parentLithologyProperty	196
FAO GfSD 2006	parentLithologyProperty	197
FAO GfSD 2006	parentLithologyProperty	198
FAO GfSD 2006	parentLithologyProperty	199
FAO GfSD 2006	parentLithologyProperty	200
FAO GfSD 2006	parentLithologyProperty	201
FAO GfSD 2006	parentLithologyProperty	202
FAO GfSD 2006	parentLithologyProperty	203
FAO GfSD 2006	parentLithologyProperty	204
FAO GfSD 2006	parentLithologyProperty	205
FAO GfSD 2006	parentLithologyProperty	206
FAO GfSD 2006	parentLithologyProperty	207
FAO GfSD 2006	parentLithologyProperty	208
FAO GfSD 2006	parentLithologyProperty	209
FAO GfSD 2006	parentLithologyProperty	210
FAO GfSD 2006	parentLithologyProperty	211
FAO GfSD 2006	parentLithologyProperty	212
FAO GfSD 2006	parentLithologyProperty	213
FAO GfSD 2006	parentLithologyProperty	214
FAO GfSD 2006	parentLithologyProperty	215
FAO GfSD 2006	parentLithologyProperty	216
FAO GfSD 2006	parentLithologyProperty	217
FAO GfSD 2006	parentLithologyProperty	218
FAO GfSD 2006	parentLithologyProperty	219
FAO GfSD 2006	parentLithologyProperty	220
FAO GfSD 2006	parentLithologyProperty	221
FAO GfSD 2006	parentLithologyProperty	222
FAO GfSD 2006	parentLithologyProperty	223
FAO GfSD 2006	parentLithologyProperty	224
FAO GfSD 2006	parentLithologyProperty	225
FAO GfSD 2006	parentLithologyProperty	226
FAO GfSD 2006	parentLithologyProperty	227
FAO GfSD 2006	parentLithologyProperty	228
FAO GfSD 2006	parentLithologyProperty	229
FAO GfSD 2006	parentLithologyProperty	230
FAO GfSD 2006	parentLithologyProperty	231
FAO GfSD 2006	parentLithologyProperty	232
FAO GfSD 2006	parentLithologyProperty	233
FAO GfSD 2006	parentLithologyProperty	234
FAO GfSD 2006	parentLithologyProperty	235
FAO GfSD 2006	parentLithologyProperty	236
FAO GfSD 2006	parentLithologyProperty	237
FAO GfSD 2006	parentLithologyProperty	238
FAO GfSD 2006	parentLithologyProperty	239
FAO GfSD 2006	parentLithologyProperty	240
FAO GfSD 2006	parentLithologyProperty	241
FAO GfSD 2006	parentLithologyProperty	242
FAO GfSD 2006	parentLithologyProperty	243
FAO GfSD 2006	parentLithologyProperty	244
FAO GfSD 2006	parentLithologyProperty	245
FAO GfSD 2006	parentLithologyProperty	246
FAO GfSD 2006	parentLithologyProperty	247
FAO GfSD 2006	parentLithologyProperty	248
FAO GfSD 2006	parentLithologyProperty	249
FAO GfSD 2006	parentLithologyProperty	250
FAO GfSD 2006	parentLithologyProperty	251
FAO GfSD 2006	parentLithologyProperty	252
FAO GfSD 2006	parentLithologyProperty	253
FAO GfSD 2006	parentLithologyProperty	254
FAO GfSD 2006	parentLithologyProperty	255
FAO GfSD 2006	parentLithologyProperty	256
FAO GfSD 2006	parentLithologyProperty	257
FAO GfSD 2006	parentLithologyProperty	258
FAO GfSD 2006	parentLithologyProperty	259
FAO GfSD 2006	parentLithologyProperty	260
FAO GfSD 2006	parentLithologyProperty	261
FAO GfSD 2006	parentLithologyProperty	262
FAO GfSD 2006	parentLithologyProperty	263
FAO GfSD 2006	parentLithologyProperty	264
FAO GfSD 2006	parentLithologyProperty	265
FAO GfSD 2006	parentLithologyProperty	266
FAO GfSD 2006	parentLithologyProperty	267
FAO GfSD 2006	parentLithologyProperty	268
FAO GfSD 2006	parentLithologyProperty	269
FAO GfSD 2006	PhysiographyProperty	286
FAO GfSD 2006	PhysiographyProperty	287
FAO GfSD 2006	PhysiographyProperty	288
FAO GfSD 2006	PhysiographyProperty	289
FAO GfSD 2006	PhysiographyProperty	290
FAO GfSD 2006	PhysiographyProperty	291
FAO GfSD 2006	PhysiographyProperty	292
FAO GfSD 2006	PhysiographyProperty	293
FAO GfSD 2006	PhysiographyProperty	294
FAO GfSD 2006	PhysiographyProperty	295
FAO GfSD 2006	rockOutcropsCoverProperty	296
FAO GfSD 2006	rockOutcropsCoverProperty	297
FAO GfSD 2006	rockOutcropsCoverProperty	298
FAO GfSD 2006	rockOutcropsCoverProperty	299
FAO GfSD 2006	rockOutcropsCoverProperty	300
FAO GfSD 2006	rockOutcropsCoverProperty	301
FAO GfSD 2006	rockOutcropsCoverProperty	302
FAO GfSD 2006	rockOutcropsDistanceProperty	303
FAO GfSD 2006	rockOutcropsDistanceProperty	304
FAO GfSD 2006	rockOutcropsDistanceProperty	305
FAO GfSD 2006	rockOutcropsDistanceProperty	306
FAO GfSD 2006	rockOutcropsDistanceProperty	307
FAO GfSD 2006	slopeFormProperty	308
FAO GfSD 2006	slopeFormProperty	309
FAO GfSD 2006	slopeFormProperty	310
FAO GfSD 2006	slopeFormProperty	311
FAO GfSD 2006	slopeFormProperty	312
FAO GfSD 2006	slopeGradientClassProperty	313
FAO GfSD 2006	slopeGradientClassProperty	314
FAO GfSD 2006	slopeGradientClassProperty	315
FAO GfSD 2006	slopeGradientClassProperty	316
FAO GfSD 2006	slopeGradientClassProperty	317
FAO GfSD 2006	slopeGradientClassProperty	318
FAO GfSD 2006	slopeGradientClassProperty	319
FAO GfSD 2006	slopeGradientClassProperty	320
FAO GfSD 2006	slopeGradientClassProperty	321
FAO GfSD 2006	slopeGradientClassProperty	322
FAO GfSD 2006	slopePathwaysProperty	323
FAO GfSD 2006	slopePathwaysProperty	324
FAO GfSD 2006	slopePathwaysProperty	325
FAO GfSD 2006	slopePathwaysProperty	326
FAO GfSD 2006	slopePathwaysProperty	327
FAO GfSD 2006	slopePathwaysProperty	328
FAO GfSD 2006	slopePathwaysProperty	329
FAO GfSD 2006	slopePathwaysProperty	330
FAO GfSD 2006	slopePathwaysProperty	331
FAO GfSD 2006	surfaceAgeProperty	332
FAO GfSD 2006	surfaceAgeProperty	333
FAO GfSD 2006	surfaceAgeProperty	334
FAO GfSD 2006	surfaceAgeProperty	335
FAO GfSD 2006	surfaceAgeProperty	336
FAO GfSD 2006	surfaceAgeProperty	337
FAO GfSD 2006	surfaceAgeProperty	338
FAO GfSD 2006	surfaceAgeProperty	339
FAO GfSD 2006	surfaceAgeProperty	340
FAO GfSD 2006	surfaceAgeProperty	341
FAO GfSD 2006	surfaceAgeProperty	342
FAO GfSD 2006	surfaceAgeProperty	343
FAO GfSD 2006	surfaceAgeProperty	344
FAO GfSD 2006	surfaceAgeProperty	345
FAO GfSD 2006	VegetationClassProperty	346
FAO GfSD 2006	VegetationClassProperty	347
FAO GfSD 2006	VegetationClassProperty	348
FAO GfSD 2006	VegetationClassProperty	349
FAO GfSD 2006	VegetationClassProperty	350
FAO GfSD 2006	VegetationClassProperty	351
FAO GfSD 2006	VegetationClassProperty	352
FAO GfSD 2006	VegetationClassProperty	353
FAO GfSD 2006	VegetationClassProperty	354
FAO GfSD 2006	VegetationClassProperty	355
FAO GfSD 2006	VegetationClassProperty	356
FAO GfSD 2006	VegetationClassProperty	357
FAO GfSD 2006	VegetationClassProperty	358
FAO GfSD 2006	VegetationClassProperty	359
FAO GfSD 2006	VegetationClassProperty	360
FAO GfSD 2006	VegetationClassProperty	361
FAO GfSD 2006	VegetationClassProperty	362
FAO GfSD 2006	VegetationClassProperty	363
FAO GfSD 2006	VegetationClassProperty	364
FAO GfSD 2006	VegetationClassProperty	365
FAO GfSD 2006	VegetationClassProperty	366
FAO GfSD 2006	VegetationClassProperty	367
FAO GfSD 2006	VegetationClassProperty	368
FAO GfSD 2006	VegetationClassProperty	369
FAO GfSD 2006	VegetationClassProperty	370
FAO GfSD 2006	VegetationClassProperty	371
FAO GfSD 2006	VegetationClassProperty	372
FAO GfSD 2006	VegetationClassProperty	373
FAO GfSD 2006	VegetationClassProperty	374
FAO GfSD 2006	weatherConditionsCurrentProperty	375
FAO GfSD 2006	weatherConditionsCurrentProperty	376
FAO GfSD 2006	weatherConditionsCurrentProperty	377
FAO GfSD 2006	weatherConditionsCurrentProperty	378
FAO GfSD 2006	weatherConditionsCurrentProperty	379
FAO GfSD 2006	weatherConditionsCurrentProperty	380
FAO GfSD 2006	weatherConditionsCurrentProperty	381
FAO GfSD 2006	weatherConditionsCurrentProperty	382
FAO GfSD 2006	weatherConditionsCurrentProperty	383
FAO GfSD 2006	weatherConditionsCurrentProperty	384
FAO GfSD 2006	weatherConditionsCurrentProperty	385
FAO GfSD 2006	weatherConditionsCurrentProperty	386
FAO GfSD 2006	weatherConditionsPastProperty	375
FAO GfSD 2006	weatherConditionsPastProperty	376
FAO GfSD 2006	weatherConditionsPastProperty	377
FAO GfSD 2006	weatherConditionsPastProperty	378
FAO GfSD 2006	weatherConditionsPastProperty	379
FAO GfSD 2006	weatherConditionsPastProperty	380
FAO GfSD 2006	weatherConditionsPastProperty	381
FAO GfSD 2006	weatherConditionsPastProperty	382
FAO GfSD 2006	weatherConditionsPastProperty	383
FAO GfSD 2006	weatherConditionsPastProperty	384
FAO GfSD 2006	weatherConditionsPastProperty	385
FAO GfSD 2006	weatherConditionsPastProperty	386
FAO GfSD 2006	weatheringRockProperty	387
FAO GfSD 2006	weatheringRockProperty	388
FAO GfSD 2006	weatheringRockProperty	389
FAO GfSD 2006	weatheringFragmentsProperty	387
FAO GfSD 2006	weatheringFragmentsProperty	388
FAO GfSD 2006	weatheringFragmentsProperty	389
FAO GfSD 2006	cropClassProperty	16
FAO GfSD 2006	cropClassProperty	8
FAO GfSD 2006	cropClassProperty	24
FAO GfSD 2006	cropClassProperty	4
FAO GfSD 2006	cropClassProperty	20
FAO GfSD 2006	cropClassProperty	12
FAO GfSD 2006	cropClassProperty	2
FAO GfSD 2006	cropClassProperty	18
FAO GfSD 2006	cropClassProperty	10
FAO GfSD 2006	cropClassProperty	22
FAO GfSD 2006	cropClassProperty	6
FAO GfSD 2006	cropClassProperty	14
FAO GfSD 2006	cropClassProperty	1
FAO GfSD 2006	cropClassProperty	11
FAO GfSD 2006	cropClassProperty	19
FAO GfSD 2006	cropClassProperty	3
FAO GfSD 2006	cropClassProperty	23
FAO GfSD 2006	cropClassProperty	7
FAO GfSD 2006	cropClassProperty	15
FAO GfSD 2006	cropClassProperty	25
FAO GfSD 2006	cropClassProperty	9
FAO GfSD 2006	cropClassProperty	17
FAO GfSD 2006	cropClassProperty	5
FAO GfSD 2006	cropClassProperty	21
FAO GfSD 2006	cropClassProperty	13
FAO GfSD 2006	cropClassProperty	26
FAO GfSD 2006	cropClassProperty	27
FAO GfSD 2006	cropClassProperty	28
FAO GfSD 2006	cropClassProperty	29
FAO GfSD 2006	cropClassProperty	30
FAO GfSD 2006	cropClassProperty	31
FAO GfSD 2006	cropClassProperty	32
FAO GfSD 2006	cropClassProperty	33
FAO GfSD 2006	cropClassProperty	34
FAO GfSD 2006	cropClassProperty	35
FAO GfSD 2006	cropClassProperty	36
FAO GfSD 2006	cropClassProperty	37
FAO GfSD 2006	cropClassProperty	38
FAO GfSD 2006	cropClassProperty	39
FAO GfSD 2006	cropClassProperty	40
FAO GfSD 2006	cropClassProperty	41
FAO GfSD 2006	cropClassProperty	42
FAO GfSD 2006	cropClassProperty	43
FAO GfSD 2006	cropClassProperty	44
FAO GfSD 2006	cropClassProperty	45
FAO GfSD 2006	cropClassProperty	46
FAO GfSD 2006	cropClassProperty	47
FAO GfSD 2006	cropClassProperty	48
FAO GfSD 2006	cropClassProperty	49
FAO GfSD 2006	cropClassProperty	50
FAO GfSD 2006	cropClassProperty	51
FAO GfSD 2006	cropClassProperty	52
FAO GfSD 2006	cropClassProperty	53
FAO GfSD 2006	cropClassProperty	54
FAO GfSD 2006	cropClassProperty	55
FAO GfSD 2006	cropClassProperty	56
FAO GfSD 2006	cropClassProperty	57
FAO GfSD 2006	SaltCoverProperty	447
FAO GfSD 2006	SaltCoverProperty	448
FAO GfSD 2006	SaltCoverProperty	449
FAO GfSD 2006	SaltCoverProperty	450
FAO GfSD 2006	SaltCoverProperty	451
FAO GfSD 2006	SaltThicknessProperty	452
FAO GfSD 2006	SaltThicknessProperty	453
FAO GfSD 2006	SaltThicknessProperty	454
FAO GfSD 2006	SaltThicknessProperty	455
FAO GfSD 2006	SaltThicknessProperty	456
FAO GfSD 2006	sealingConsistenceProperty	457
FAO GfSD 2006	sealingConsistenceProperty	458
FAO GfSD 2006	sealingConsistenceProperty	459
FAO GfSD 2006	sealingConsistenceProperty	460
FAO GfSD 2006	sealingThicknessProperty	461
FAO GfSD 2006	sealingThicknessProperty	462
FAO GfSD 2006	sealingThicknessProperty	463
FAO GfSD 2006	sealingThicknessProperty	464
FAO GfSD 2006	sealingThicknessProperty	465
FAO GfSD 2006	cracksDepthProperty	390
FAO GfSD 2006	cracksDepthProperty	391
FAO GfSD 2006	cracksDepthProperty	392
FAO GfSD 2006	cracksDepthProperty	393
FAO GfSD 2006	cracksDistanceProperty	394
FAO GfSD 2006	cracksDistanceProperty	395
FAO GfSD 2006	cracksDistanceProperty	396
FAO GfSD 2006	cracksDistanceProperty	397
FAO GfSD 2006	cracksDistanceProperty	398
FAO GfSD 2006	cracksWidthProperty	399
FAO GfSD 2006	cracksWidthProperty	400
FAO GfSD 2006	cracksWidthProperty	401
FAO GfSD 2006	cracksWidthProperty	402
FAO GfSD 2006	cracksWidthProperty	403
FAO GfSD 2006	fragmentCoverProperty	404
FAO GfSD 2006	fragmentCoverProperty	405
FAO GfSD 2006	fragmentCoverProperty	406
FAO GfSD 2006	fragmentCoverProperty	407
FAO GfSD 2006	fragmentCoverProperty	408
FAO GfSD 2006	fragmentCoverProperty	409
FAO GfSD 2006	fragmentCoverProperty	410
FAO GfSD 2006	fragmentSizeProperty	411
FAO GfSD 2006	fragmentSizeProperty	412
FAO GfSD 2006	fragmentSizeProperty	413
FAO GfSD 2006	fragmentSizeProperty	414
FAO GfSD 2006	fragmentSizeProperty	415
FAO GfSD 2006	fragmentSizeProperty	416
FAO GfSD 2006	rockAbundanceProperty	417
FAO GfSD 2006	rockAbundanceProperty	418
FAO GfSD 2006	rockAbundanceProperty	419
FAO GfSD 2006	rockAbundanceProperty	420
FAO GfSD 2006	rockAbundanceProperty	421
FAO GfSD 2006	rockAbundanceProperty	422
FAO GfSD 2006	rockAbundanceProperty	423
FAO GfSD 2006	rockAbundanceProperty	424
FAO GfSD 2006	rockShapeProperty	425
FAO GfSD 2006	rockShapeProperty	426
FAO GfSD 2006	rockShapeProperty	427
FAO GfSD 2006	rockShapeProperty	428
FAO GfSD 2006	rockSizeProperty	429
FAO GfSD 2006	rockSizeProperty	430
FAO GfSD 2006	rockSizeProperty	431
FAO GfSD 2006	rockSizeProperty	432
FAO GfSD 2006	rockSizeProperty	433
FAO GfSD 2006	rockSizeProperty	434
FAO GfSD 2006	rockSizeProperty	435
FAO GfSD 2006	rockSizeProperty	436
FAO GfSD 2006	rockSizeProperty	437
FAO GfSD 2006	rockSizeProperty	438
FAO GfSD 2006	rockSizeProperty	439
FAO GfSD 2006	rockSizeProperty	440
FAO GfSD 2006	rockSizeProperty	441
FAO GfSD 2006	rockSizeProperty	442
FAO GfSD 2006	rockSizeProperty	443
FAO GfSD 2006	rockSizeProperty	444
FAO GfSD 2006	rockSizeProperty	445
FAO GfSD 2006	rockSizeProperty	446
\.


--
-- TOC entry 4364 (class 0 OID 54021837)
-- Dependencies: 214
-- Data for Name: observation_desc_profile; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.observation_desc_profile (procedure_desc_id, property_desc_profile_id, thesaurus_desc_profile_id) FROM stdin;
FAO GfSD 2006	profileDescriptionStatusProperty	4
FAO GfSD 2006	profileDescriptionStatusProperty	8
FAO GfSD 2006	profileDescriptionStatusProperty	2
FAO GfSD 2006	profileDescriptionStatusProperty	6
FAO GfSD 2006	profileDescriptionStatusProperty	1
FAO GfSD 2006	profileDescriptionStatusProperty	7
FAO GfSD 2006	profileDescriptionStatusProperty	3
FAO GfSD 2006	profileDescriptionStatusProperty	9
FAO GfSD 2006	profileDescriptionStatusProperty	5
\.


--
-- TOC entry 4365 (class 0 OID 54021854)
-- Dependencies: 215
-- Data for Name: observation_phys_chem; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.observation_phys_chem (observation_phys_chem_id, property_phys_chem_id, procedure_phys_chem_id, unit_of_measure_id, value_min, value_max) FROM stdin;
543	pHProperty	pHH2O	pH	1.5	13
175	Boron (B) - extractable	Extr_ap14	%	0	100
514	pH - Hydrogen potential	pHH2O	pH	1.5	13
508	pH - Hydrogen potential	pHCaCl2_ratio1-1	pH	1.5	13
537	pHProperty	pHCaCl2_ratio1-1	pH	1.5	13
509	pH - Hydrogen potential	pHCaCl2_ratio1-10	pH	1.5	13
538	pHProperty	pHCaCl2_ratio1-10	pH	1.5	13
510	pH - Hydrogen potential	pHCaCl2_ratio1-2	pH	1.5	13
539	pHProperty	pHCaCl2_ratio1-2	pH	1.5	13
511	pH - Hydrogen potential	pHCaCl2_ratio1-2.5	pH	1.5	13
540	pHProperty	pHCaCl2_ratio1-2.5	pH	1.5	13
512	pH - Hydrogen potential	pHCaCl2_ratio1-5	pH	1.5	13
541	pHProperty	pHCaCl2_ratio1-5	pH	1.5	13
513	pH - Hydrogen potential	pHCaCl2_sat	pH	1.5	13
542	pHProperty	pHCaCl2_sat	pH	1.5	13
515	pH - Hydrogen potential	pHH2O_ratio1-1	pH	1.5	13
544	pHProperty	pHH2O_ratio1-1	pH	1.5	13
516	pH - Hydrogen potential	pHH2O_ratio1-10	pH	1.5	13
545	pHProperty	pHH2O_ratio1-10	pH	1.5	13
517	pH - Hydrogen potential	pHH2O_ratio1-2	pH	1.5	13
546	pHProperty	pHH2O_ratio1-2	pH	1.5	13
518	pH - Hydrogen potential	pHH2O_ratio1-2.5	pH	1.5	13
547	pHProperty	pHH2O_ratio1-2.5	pH	1.5	13
519	pH - Hydrogen potential	pHH2O_ratio1-5	pH	1.5	13
548	pHProperty	pHH2O_ratio1-5	pH	1.5	13
520	pH - Hydrogen potential	pHH2O_sat	pH	1.5	13
635	Clay texture fraction	SaSiCl_2-50-2000u-adj100	%	0	100
587	Sand texture fraction	SaSiCl_2-50-2000u-adj100	%	0	100
683	Silt texture fraction	SaSiCl_2-50-2000u-adj100	%	0	100
619	Clay texture fraction	SaSiCl_2-20-2000u-adj100	%	0	100
571	Sand texture fraction	SaSiCl_2-20-2000u-adj100	%	0	100
667	Silt texture fraction	SaSiCl_2-20-2000u-adj100	%	0	100
620	Clay texture fraction	SaSiCl_2-20-2000u-disp	%	0	100
572	Sand texture fraction	SaSiCl_2-20-2000u-disp	%	0	100
668	Silt texture fraction	SaSiCl_2-20-2000u-disp	%	0	100
621	Clay texture fraction	SaSiCl_2-20-2000u-disp-beaker	%	0	100
573	Sand texture fraction	SaSiCl_2-20-2000u-disp-beaker	%	0	100
669	Silt texture fraction	SaSiCl_2-20-2000u-disp-beaker	%	0	100
622	Clay texture fraction	SaSiCl_2-20-2000u-disp-hydrometer	%	0	100
574	Sand texture fraction	SaSiCl_2-20-2000u-disp-hydrometer	%	0	100
670	Silt texture fraction	SaSiCl_2-20-2000u-disp-hydrometer	%	0	100
623	Clay texture fraction	SaSiCl_2-20-2000u-disp-hydrometer-bouy	%	0	100
575	Sand texture fraction	SaSiCl_2-20-2000u-disp-hydrometer-bouy	%	0	100
671	Silt texture fraction	SaSiCl_2-20-2000u-disp-hydrometer-bouy	%	0	100
624	Clay texture fraction	SaSiCl_2-20-2000u-disp-laser	%	0	100
576	Sand texture fraction	SaSiCl_2-20-2000u-disp-laser	%	0	100
672	Silt texture fraction	SaSiCl_2-20-2000u-disp-laser	%	0	100
625	Clay texture fraction	SaSiCl_2-20-2000u-disp-pipette	%	0	100
577	Sand texture fraction	SaSiCl_2-20-2000u-disp-pipette	%	0	100
673	Silt texture fraction	SaSiCl_2-20-2000u-disp-pipette	%	0	100
626	Clay texture fraction	SaSiCl_2-20-2000u-disp-spec	%	0	100
578	Sand texture fraction	SaSiCl_2-20-2000u-disp-spec	%	0	100
493	Nitrogen (N) - total	TotalN_dc-ht-dumas	g/kg	0	1000
494	Nitrogen (N) - total	TotalN_dc-ht-leco	g/kg	0	1000
495	Nitrogen (N) - total	TotalN_dc-spec	g/kg	0	1000
69	electricalConductivityProperty	EC_ratio1-2	dS/m	0	60
674	Silt texture fraction	SaSiCl_2-20-2000u-disp-spec	%	0	100
706	Silt texture fraction	SaSiCl_2-64-2000u-disp-spec	%	0	100
659	Clay texture fraction	SaSiCl_2-64-2000u-fld	%	0	100
611	Sand texture fraction	SaSiCl_2-64-2000u-fld	%	0	100
707	Silt texture fraction	SaSiCl_2-64-2000u-fld	%	0	100
8	Available water capacity - volumetric (FC to WP)	PAWHC_calcul-fc100wp	m³/100 m³	0	100
9	Available water capacity - volumetric (FC to WP)	PAWHC_calcul-fc200wp	m³/100 m³	0	100
10	Available water capacity - volumetric (FC to WP)	PAWHC_calcul-fc300wp	m³/100 m³	0	100
31	carbonInorganicProperty	InOrgC_calcul-caco3	g/kg	0	1000
32	carbonInorganicProperty	InOrgC_calcul-tc-oc	g/kg	0	1000
33	Carbon (C) - organic	OrgC_acid-dc	g/kg	0	1000
34	Carbon (C) - organic	OrgC_acid-dc-ht	g/kg	0	1000
35	Carbon (C) - organic	OrgC_acid-dc-ht-analyser	g/kg	0	1000
36	Carbon (C) - organic	OrgC_acid-dc-lt	g/kg	0	1000
37	Carbon (C) - organic	OrgC_acid-dc-lt-loi	g/kg	0	1000
38	Carbon (C) - organic	OrgC_acid-dc-mt	g/kg	0	1000
39	Carbon (C) - organic	OrgC_acid-dc-spec	g/kg	0	1000
40	Carbon (C) - organic	OrgC_calcul-tc-ic	g/kg	0	1000
41	Carbon (C) - organic	OrgC_dc	g/kg	0	1000
42	Carbon (C) - organic	OrgC_dc-ht	g/kg	0	1000
43	Carbon (C) - organic	OrgC_dc-ht-analyser	g/kg	0	1000
44	Carbon (C) - organic	OrgC_dc-lt	g/kg	0	1000
45	Carbon (C) - organic	OrgC_dc-lt-loi	g/kg	0	1000
46	Carbon (C) - organic	OrgC_dc-mt	g/kg	0	1000
47	Carbon (C) - organic	OrgC_dc-spec	g/kg	0	1000
48	Carbon (C) - organic	OrgC_wc	g/kg	0	1000
49	Carbon (C) - organic	OrgC_wc-cro3-jackson	g/kg	0	1000
50	Carbon (C) - organic	OrgC_wc-cro3-kalembra	g/kg	0	1000
51	Carbon (C) - organic	OrgC_wc-cro3-knopp	g/kg	0	1000
52	Carbon (C) - organic	OrgC_wc-cro3-kurmies	g/kg	0	1000
53	Carbon (C) - organic	OrgC_wc-cro3-nelson	g/kg	0	1000
13	bulkDensityFineEarthProperty	BlkDensF_fe-cl-fc	kg/dm³	0.01	2.65
14	bulkDensityFineEarthProperty	BlkDensF_fe-cl-od	kg/dm³	0.01	2.65
15	bulkDensityFineEarthProperty	BlkDensF_fe-cl-unkn	kg/dm³	0.01	2.65
16	bulkDensityFineEarthProperty	BlkDensF_fe-co-fc	kg/dm³	0.01	2.65
17	bulkDensityFineEarthProperty	BlkDensF_fe-co-od	kg/dm³	0.01	2.65
18	bulkDensityFineEarthProperty	BlkDensF_fe-co-unkn	kg/dm³	0.01	2.65
19	bulkDensityFineEarthProperty	BlkDensF_fe-rpl-unkn	kg/dm³	0.01	2.65
20	bulkDensityFineEarthProperty	BlkDensF_fe-unkn	kg/dm³	0.01	2.65
21	bulkDensityFineEarthProperty	BlkDensF_fe-unkn-fc	kg/dm³	0.01	2.65
22	bulkDensityFineEarthProperty	BlkDensF_fe-unkn-od	kg/dm³	0.01	2.65
1	Acidity - exchangeable	ExchAcid_ph0-kcl1m	cmol/kg	0	100
2	Acidity - exchangeable	ExchAcid_ph0-nh4cl	cmol/kg	0	100
3	Acidity - exchangeable	ExchAcid_ph0-unkn	cmol/kg	0	100
4	Acidity - exchangeable	ExchAcid_ph7-caoac	cmol/kg	0	100
5	Acidity - exchangeable	ExchAcid_ph7-unkn	cmol/kg	0	100
6	Acidity - exchangeable	ExchAcid_ph8-bacl2tea	cmol/kg	0	100
7	Acidity - exchangeable	ExchAcid_ph8-unkn	cmol/kg	0	100
95	Hydrogen (H+) - exchangeable	ExchBases_ph-unkn-edta	cmol/kg	0	100
65	effectiveCecProperty	EffCEC_calcul-b	cmol/kg	0	100
66	effectiveCecProperty	EffCEC_calcul-ba	cmol/kg	0	100
23	bulkDensityWholeSoilProperty	BlkDensW_we-cl-fc	kg/dm³	0.01	3.6
24	bulkDensityWholeSoilProperty	BlkDensW_we-cl-od	kg/dm³	0.01	3.6
25	bulkDensityWholeSoilProperty	BlkDensW_we-cl-unkn	kg/dm³	0.01	3.6
26	bulkDensityWholeSoilProperty	BlkDensW_we-co-fc	kg/dm³	0.01	3.6
27	bulkDensityWholeSoilProperty	BlkDensW_we-co-od	kg/dm³	0.01	3.6
28	bulkDensityWholeSoilProperty	BlkDensW_we-co-unkn	kg/dm³	0.01	3.6
29	bulkDensityWholeSoilProperty	BlkDensW_we-rpl-unkn	kg/dm³	0.01	3.6
30	bulkDensityWholeSoilProperty	BlkDensW_we-unkn	kg/dm³	0.01	3.6
73	manganeseProperty	ExchBases_ph-unkn-edta	cmol/kg	0	1000
139	Magnesium (Mg++) - exchangeable	ExchBases_ph-unkn-edta	cmol/kg	0	100
106	Potassium (K+) - exchangeable	ExchBases_ph-unkn-edta	cmol/kg	0	100
117	Aluminium (Al+++) - exchangeable	ExchBases_ph-unkn-edta	cmol/kg	0	100
84	Sodium (Na+) - exchangeable	ExchBases_ph-unkn-edta	cmol/kg	0	100
251	Magnesium (Mg) - extractable	Extr_ap15	cmol/kg	0	1000
151	Manganese (Mn) - extractable	Extr_ap15	cmol/kg	0	1000
226	Potassium (K) - extractable	Extr_ap15	cmol/kg	0	1000
376	Sodium (Na) - extractable	Extr_ap15	cmol/kg	0	1000
326	Calcium (Ca++) - extractable	Extr_ap15	cmol/kg	0	1000
252	Magnesium (Mg) - extractable	Extr_ap20	cmol/kg	0	1000
152	Manganese (Mn) - extractable	Extr_ap20	cmol/kg	0	1000
227	Potassium (K) - extractable	Extr_ap20	cmol/kg	0	1000
377	Sodium (Na) - extractable	Extr_ap20	cmol/kg	0	1000
327	Calcium (Ca++) - extractable	Extr_ap20	cmol/kg	0	1000
253	Magnesium (Mg) - extractable	Extr_ap21	cmol/kg	0	1000
153	Manganese (Mn) - extractable	Extr_ap21	cmol/kg	0	1000
228	Potassium (K) - extractable	Extr_ap21	cmol/kg	0	1000
378	Sodium (Na) - extractable	Extr_ap21	cmol/kg	0	1000
328	Calcium (Ca++) - extractable	Extr_ap21	cmol/kg	0	1000
254	Magnesium (Mg) - extractable	Extr_c6h8o7-reeuwijk	cmol/kg	0	1000
154	Manganese (Mn) - extractable	Extr_c6h8o7-reeuwijk	cmol/kg	0	1000
229	Potassium (K) - extractable	Extr_c6h8o7-reeuwijk	cmol/kg	0	1000
379	Sodium (Na) - extractable	Extr_c6h8o7-reeuwijk	cmol/kg	0	1000
329	Calcium (Ca++) - extractable	Extr_c6h8o7-reeuwijk	cmol/kg	0	1000
255	Magnesium (Mg) - extractable	Extr_cacl2	cmol/kg	0	1000
155	Manganese (Mn) - extractable	Extr_cacl2	cmol/kg	0	1000
230	Potassium (K) - extractable	Extr_cacl2	cmol/kg	0	1000
380	Sodium (Na) - extractable	Extr_cacl2	cmol/kg	0	1000
330	Calcium (Ca++) - extractable	Extr_cacl2	cmol/kg	0	1000
256	Magnesium (Mg) - extractable	Extr_capo4	cmol/kg	0	1000
156	Manganese (Mn) - extractable	Extr_capo4	cmol/kg	0	1000
231	Potassium (K) - extractable	Extr_capo4	cmol/kg	0	1000
381	Sodium (Na) - extractable	Extr_capo4	cmol/kg	0	1000
331	Calcium (Ca++) - extractable	Extr_capo4	cmol/kg	0	1000
257	Magnesium (Mg) - extractable	Extr_dtpa	cmol/kg	0	1000
157	Manganese (Mn) - extractable	Extr_dtpa	cmol/kg	0	1000
232	Potassium (K) - extractable	Extr_dtpa	cmol/kg	0	1000
382	Sodium (Na) - extractable	Extr_dtpa	cmol/kg	0	1000
332	Calcium (Ca++) - extractable	Extr_dtpa	cmol/kg	0	1000
258	Magnesium (Mg) - extractable	Extr_edta	cmol/kg	0	1000
158	Manganese (Mn) - extractable	Extr_edta	cmol/kg	0	1000
233	Potassium (K) - extractable	Extr_edta	cmol/kg	0	1000
383	Sodium (Na) - extractable	Extr_edta	cmol/kg	0	1000
333	Calcium (Ca++) - extractable	Extr_edta	cmol/kg	0	1000
259	Magnesium (Mg) - extractable	Extr_h2so4-truog	cmol/kg	0	1000
159	Manganese (Mn) - extractable	Extr_h2so4-truog	cmol/kg	0	1000
234	Potassium (K) - extractable	Extr_h2so4-truog	cmol/kg	0	1000
384	Sodium (Na) - extractable	Extr_h2so4-truog	cmol/kg	0	1000
334	Calcium (Ca++) - extractable	Extr_h2so4-truog	cmol/kg	0	1000
260	Magnesium (Mg) - extractable	Extr_hcl-h2so4-nelson	cmol/kg	0	1000
160	Manganese (Mn) - extractable	Extr_hcl-h2so4-nelson	cmol/kg	0	1000
235	Potassium (K) - extractable	Extr_hcl-h2so4-nelson	cmol/kg	0	1000
385	Sodium (Na) - extractable	Extr_hcl-h2so4-nelson	cmol/kg	0	1000
335	Calcium (Ca++) - extractable	Extr_hcl-h2so4-nelson	cmol/kg	0	1000
261	Magnesium (Mg) - extractable	Extr_hcl-nh4f-bray1	cmol/kg	0	1000
161	Manganese (Mn) - extractable	Extr_hcl-nh4f-bray1	cmol/kg	0	1000
236	Potassium (K) - extractable	Extr_hcl-nh4f-bray1	cmol/kg	0	1000
386	Sodium (Na) - extractable	Extr_hcl-nh4f-bray1	cmol/kg	0	1000
336	Calcium (Ca++) - extractable	Extr_hcl-nh4f-bray1	cmol/kg	0	1000
262	Magnesium (Mg) - extractable	Extr_hcl-nh4f-bray2	cmol/kg	0	1000
162	Manganese (Mn) - extractable	Extr_hcl-nh4f-bray2	cmol/kg	0	1000
237	Potassium (K) - extractable	Extr_hcl-nh4f-bray2	cmol/kg	0	1000
387	Sodium (Na) - extractable	Extr_hcl-nh4f-bray2	cmol/kg	0	1000
337	Calcium (Ca++) - extractable	Extr_hcl-nh4f-bray2	cmol/kg	0	1000
263	Magnesium (Mg) - extractable	Extr_hcl-nh4f-kurtz-bray	cmol/kg	0	1000
163	Manganese (Mn) - extractable	Extr_hcl-nh4f-kurtz-bray	cmol/kg	0	1000
238	Potassium (K) - extractable	Extr_hcl-nh4f-kurtz-bray	cmol/kg	0	1000
388	Sodium (Na) - extractable	Extr_hcl-nh4f-kurtz-bray	cmol/kg	0	1000
338	Calcium (Ca++) - extractable	Extr_hcl-nh4f-kurtz-bray	cmol/kg	0	1000
264	Magnesium (Mg) - extractable	Extr_hno3	cmol/kg	0	1000
164	Manganese (Mn) - extractable	Extr_hno3	cmol/kg	0	1000
239	Potassium (K) - extractable	Extr_hno3	cmol/kg	0	1000
389	Sodium (Na) - extractable	Extr_hno3	cmol/kg	0	1000
339	Calcium (Ca++) - extractable	Extr_hno3	cmol/kg	0	1000
265	Magnesium (Mg) - extractable	Extr_hotwater	cmol/kg	0	1000
165	Manganese (Mn) - extractable	Extr_hotwater	cmol/kg	0	1000
240	Potassium (K) - extractable	Extr_hotwater	cmol/kg	0	1000
390	Sodium (Na) - extractable	Extr_hotwater	cmol/kg	0	1000
340	Calcium (Ca++) - extractable	Extr_hotwater	cmol/kg	0	1000
266	Magnesium (Mg) - extractable	Extr_m1	cmol/kg	0	1000
166	Manganese (Mn) - extractable	Extr_m1	cmol/kg	0	1000
241	Potassium (K) - extractable	Extr_m1	cmol/kg	0	1000
391	Sodium (Na) - extractable	Extr_m1	cmol/kg	0	1000
341	Calcium (Ca++) - extractable	Extr_m1	cmol/kg	0	1000
267	Magnesium (Mg) - extractable	Extr_m2	cmol/kg	0	1000
167	Manganese (Mn) - extractable	Extr_m2	cmol/kg	0	1000
242	Potassium (K) - extractable	Extr_m2	cmol/kg	0	1000
392	Sodium (Na) - extractable	Extr_m2	cmol/kg	0	1000
342	Calcium (Ca++) - extractable	Extr_m2	cmol/kg	0	1000
268	Magnesium (Mg) - extractable	Extr_m3	cmol/kg	0	1000
168	Manganese (Mn) - extractable	Extr_m3	cmol/kg	0	1000
243	Potassium (K) - extractable	Extr_m3	cmol/kg	0	1000
393	Sodium (Na) - extractable	Extr_m3	cmol/kg	0	1000
343	Calcium (Ca++) - extractable	Extr_m3	cmol/kg	0	1000
269	Magnesium (Mg) - extractable	Extr_m3-spec	cmol/kg	0	1000
169	Manganese (Mn) - extractable	Extr_m3-spec	cmol/kg	0	1000
244	Potassium (K) - extractable	Extr_m3-spec	cmol/kg	0	1000
394	Sodium (Na) - extractable	Extr_m3-spec	cmol/kg	0	1000
344	Calcium (Ca++) - extractable	Extr_m3-spec	cmol/kg	0	1000
270	Magnesium (Mg) - extractable	Extr_nahco3-olsen	cmol/kg	0	1000
170	Manganese (Mn) - extractable	Extr_nahco3-olsen	cmol/kg	0	1000
245	Potassium (K) - extractable	Extr_nahco3-olsen	cmol/kg	0	1000
395	Sodium (Na) - extractable	Extr_nahco3-olsen	cmol/kg	0	1000
345	Calcium (Ca++) - extractable	Extr_nahco3-olsen	cmol/kg	0	1000
271	Magnesium (Mg) - extractable	Extr_nahco3-olsen-dabin	cmol/kg	0	1000
171	Manganese (Mn) - extractable	Extr_nahco3-olsen-dabin	cmol/kg	0	1000
246	Potassium (K) - extractable	Extr_nahco3-olsen-dabin	cmol/kg	0	1000
396	Sodium (Na) - extractable	Extr_nahco3-olsen-dabin	cmol/kg	0	1000
346	Calcium (Ca++) - extractable	Extr_nahco3-olsen-dabin	cmol/kg	0	1000
272	Magnesium (Mg) - extractable	Extr_naoac-morgan	cmol/kg	0	1000
172	Manganese (Mn) - extractable	Extr_naoac-morgan	cmol/kg	0	1000
247	Potassium (K) - extractable	Extr_naoac-morgan	cmol/kg	0	1000
397	Sodium (Na) - extractable	Extr_naoac-morgan	cmol/kg	0	1000
347	Calcium (Ca++) - extractable	Extr_naoac-morgan	cmol/kg	0	1000
273	Magnesium (Mg) - extractable	Extr_nh4-co3-2-ambic1	cmol/kg	0	1000
173	Manganese (Mn) - extractable	Extr_nh4-co3-2-ambic1	cmol/kg	0	1000
248	Potassium (K) - extractable	Extr_nh4-co3-2-ambic1	cmol/kg	0	1000
398	Sodium (Na) - extractable	Extr_nh4-co3-2-ambic1	cmol/kg	0	1000
348	Calcium (Ca++) - extractable	Extr_nh4-co3-2-ambic1	cmol/kg	0	1000
274	Magnesium (Mg) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	cmol/kg	0	1000
174	Manganese (Mn) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	cmol/kg	0	1000
249	Potassium (K) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	cmol/kg	0	1000
399	Sodium (Na) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	cmol/kg	0	1000
299	Sulfur (S) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	%	0	100
424	Zinc (Zn) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	%	0	100
449	cadmiumProperty	Extr_nh4ch3ch-oh-cooh-leuven	%	0	100
224	molybdenumProperty	Extr_nh4ch3ch-oh-cooh-leuven	%	0	100
482	hydraulicConductivityProperty	KSat_calcul-ptf	cm/h	0	100
483	hydraulicConductivityProperty	KSat_calcul-ptf-genuchten	cm/h	0	100
484	hydraulicConductivityProperty	KSat_calcul-ptf-saxton	cm/h	0	100
485	hydraulicConductivityProperty	Ksat_bhole	cm/h	0	100
486	hydraulicConductivityProperty	Ksat_column	cm/h	0	100
487	hydraulicConductivityProperty	Ksat_dblring	cm/h	0	100
488	hydraulicConductivityProperty	Ksat_invbhole	cm/h	0	100
565	Phosphorus (P) - retention	RetentP_blakemore	g/hg	0	100
566	Phosphorus (P) - retention	RetentP_unkn-spec	g/hg	0	100
567	porosityProperty	Poros_calcul-pf0	m³/100 m³	0	100
489	Nitrogen (N) - total	TotalN_bremner	g/kg	0	1000
490	Nitrogen (N) - total	TotalN_calcul	g/kg	0	1000
491	Nitrogen (N) - total	TotalN_calcul-oc10	g/kg	0	1000
492	Nitrogen (N) - total	TotalN_dc	g/kg	0	1000
496	Nitrogen (N) - total	TotalN_h2so4	g/kg	0	1000
497	Nitrogen (N) - total	TotalN_kjeldahl	g/kg	0	1000
498	Nitrogen (N) - total	TotalN_kjeldahl-nh4	g/kg	0	1000
499	Nitrogen (N) - total	TotalN_nelson	g/kg	0	1000
500	Nitrogen (N) - total	TotalN_tn04	g/kg	0	1000
501	Nitrogen (N) - total	TotalN_tn06	g/kg	0	1000
502	Nitrogen (N) - total	TotalN_tn08	g/kg	0	1000
503	organicMatterProperty	FulAcidC_unkn	g/kg	0	1000
504	organicMatterProperty	HumAcidC_unkn	g/kg	0	1000
505	organicMatterProperty	OrgM_calcul-oc1.73	g/kg	0	1000
506	organicMatterProperty	TotHumC_unkn	g/kg	0	1000
568	solubleSaltsProperty	SlbAn_calcul-unkn	cmol/L	0	1000
569	solubleSaltsProperty	SlbCat_calcul-unkn	cmol/L	0	1000
349	Calcium (Ca++) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	cmol/kg	0	1000
951	Calcium (Ca++) - total	Total_h2so4	cmol/kg	0	1000
761	Magnesium (Mg) - total	Total_h2so4	cmol/kg	0	1000
989	Manganese (Mn) - total	Total_h2so4	cmol/kg	0	1000
742	Potassium (K) - total	Total_h2so4	cmol/kg	0	1000
970	Sodium (Na) - total	Total_h2so4	cmol/kg	0	1000
952	Calcium (Ca++) - total	Total_hcl	cmol/kg	0	1000
762	Magnesium (Mg) - total	Total_hcl	cmol/kg	0	1000
990	Manganese (Mn) - total	Total_hcl	cmol/kg	0	1000
743	Potassium (K) - total	Total_hcl	cmol/kg	0	1000
971	Sodium (Na) - total	Total_hcl	cmol/kg	0	1000
953	Calcium (Ca++) - total	Total_hcl-aquaregia	cmol/kg	0	1000
763	Magnesium (Mg) - total	Total_hcl-aquaregia	cmol/kg	0	1000
991	Manganese (Mn) - total	Total_hcl-aquaregia	cmol/kg	0	1000
744	Potassium (K) - total	Total_hcl-aquaregia	cmol/kg	0	1000
972	Sodium (Na) - total	Total_hcl-aquaregia	cmol/kg	0	1000
954	Calcium (Ca++) - total	Total_hclo4	cmol/kg	0	1000
764	Magnesium (Mg) - total	Total_hclo4	cmol/kg	0	1000
992	Manganese (Mn) - total	Total_hclo4	cmol/kg	0	1000
745	Potassium (K) - total	Total_hclo4	cmol/kg	0	1000
973	Sodium (Na) - total	Total_hclo4	cmol/kg	0	1000
955	Calcium (Ca++) - total	Total_hno3-aquafortis	cmol/kg	0	1000
765	Magnesium (Mg) - total	Total_hno3-aquafortis	cmol/kg	0	1000
993	Manganese (Mn) - total	Total_hno3-aquafortis	cmol/kg	0	1000
746	Potassium (K) - total	Total_hno3-aquafortis	cmol/kg	0	1000
974	Sodium (Na) - total	Total_hno3-aquafortis	cmol/kg	0	1000
956	Calcium (Ca++) - total	Total_nh4-6mo7o24	cmol/kg	0	1000
766	Magnesium (Mg) - total	Total_nh4-6mo7o24	cmol/kg	0	1000
994	Manganese (Mn) - total	Total_nh4-6mo7o24	cmol/kg	0	1000
747	Potassium (K) - total	Total_nh4-6mo7o24	cmol/kg	0	1000
975	Sodium (Na) - total	Total_nh4-6mo7o24	cmol/kg	0	1000
957	Calcium (Ca++) - total	Total_tp03	cmol/kg	0	1000
767	Magnesium (Mg) - total	Total_tp03	cmol/kg	0	1000
995	Manganese (Mn) - total	Total_tp03	cmol/kg	0	1000
748	Potassium (K) - total	Total_tp03	cmol/kg	0	1000
976	Sodium (Na) - total	Total_tp03	cmol/kg	0	1000
958	Calcium (Ca++) - total	Total_tp04	cmol/kg	0	1000
768	Magnesium (Mg) - total	Total_tp04	cmol/kg	0	1000
996	Manganese (Mn) - total	Total_tp04	cmol/kg	0	1000
749	Potassium (K) - total	Total_tp04	cmol/kg	0	1000
977	Sodium (Na) - total	Total_tp04	cmol/kg	0	1000
959	Calcium (Ca++) - total	Total_tp05	cmol/kg	0	1000
769	Magnesium (Mg) - total	Total_tp05	cmol/kg	0	1000
997	Manganese (Mn) - total	Total_tp05	cmol/kg	0	1000
750	Potassium (K) - total	Total_tp05	cmol/kg	0	1000
978	Sodium (Na) - total	Total_tp05	cmol/kg	0	1000
960	Calcium (Ca++) - total	Total_tp06	cmol/kg	0	1000
770	Magnesium (Mg) - total	Total_tp06	cmol/kg	0	1000
998	Manganese (Mn) - total	Total_tp06	cmol/kg	0	1000
751	Potassium (K) - total	Total_tp06	cmol/kg	0	1000
979	Sodium (Na) - total	Total_tp06	cmol/kg	0	1000
961	Calcium (Ca++) - total	Total_tp07	cmol/kg	0	1000
771	Magnesium (Mg) - total	Total_tp07	cmol/kg	0	1000
999	Manganese (Mn) - total	Total_tp07	cmol/kg	0	1000
752	Potassium (K) - total	Total_tp07	cmol/kg	0	1000
980	Sodium (Na) - total	Total_tp07	cmol/kg	0	1000
962	Calcium (Ca++) - total	Total_tp08	cmol/kg	0	1000
772	Magnesium (Mg) - total	Total_tp08	cmol/kg	0	1000
1000	Manganese (Mn) - total	Total_tp08	cmol/kg	0	1000
753	Potassium (K) - total	Total_tp08	cmol/kg	0	1000
981	Sodium (Na) - total	Total_tp08	cmol/kg	0	1000
963	Calcium (Ca++) - total	Total_tp09	cmol/kg	0	1000
773	Magnesium (Mg) - total	Total_tp09	cmol/kg	0	1000
1001	Manganese (Mn) - total	Total_tp09	cmol/kg	0	1000
754	Potassium (K) - total	Total_tp09	cmol/kg	0	1000
982	Sodium (Na) - total	Total_tp09	cmol/kg	0	1000
964	Calcium (Ca++) - total	Total_tp10	cmol/kg	0	1000
774	Magnesium (Mg) - total	Total_tp10	cmol/kg	0	1000
1002	Manganese (Mn) - total	Total_tp10	cmol/kg	0	1000
755	Potassium (K) - total	Total_tp10	cmol/kg	0	1000
983	Sodium (Na) - total	Total_tp10	cmol/kg	0	1000
965	Calcium (Ca++) - total	Total_unkn	cmol/kg	0	1000
775	Magnesium (Mg) - total	Total_unkn	cmol/kg	0	1000
1003	Manganese (Mn) - total	Total_unkn	cmol/kg	0	1000
756	Potassium (K) - total	Total_unkn	cmol/kg	0	1000
984	Sodium (Na) - total	Total_unkn	cmol/kg	0	1000
966	Calcium (Ca++) - total	Total_xrd	cmol/kg	0	1000
776	Magnesium (Mg) - total	Total_xrd	cmol/kg	0	1000
1004	Manganese (Mn) - total	Total_xrd	cmol/kg	0	1000
757	Potassium (K) - total	Total_xrd	cmol/kg	0	1000
985	Sodium (Na) - total	Total_xrd	cmol/kg	0	1000
967	Calcium (Ca++) - total	Total_xrf	cmol/kg	0	1000
777	Magnesium (Mg) - total	Total_xrf	cmol/kg	0	1000
1005	Manganese (Mn) - total	Total_xrf	cmol/kg	0	1000
758	Potassium (K) - total	Total_xrf	cmol/kg	0	1000
986	Sodium (Na) - total	Total_xrf	cmol/kg	0	1000
968	Calcium (Ca++) - total	Total_xrf-p	cmol/kg	0	1000
778	Magnesium (Mg) - total	Total_xrf-p	cmol/kg	0	1000
1006	Manganese (Mn) - total	Total_xrf-p	cmol/kg	0	1000
759	Potassium (K) - total	Total_xrf-p	cmol/kg	0	1000
987	Sodium (Na) - total	Total_xrf-p	cmol/kg	0	1000
549	pHProperty	pHH2O_sat	pH	1.5	13
521	pH - Hydrogen potential	pHH2O_unkn-spec	pH	1.5	13
550	pHProperty	pHH2O_unkn-spec	pH	1.5	13
523	pH - Hydrogen potential	pHKCl_ratio1-1	pH	1.5	13
552	pHProperty	pHKCl_ratio1-1	pH	1.5	13
524	pH - Hydrogen potential	pHKCl_ratio1-10	pH	1.5	13
553	pHProperty	pHKCl_ratio1-10	pH	1.5	13
525	pH - Hydrogen potential	pHKCl_ratio1-2	pH	1.5	13
554	pHProperty	pHKCl_ratio1-2	pH	1.5	13
526	pH - Hydrogen potential	pHKCl_ratio1-2.5	pH	1.5	13
555	pHProperty	pHKCl_ratio1-2.5	pH	1.5	13
527	pH - Hydrogen potential	pHKCl_ratio1-5	pH	1.5	13
556	pHProperty	pHKCl_ratio1-5	pH	1.5	13
530	pH - Hydrogen potential	pHNaF_ratio1-1	pH	1.5	13
559	pHProperty	pHNaF_ratio1-1	pH	1.5	13
531	pH - Hydrogen potential	pHNaF_ratio1-10	pH	1.5	13
560	pHProperty	pHNaF_ratio1-10	pH	1.5	13
532	pH - Hydrogen potential	pHNaF_ratio1-2	pH	1.5	13
561	pHProperty	pHNaF_ratio1-2	pH	1.5	13
533	pH - Hydrogen potential	pHNaF_ratio1-2.5	pH	1.5	13
562	pHProperty	pHNaF_ratio1-2.5	pH	1.5	13
534	pH - Hydrogen potential	pHNaF_ratio1-5	pH	1.5	13
563	pHProperty	pHNaF_ratio1-5	pH	1.5	13
535	pH - Hydrogen potential	pHNaF_sat	pH	1.5	13
564	pHProperty	pHNaF_sat	pH	1.5	13
507	pH - Hydrogen potential	pHCaCl2	pH	1.5	13
536	pHProperty	pHCaCl2	pH	1.5	13
522	pH - Hydrogen potential	pHKCl	pH	1.5	13
551	pHProperty	pHKCl	pH	1.5	13
528	pH - Hydrogen potential	pHKCl_sat	pH	1.5	13
557	pHProperty	pHKCl_sat	pH	1.5	13
529	pH - Hydrogen potential	pHNaF	pH	1.5	13
558	pHProperty	pHNaF	pH	1.5	13
67	electricalConductivityProperty	EC_ratio1-1	dS/m	0	60
68	electricalConductivityProperty	EC_ratio1-10	dS/m	0	60
70	electricalConductivityProperty	EC_ratio1-2.5	dS/m	0	60
71	electricalConductivityProperty	EC_ratio1-5	dS/m	0	60
72	electricalConductivityProperty	ECe_sat	dS/m	0	60
627	Clay texture fraction	SaSiCl_2-20-2000u-fld	%	0	100
579	Sand texture fraction	SaSiCl_2-20-2000u-fld	%	0	100
675	Silt texture fraction	SaSiCl_2-20-2000u-fld	%	0	100
628	Clay texture fraction	SaSiCl_2-20-2000u-nodisp	%	0	100
580	Sand texture fraction	SaSiCl_2-20-2000u-nodisp	%	0	100
676	Silt texture fraction	SaSiCl_2-20-2000u-nodisp	%	0	100
629	Clay texture fraction	SaSiCl_2-20-2000u-nodisp-hydrometer	%	0	100
581	Sand texture fraction	SaSiCl_2-20-2000u-nodisp-hydrometer	%	0	100
677	Silt texture fraction	SaSiCl_2-20-2000u-nodisp-hydrometer	%	0	100
630	Clay texture fraction	SaSiCl_2-20-2000u-nodisp-hydrometer-bouy	%	0	100
582	Sand texture fraction	SaSiCl_2-20-2000u-nodisp-hydrometer-bouy	%	0	100
678	Silt texture fraction	SaSiCl_2-20-2000u-nodisp-hydrometer-bouy	%	0	100
631	Clay texture fraction	SaSiCl_2-20-2000u-nodisp-laser	%	0	100
583	Sand texture fraction	SaSiCl_2-20-2000u-nodisp-laser	%	0	100
679	Silt texture fraction	SaSiCl_2-20-2000u-nodisp-laser	%	0	100
632	Clay texture fraction	SaSiCl_2-20-2000u-nodisp-pipette	%	0	100
584	Sand texture fraction	SaSiCl_2-20-2000u-nodisp-pipette	%	0	100
680	Silt texture fraction	SaSiCl_2-20-2000u-nodisp-pipette	%	0	100
633	Clay texture fraction	SaSiCl_2-20-2000u-nodisp-spec	%	0	100
585	Sand texture fraction	SaSiCl_2-20-2000u-nodisp-spec	%	0	100
681	Silt texture fraction	SaSiCl_2-20-2000u-nodisp-spec	%	0	100
636	Clay texture fraction	SaSiCl_2-50-2000u-disp	%	0	100
588	Sand texture fraction	SaSiCl_2-50-2000u-disp	%	0	100
684	Silt texture fraction	SaSiCl_2-50-2000u-disp	%	0	100
637	Clay texture fraction	SaSiCl_2-50-2000u-disp-beaker	%	0	100
589	Sand texture fraction	SaSiCl_2-50-2000u-disp-beaker	%	0	100
685	Silt texture fraction	SaSiCl_2-50-2000u-disp-beaker	%	0	100
638	Clay texture fraction	SaSiCl_2-50-2000u-disp-hydrometer	%	0	100
590	Sand texture fraction	SaSiCl_2-50-2000u-disp-hydrometer	%	0	100
686	Silt texture fraction	SaSiCl_2-50-2000u-disp-hydrometer	%	0	100
639	Clay texture fraction	SaSiCl_2-50-2000u-disp-hydrometer-bouy	%	0	100
591	Sand texture fraction	SaSiCl_2-50-2000u-disp-hydrometer-bouy	%	0	100
687	Silt texture fraction	SaSiCl_2-50-2000u-disp-hydrometer-bouy	%	0	100
640	Clay texture fraction	SaSiCl_2-50-2000u-disp-laser	%	0	100
592	Sand texture fraction	SaSiCl_2-50-2000u-disp-laser	%	0	100
688	Silt texture fraction	SaSiCl_2-50-2000u-disp-laser	%	0	100
641	Clay texture fraction	SaSiCl_2-50-2000u-disp-pipette	%	0	100
593	Sand texture fraction	SaSiCl_2-50-2000u-disp-pipette	%	0	100
873	zincProperty	Total_xrf-p	%	0	100
969	Calcium (Ca++) - total	Total_xtf-t	cmol/kg	0	1000
779	Magnesium (Mg) - total	Total_xtf-t	cmol/kg	0	1000
1007	Manganese (Mn) - total	Total_xtf-t	cmol/kg	0	1000
760	Potassium (K) - total	Total_xtf-t	cmol/kg	0	1000
988	Sodium (Na) - total	Total_xtf-t	cmol/kg	0	1000
689	Silt texture fraction	SaSiCl_2-50-2000u-disp-pipette	%	0	100
642	Clay texture fraction	SaSiCl_2-50-2000u-disp-spec	%	0	100
594	Sand texture fraction	SaSiCl_2-50-2000u-disp-spec	%	0	100
690	Silt texture fraction	SaSiCl_2-50-2000u-disp-spec	%	0	100
643	Clay texture fraction	SaSiCl_2-50-2000u-fld	%	0	100
595	Sand texture fraction	SaSiCl_2-50-2000u-fld	%	0	100
691	Silt texture fraction	SaSiCl_2-50-2000u-fld	%	0	100
644	Clay texture fraction	SaSiCl_2-50-2000u-nodisp	%	0	100
596	Sand texture fraction	SaSiCl_2-50-2000u-nodisp	%	0	100
692	Silt texture fraction	SaSiCl_2-50-2000u-nodisp	%	0	100
645	Clay texture fraction	SaSiCl_2-50-2000u-nodisp-hydrometer	%	0	100
597	Sand texture fraction	SaSiCl_2-50-2000u-nodisp-hydrometer	%	0	100
693	Silt texture fraction	SaSiCl_2-50-2000u-nodisp-hydrometer	%	0	100
646	Clay texture fraction	SaSiCl_2-50-2000u-nodisp-hydrometer-bouy	%	0	100
598	Sand texture fraction	SaSiCl_2-50-2000u-nodisp-hydrometer-bouy	%	0	100
694	Silt texture fraction	SaSiCl_2-50-2000u-nodisp-hydrometer-bouy	%	0	100
647	Clay texture fraction	SaSiCl_2-50-2000u-nodisp-laser	%	0	100
599	Sand texture fraction	SaSiCl_2-50-2000u-nodisp-laser	%	0	100
695	Silt texture fraction	SaSiCl_2-50-2000u-nodisp-laser	%	0	100
648	Clay texture fraction	SaSiCl_2-50-2000u-nodisp-pipette	%	0	100
600	Sand texture fraction	SaSiCl_2-50-2000u-nodisp-pipette	%	0	100
696	Silt texture fraction	SaSiCl_2-50-2000u-nodisp-pipette	%	0	100
649	Clay texture fraction	SaSiCl_2-50-2000u-nodisp-spec	%	0	100
601	Sand texture fraction	SaSiCl_2-50-2000u-nodisp-spec	%	0	100
697	Silt texture fraction	SaSiCl_2-50-2000u-nodisp-spec	%	0	100
651	Clay texture fraction	SaSiCl_2-64-2000u-adj100	%	0	100
603	Sand texture fraction	SaSiCl_2-64-2000u-adj100	%	0	100
699	Silt texture fraction	SaSiCl_2-64-2000u-adj100	%	0	100
652	Clay texture fraction	SaSiCl_2-64-2000u-disp	%	0	100
604	Sand texture fraction	SaSiCl_2-64-2000u-disp	%	0	100
700	Silt texture fraction	SaSiCl_2-64-2000u-disp	%	0	100
653	Clay texture fraction	SaSiCl_2-64-2000u-disp-beaker	%	0	100
605	Sand texture fraction	SaSiCl_2-64-2000u-disp-beaker	%	0	100
701	Silt texture fraction	SaSiCl_2-64-2000u-disp-beaker	%	0	100
654	Clay texture fraction	SaSiCl_2-64-2000u-disp-hydrometer	%	0	100
606	Sand texture fraction	SaSiCl_2-64-2000u-disp-hydrometer	%	0	100
702	Silt texture fraction	SaSiCl_2-64-2000u-disp-hydrometer	%	0	100
655	Clay texture fraction	SaSiCl_2-64-2000u-disp-hydrometer-bouy	%	0	100
607	Sand texture fraction	SaSiCl_2-64-2000u-disp-hydrometer-bouy	%	0	100
703	Silt texture fraction	SaSiCl_2-64-2000u-disp-hydrometer-bouy	%	0	100
656	Clay texture fraction	SaSiCl_2-64-2000u-disp-laser	%	0	100
608	Sand texture fraction	SaSiCl_2-64-2000u-disp-laser	%	0	100
704	Silt texture fraction	SaSiCl_2-64-2000u-disp-laser	%	0	100
657	Clay texture fraction	SaSiCl_2-64-2000u-disp-pipette	%	0	100
609	Sand texture fraction	SaSiCl_2-64-2000u-disp-pipette	%	0	100
705	Silt texture fraction	SaSiCl_2-64-2000u-disp-pipette	%	0	100
658	Clay texture fraction	SaSiCl_2-64-2000u-disp-spec	%	0	100
610	Sand texture fraction	SaSiCl_2-64-2000u-disp-spec	%	0	100
351	Iron (Fe) - extractable	Extr_ap15	%	0	100
660	Clay texture fraction	SaSiCl_2-64-2000u-nodisp	%	0	100
612	Sand texture fraction	SaSiCl_2-64-2000u-nodisp	%	0	100
708	Silt texture fraction	SaSiCl_2-64-2000u-nodisp	%	0	100
661	Clay texture fraction	SaSiCl_2-64-2000u-nodisp-hydrometer	%	0	100
613	Sand texture fraction	SaSiCl_2-64-2000u-nodisp-hydrometer	%	0	100
709	Silt texture fraction	SaSiCl_2-64-2000u-nodisp-hydrometer	%	0	100
662	Clay texture fraction	SaSiCl_2-64-2000u-nodisp-hydrometer-bouy	%	0	100
614	Sand texture fraction	SaSiCl_2-64-2000u-nodisp-hydrometer-bouy	%	0	100
710	Silt texture fraction	SaSiCl_2-64-2000u-nodisp-hydrometer-bouy	%	0	100
663	Clay texture fraction	SaSiCl_2-64-2000u-nodisp-laser	%	0	100
615	Sand texture fraction	SaSiCl_2-64-2000u-nodisp-laser	%	0	100
711	Silt texture fraction	SaSiCl_2-64-2000u-nodisp-laser	%	0	100
664	Clay texture fraction	SaSiCl_2-64-2000u-nodisp-pipette	%	0	100
616	Sand texture fraction	SaSiCl_2-64-2000u-nodisp-pipette	%	0	100
712	Silt texture fraction	SaSiCl_2-64-2000u-nodisp-pipette	%	0	100
665	Clay texture fraction	SaSiCl_2-64-2000u-nodisp-spec	%	0	100
617	Sand texture fraction	SaSiCl_2-64-2000u-nodisp-spec	%	0	100
713	Silt texture fraction	SaSiCl_2-64-2000u-nodisp-spec	%	0	100
11	Base saturation - calculated	BSat_calcul-cec	%	0	100
12	Base saturation - calculated	BSat_calcul-ecec	%	0	100
62	coarseFragmentsProperty	CrsFrg_fld	%	0	100
63	coarseFragmentsProperty	CrsFrg_fldcls	%	0	100
64	coarseFragmentsProperty	CrsFrg_lab	%	0	100
191	Boron (B) - extractable	Extr_m1	%	0	100
300	Copper (Cu) - extractable	Extr_ap14	%	0	100
350	Iron (Fe) - extractable	Extr_ap14	%	0	100
450	Phosphorus (P) - extractable	Extr_ap14	%	0	100
275	Sulfur (S) - extractable	Extr_ap14	%	0	100
400	Zinc (Zn) - extractable	Extr_ap14	%	0	100
425	cadmiumProperty	Extr_ap14	%	0	100
200	molybdenumProperty	Extr_ap14	%	0	100
301	Copper (Cu) - extractable	Extr_ap15	%	0	100
451	Phosphorus (P) - extractable	Extr_ap15	%	0	100
276	Sulfur (S) - extractable	Extr_ap15	%	0	100
401	Zinc (Zn) - extractable	Extr_ap15	%	0	100
426	cadmiumProperty	Extr_ap15	%	0	100
201	molybdenumProperty	Extr_ap15	%	0	100
176	Boron (B) - extractable	Extr_ap15	%	0	100
302	Copper (Cu) - extractable	Extr_ap20	%	0	100
352	Iron (Fe) - extractable	Extr_ap20	%	0	100
452	Phosphorus (P) - extractable	Extr_ap20	%	0	100
277	Sulfur (S) - extractable	Extr_ap20	%	0	100
402	Zinc (Zn) - extractable	Extr_ap20	%	0	100
427	cadmiumProperty	Extr_ap20	%	0	100
202	molybdenumProperty	Extr_ap20	%	0	100
177	Boron (B) - extractable	Extr_ap20	%	0	100
303	Copper (Cu) - extractable	Extr_ap21	%	0	100
353	Iron (Fe) - extractable	Extr_ap21	%	0	100
453	Phosphorus (P) - extractable	Extr_ap21	%	0	100
278	Sulfur (S) - extractable	Extr_ap21	%	0	100
403	Zinc (Zn) - extractable	Extr_ap21	%	0	100
428	cadmiumProperty	Extr_ap21	%	0	100
203	molybdenumProperty	Extr_ap21	%	0	100
178	Boron (B) - extractable	Extr_ap21	%	0	100
304	Copper (Cu) - extractable	Extr_c6h8o7-reeuwijk	%	0	100
354	Iron (Fe) - extractable	Extr_c6h8o7-reeuwijk	%	0	100
454	Phosphorus (P) - extractable	Extr_c6h8o7-reeuwijk	%	0	100
279	Sulfur (S) - extractable	Extr_c6h8o7-reeuwijk	%	0	100
404	Zinc (Zn) - extractable	Extr_c6h8o7-reeuwijk	%	0	100
429	cadmiumProperty	Extr_c6h8o7-reeuwijk	%	0	100
204	molybdenumProperty	Extr_c6h8o7-reeuwijk	%	0	100
179	Boron (B) - extractable	Extr_c6h8o7-reeuwijk	%	0	100
305	Copper (Cu) - extractable	Extr_cacl2	%	0	100
355	Iron (Fe) - extractable	Extr_cacl2	%	0	100
455	Phosphorus (P) - extractable	Extr_cacl2	%	0	100
280	Sulfur (S) - extractable	Extr_cacl2	%	0	100
405	Zinc (Zn) - extractable	Extr_cacl2	%	0	100
430	cadmiumProperty	Extr_cacl2	%	0	100
205	molybdenumProperty	Extr_cacl2	%	0	100
180	Boron (B) - extractable	Extr_cacl2	%	0	100
306	Copper (Cu) - extractable	Extr_capo4	%	0	100
356	Iron (Fe) - extractable	Extr_capo4	%	0	100
456	Phosphorus (P) - extractable	Extr_capo4	%	0	100
281	Sulfur (S) - extractable	Extr_capo4	%	0	100
406	Zinc (Zn) - extractable	Extr_capo4	%	0	100
431	cadmiumProperty	Extr_capo4	%	0	100
206	molybdenumProperty	Extr_capo4	%	0	100
181	Boron (B) - extractable	Extr_capo4	%	0	100
307	Copper (Cu) - extractable	Extr_dtpa	%	0	100
357	Iron (Fe) - extractable	Extr_dtpa	%	0	100
457	Phosphorus (P) - extractable	Extr_dtpa	%	0	100
282	Sulfur (S) - extractable	Extr_dtpa	%	0	100
407	Zinc (Zn) - extractable	Extr_dtpa	%	0	100
432	cadmiumProperty	Extr_dtpa	%	0	100
207	molybdenumProperty	Extr_dtpa	%	0	100
182	Boron (B) - extractable	Extr_dtpa	%	0	100
308	Copper (Cu) - extractable	Extr_edta	%	0	100
358	Iron (Fe) - extractable	Extr_edta	%	0	100
458	Phosphorus (P) - extractable	Extr_edta	%	0	100
283	Sulfur (S) - extractable	Extr_edta	%	0	100
408	Zinc (Zn) - extractable	Extr_edta	%	0	100
433	cadmiumProperty	Extr_edta	%	0	100
208	molybdenumProperty	Extr_edta	%	0	100
183	Boron (B) - extractable	Extr_edta	%	0	100
309	Copper (Cu) - extractable	Extr_h2so4-truog	%	0	100
359	Iron (Fe) - extractable	Extr_h2so4-truog	%	0	100
459	Phosphorus (P) - extractable	Extr_h2so4-truog	%	0	100
284	Sulfur (S) - extractable	Extr_h2so4-truog	%	0	100
409	Zinc (Zn) - extractable	Extr_h2so4-truog	%	0	100
434	cadmiumProperty	Extr_h2so4-truog	%	0	100
209	molybdenumProperty	Extr_h2so4-truog	%	0	100
184	Boron (B) - extractable	Extr_h2so4-truog	%	0	100
310	Copper (Cu) - extractable	Extr_hcl-h2so4-nelson	%	0	100
360	Iron (Fe) - extractable	Extr_hcl-h2so4-nelson	%	0	100
460	Phosphorus (P) - extractable	Extr_hcl-h2so4-nelson	%	0	100
285	Sulfur (S) - extractable	Extr_hcl-h2so4-nelson	%	0	100
410	Zinc (Zn) - extractable	Extr_hcl-h2so4-nelson	%	0	100
435	cadmiumProperty	Extr_hcl-h2so4-nelson	%	0	100
210	molybdenumProperty	Extr_hcl-h2so4-nelson	%	0	100
185	Boron (B) - extractable	Extr_hcl-h2so4-nelson	%	0	100
311	Copper (Cu) - extractable	Extr_hcl-nh4f-bray1	%	0	100
361	Iron (Fe) - extractable	Extr_hcl-nh4f-bray1	%	0	100
461	Phosphorus (P) - extractable	Extr_hcl-nh4f-bray1	%	0	100
286	Sulfur (S) - extractable	Extr_hcl-nh4f-bray1	%	0	100
411	Zinc (Zn) - extractable	Extr_hcl-nh4f-bray1	%	0	100
436	cadmiumProperty	Extr_hcl-nh4f-bray1	%	0	100
211	molybdenumProperty	Extr_hcl-nh4f-bray1	%	0	100
186	Boron (B) - extractable	Extr_hcl-nh4f-bray1	%	0	100
312	Copper (Cu) - extractable	Extr_hcl-nh4f-bray2	%	0	100
362	Iron (Fe) - extractable	Extr_hcl-nh4f-bray2	%	0	100
462	Phosphorus (P) - extractable	Extr_hcl-nh4f-bray2	%	0	100
287	Sulfur (S) - extractable	Extr_hcl-nh4f-bray2	%	0	100
412	Zinc (Zn) - extractable	Extr_hcl-nh4f-bray2	%	0	100
437	cadmiumProperty	Extr_hcl-nh4f-bray2	%	0	100
212	molybdenumProperty	Extr_hcl-nh4f-bray2	%	0	100
187	Boron (B) - extractable	Extr_hcl-nh4f-bray2	%	0	100
313	Copper (Cu) - extractable	Extr_hcl-nh4f-kurtz-bray	%	0	100
363	Iron (Fe) - extractable	Extr_hcl-nh4f-kurtz-bray	%	0	100
463	Phosphorus (P) - extractable	Extr_hcl-nh4f-kurtz-bray	%	0	100
288	Sulfur (S) - extractable	Extr_hcl-nh4f-kurtz-bray	%	0	100
413	Zinc (Zn) - extractable	Extr_hcl-nh4f-kurtz-bray	%	0	100
438	cadmiumProperty	Extr_hcl-nh4f-kurtz-bray	%	0	100
213	molybdenumProperty	Extr_hcl-nh4f-kurtz-bray	%	0	100
188	Boron (B) - extractable	Extr_hcl-nh4f-kurtz-bray	%	0	100
314	Copper (Cu) - extractable	Extr_hno3	%	0	100
364	Iron (Fe) - extractable	Extr_hno3	%	0	100
464	Phosphorus (P) - extractable	Extr_hno3	%	0	100
289	Sulfur (S) - extractable	Extr_hno3	%	0	100
414	Zinc (Zn) - extractable	Extr_hno3	%	0	100
439	cadmiumProperty	Extr_hno3	%	0	100
214	molybdenumProperty	Extr_hno3	%	0	100
189	Boron (B) - extractable	Extr_hno3	%	0	100
315	Copper (Cu) - extractable	Extr_hotwater	%	0	100
365	Iron (Fe) - extractable	Extr_hotwater	%	0	100
465	Phosphorus (P) - extractable	Extr_hotwater	%	0	100
290	Sulfur (S) - extractable	Extr_hotwater	%	0	100
415	Zinc (Zn) - extractable	Extr_hotwater	%	0	100
440	cadmiumProperty	Extr_hotwater	%	0	100
215	molybdenumProperty	Extr_hotwater	%	0	100
190	Boron (B) - extractable	Extr_hotwater	%	0	100
316	Copper (Cu) - extractable	Extr_m1	%	0	100
366	Iron (Fe) - extractable	Extr_m1	%	0	100
466	Phosphorus (P) - extractable	Extr_m1	%	0	100
291	Sulfur (S) - extractable	Extr_m1	%	0	100
416	Zinc (Zn) - extractable	Extr_m1	%	0	100
441	cadmiumProperty	Extr_m1	%	0	100
216	molybdenumProperty	Extr_m1	%	0	100
317	Copper (Cu) - extractable	Extr_m2	%	0	100
367	Iron (Fe) - extractable	Extr_m2	%	0	100
467	Phosphorus (P) - extractable	Extr_m2	%	0	100
292	Sulfur (S) - extractable	Extr_m2	%	0	100
417	Zinc (Zn) - extractable	Extr_m2	%	0	100
442	cadmiumProperty	Extr_m2	%	0	100
217	molybdenumProperty	Extr_m2	%	0	100
192	Boron (B) - extractable	Extr_m2	%	0	100
318	Copper (Cu) - extractable	Extr_m3	%	0	100
368	Iron (Fe) - extractable	Extr_m3	%	0	100
468	Phosphorus (P) - extractable	Extr_m3	%	0	100
293	Sulfur (S) - extractable	Extr_m3	%	0	100
418	Zinc (Zn) - extractable	Extr_m3	%	0	100
443	cadmiumProperty	Extr_m3	%	0	100
218	molybdenumProperty	Extr_m3	%	0	100
193	Boron (B) - extractable	Extr_m3	%	0	100
319	Copper (Cu) - extractable	Extr_m3-spec	%	0	100
369	Iron (Fe) - extractable	Extr_m3-spec	%	0	100
469	Phosphorus (P) - extractable	Extr_m3-spec	%	0	100
294	Sulfur (S) - extractable	Extr_m3-spec	%	0	100
419	Zinc (Zn) - extractable	Extr_m3-spec	%	0	100
444	cadmiumProperty	Extr_m3-spec	%	0	100
219	molybdenumProperty	Extr_m3-spec	%	0	100
194	Boron (B) - extractable	Extr_m3-spec	%	0	100
320	Copper (Cu) - extractable	Extr_nahco3-olsen	%	0	100
370	Iron (Fe) - extractable	Extr_nahco3-olsen	%	0	100
470	Phosphorus (P) - extractable	Extr_nahco3-olsen	%	0	100
295	Sulfur (S) - extractable	Extr_nahco3-olsen	%	0	100
420	Zinc (Zn) - extractable	Extr_nahco3-olsen	%	0	100
445	cadmiumProperty	Extr_nahco3-olsen	%	0	100
220	molybdenumProperty	Extr_nahco3-olsen	%	0	100
195	Boron (B) - extractable	Extr_nahco3-olsen	%	0	100
321	Copper (Cu) - extractable	Extr_nahco3-olsen-dabin	%	0	100
371	Iron (Fe) - extractable	Extr_nahco3-olsen-dabin	%	0	100
471	Phosphorus (P) - extractable	Extr_nahco3-olsen-dabin	%	0	100
296	Sulfur (S) - extractable	Extr_nahco3-olsen-dabin	%	0	100
421	Zinc (Zn) - extractable	Extr_nahco3-olsen-dabin	%	0	100
446	cadmiumProperty	Extr_nahco3-olsen-dabin	%	0	100
221	molybdenumProperty	Extr_nahco3-olsen-dabin	%	0	100
196	Boron (B) - extractable	Extr_nahco3-olsen-dabin	%	0	100
322	Copper (Cu) - extractable	Extr_naoac-morgan	%	0	100
372	Iron (Fe) - extractable	Extr_naoac-morgan	%	0	100
472	Phosphorus (P) - extractable	Extr_naoac-morgan	%	0	100
297	Sulfur (S) - extractable	Extr_naoac-morgan	%	0	100
422	Zinc (Zn) - extractable	Extr_naoac-morgan	%	0	100
447	cadmiumProperty	Extr_naoac-morgan	%	0	100
222	molybdenumProperty	Extr_naoac-morgan	%	0	100
197	Boron (B) - extractable	Extr_naoac-morgan	%	0	100
323	Copper (Cu) - extractable	Extr_nh4-co3-2-ambic1	%	0	100
373	Iron (Fe) - extractable	Extr_nh4-co3-2-ambic1	%	0	100
473	Phosphorus (P) - extractable	Extr_nh4-co3-2-ambic1	%	0	100
298	Sulfur (S) - extractable	Extr_nh4-co3-2-ambic1	%	0	100
423	Zinc (Zn) - extractable	Extr_nh4-co3-2-ambic1	%	0	100
448	cadmiumProperty	Extr_nh4-co3-2-ambic1	%	0	100
223	molybdenumProperty	Extr_nh4-co3-2-ambic1	%	0	100
198	Boron (B) - extractable	Extr_nh4-co3-2-ambic1	%	0	100
324	Copper (Cu) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	%	0	100
374	Iron (Fe) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	%	0	100
474	Phosphorus (P) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	%	0	100
895	Phosphorus (P) - total	Total_hcl	%	0	100
199	Boron (B) - extractable	Extr_nh4ch3ch-oh-cooh-leuven	%	0	100
475	gypsumProperty	CaSO4_gy01	%	0	100
476	gypsumProperty	CaSO4_gy02	%	0	100
477	gypsumProperty	CaSO4_gy03	%	0	100
478	gypsumProperty	CaSO4_gy04	%	0	100
479	gypsumProperty	CaSO4_gy05	%	0	100
480	gypsumProperty	CaSO4_gy06	%	0	100
481	gypsumProperty	CaSO4_gy07	%	0	100
618	Clay texture fraction	SaSiCl_2-20-2000u	%	0	100
570	Sand texture fraction	SaSiCl_2-20-2000u	%	0	100
666	Silt texture fraction	SaSiCl_2-20-2000u	%	0	100
634	Clay texture fraction	SaSiCl_2-50-2000u	%	0	100
586	Sand texture fraction	SaSiCl_2-50-2000u	%	0	100
682	Silt texture fraction	SaSiCl_2-50-2000u	%	0	100
650	Clay texture fraction	SaSiCl_2-64-2000u	%	0	100
602	Sand texture fraction	SaSiCl_2-64-2000u	%	0	100
698	Silt texture fraction	SaSiCl_2-64-2000u	%	0	100
913	aluminiumProperty	Total_h2so4	%	0	100
837	Copper (Cu) - total	Total_h2so4	%	0	100
932	Iron (Fe) - total	Total_h2so4	%	0	100
894	Phosphorus (P) - total	Total_h2so4	%	0	100
818	Sulfur (S) - total	Total_h2so4	%	0	100
875	cadmiumProperty	Total_h2so4	%	0	100
780	molybdenumProperty	Total_h2so4	%	0	100
856	zincProperty	Total_h2so4	%	0	100
799	Boron (B) - total	Total_h2so4	%	0	100
914	aluminiumProperty	Total_hcl	%	0	100
838	Copper (Cu) - total	Total_hcl	%	0	100
933	Iron (Fe) - total	Total_hcl	%	0	100
819	Sulfur (S) - total	Total_hcl	%	0	100
876	cadmiumProperty	Total_hcl	%	0	100
781	molybdenumProperty	Total_hcl	%	0	100
857	zincProperty	Total_hcl	%	0	100
800	Boron (B) - total	Total_hcl	%	0	100
915	aluminiumProperty	Total_hcl-aquaregia	%	0	100
839	Copper (Cu) - total	Total_hcl-aquaregia	%	0	100
934	Iron (Fe) - total	Total_hcl-aquaregia	%	0	100
896	Phosphorus (P) - total	Total_hcl-aquaregia	%	0	100
820	Sulfur (S) - total	Total_hcl-aquaregia	%	0	100
877	cadmiumProperty	Total_hcl-aquaregia	%	0	100
782	molybdenumProperty	Total_hcl-aquaregia	%	0	100
858	zincProperty	Total_hcl-aquaregia	%	0	100
801	Boron (B) - total	Total_hcl-aquaregia	%	0	100
916	aluminiumProperty	Total_hclo4	%	0	100
840	Copper (Cu) - total	Total_hclo4	%	0	100
935	Iron (Fe) - total	Total_hclo4	%	0	100
897	Phosphorus (P) - total	Total_hclo4	%	0	100
821	Sulfur (S) - total	Total_hclo4	%	0	100
878	cadmiumProperty	Total_hclo4	%	0	100
783	molybdenumProperty	Total_hclo4	%	0	100
859	zincProperty	Total_hclo4	%	0	100
802	Boron (B) - total	Total_hclo4	%	0	100
917	aluminiumProperty	Total_hno3-aquafortis	%	0	100
841	Copper (Cu) - total	Total_hno3-aquafortis	%	0	100
936	Iron (Fe) - total	Total_hno3-aquafortis	%	0	100
898	Phosphorus (P) - total	Total_hno3-aquafortis	%	0	100
822	Sulfur (S) - total	Total_hno3-aquafortis	%	0	100
879	cadmiumProperty	Total_hno3-aquafortis	%	0	100
784	molybdenumProperty	Total_hno3-aquafortis	%	0	100
860	zincProperty	Total_hno3-aquafortis	%	0	100
803	Boron (B) - total	Total_hno3-aquafortis	%	0	100
918	aluminiumProperty	Total_nh4-6mo7o24	%	0	100
842	Copper (Cu) - total	Total_nh4-6mo7o24	%	0	100
937	Iron (Fe) - total	Total_nh4-6mo7o24	%	0	100
899	Phosphorus (P) - total	Total_nh4-6mo7o24	%	0	100
823	Sulfur (S) - total	Total_nh4-6mo7o24	%	0	100
880	cadmiumProperty	Total_nh4-6mo7o24	%	0	100
785	molybdenumProperty	Total_nh4-6mo7o24	%	0	100
861	zincProperty	Total_nh4-6mo7o24	%	0	100
804	Boron (B) - total	Total_nh4-6mo7o24	%	0	100
919	aluminiumProperty	Total_tp03	%	0	100
843	Copper (Cu) - total	Total_tp03	%	0	100
938	Iron (Fe) - total	Total_tp03	%	0	100
900	Phosphorus (P) - total	Total_tp03	%	0	100
824	Sulfur (S) - total	Total_tp03	%	0	100
881	cadmiumProperty	Total_tp03	%	0	100
786	molybdenumProperty	Total_tp03	%	0	100
862	zincProperty	Total_tp03	%	0	100
805	Boron (B) - total	Total_tp03	%	0	100
920	aluminiumProperty	Total_tp04	%	0	100
844	Copper (Cu) - total	Total_tp04	%	0	100
939	Iron (Fe) - total	Total_tp04	%	0	100
901	Phosphorus (P) - total	Total_tp04	%	0	100
825	Sulfur (S) - total	Total_tp04	%	0	100
882	cadmiumProperty	Total_tp04	%	0	100
787	molybdenumProperty	Total_tp04	%	0	100
863	zincProperty	Total_tp04	%	0	100
806	Boron (B) - total	Total_tp04	%	0	100
921	aluminiumProperty	Total_tp05	%	0	100
845	Copper (Cu) - total	Total_tp05	%	0	100
940	Iron (Fe) - total	Total_tp05	%	0	100
902	Phosphorus (P) - total	Total_tp05	%	0	100
826	Sulfur (S) - total	Total_tp05	%	0	100
883	cadmiumProperty	Total_tp05	%	0	100
788	molybdenumProperty	Total_tp05	%	0	100
864	zincProperty	Total_tp05	%	0	100
807	Boron (B) - total	Total_tp05	%	0	100
922	aluminiumProperty	Total_tp06	%	0	100
846	Copper (Cu) - total	Total_tp06	%	0	100
941	Iron (Fe) - total	Total_tp06	%	0	100
903	Phosphorus (P) - total	Total_tp06	%	0	100
827	Sulfur (S) - total	Total_tp06	%	0	100
884	cadmiumProperty	Total_tp06	%	0	100
789	molybdenumProperty	Total_tp06	%	0	100
865	zincProperty	Total_tp06	%	0	100
808	Boron (B) - total	Total_tp06	%	0	100
923	aluminiumProperty	Total_tp07	%	0	100
847	Copper (Cu) - total	Total_tp07	%	0	100
942	Iron (Fe) - total	Total_tp07	%	0	100
904	Phosphorus (P) - total	Total_tp07	%	0	100
828	Sulfur (S) - total	Total_tp07	%	0	100
885	cadmiumProperty	Total_tp07	%	0	100
790	molybdenumProperty	Total_tp07	%	0	100
866	zincProperty	Total_tp07	%	0	100
809	Boron (B) - total	Total_tp07	%	0	100
924	aluminiumProperty	Total_tp08	%	0	100
848	Copper (Cu) - total	Total_tp08	%	0	100
943	Iron (Fe) - total	Total_tp08	%	0	100
905	Phosphorus (P) - total	Total_tp08	%	0	100
829	Sulfur (S) - total	Total_tp08	%	0	100
886	cadmiumProperty	Total_tp08	%	0	100
791	molybdenumProperty	Total_tp08	%	0	100
867	zincProperty	Total_tp08	%	0	100
810	Boron (B) - total	Total_tp08	%	0	100
925	aluminiumProperty	Total_tp09	%	0	100
849	Copper (Cu) - total	Total_tp09	%	0	100
944	Iron (Fe) - total	Total_tp09	%	0	100
906	Phosphorus (P) - total	Total_tp09	%	0	100
830	Sulfur (S) - total	Total_tp09	%	0	100
887	cadmiumProperty	Total_tp09	%	0	100
792	molybdenumProperty	Total_tp09	%	0	100
868	zincProperty	Total_tp09	%	0	100
811	Boron (B) - total	Total_tp09	%	0	100
926	aluminiumProperty	Total_tp10	%	0	100
850	Copper (Cu) - total	Total_tp10	%	0	100
945	Iron (Fe) - total	Total_tp10	%	0	100
907	Phosphorus (P) - total	Total_tp10	%	0	100
831	Sulfur (S) - total	Total_tp10	%	0	100
888	cadmiumProperty	Total_tp10	%	0	100
793	molybdenumProperty	Total_tp10	%	0	100
869	zincProperty	Total_tp10	%	0	100
812	Boron (B) - total	Total_tp10	%	0	100
927	aluminiumProperty	Total_unkn	%	0	100
851	Copper (Cu) - total	Total_unkn	%	0	100
946	Iron (Fe) - total	Total_unkn	%	0	100
908	Phosphorus (P) - total	Total_unkn	%	0	100
832	Sulfur (S) - total	Total_unkn	%	0	100
889	cadmiumProperty	Total_unkn	%	0	100
794	molybdenumProperty	Total_unkn	%	0	100
870	zincProperty	Total_unkn	%	0	100
813	Boron (B) - total	Total_unkn	%	0	100
928	aluminiumProperty	Total_xrd	%	0	100
852	Copper (Cu) - total	Total_xrd	%	0	100
947	Iron (Fe) - total	Total_xrd	%	0	100
909	Phosphorus (P) - total	Total_xrd	%	0	100
833	Sulfur (S) - total	Total_xrd	%	0	100
890	cadmiumProperty	Total_xrd	%	0	100
795	molybdenumProperty	Total_xrd	%	0	100
871	zincProperty	Total_xrd	%	0	100
814	Boron (B) - total	Total_xrd	%	0	100
929	aluminiumProperty	Total_xrf	%	0	100
853	Copper (Cu) - total	Total_xrf	%	0	100
948	Iron (Fe) - total	Total_xrf	%	0	100
910	Phosphorus (P) - total	Total_xrf	%	0	100
834	Sulfur (S) - total	Total_xrf	%	0	100
891	cadmiumProperty	Total_xrf	%	0	100
796	molybdenumProperty	Total_xrf	%	0	100
872	zincProperty	Total_xrf	%	0	100
815	Boron (B) - total	Total_xrf	%	0	100
930	aluminiumProperty	Total_xrf-p	%	0	100
854	Copper (Cu) - total	Total_xrf-p	%	0	100
949	Iron (Fe) - total	Total_xrf-p	%	0	100
911	Phosphorus (P) - total	Total_xrf-p	%	0	100
835	Sulfur (S) - total	Total_xrf-p	%	0	100
892	cadmiumProperty	Total_xrf-p	%	0	100
797	molybdenumProperty	Total_xrf-p	%	0	100
816	Boron (B) - total	Total_xrf-p	%	0	100
931	aluminiumProperty	Total_xtf-t	%	0	100
855	Copper (Cu) - total	Total_xtf-t	%	0	100
950	Iron (Fe) - total	Total_xtf-t	%	0	100
912	Phosphorus (P) - total	Total_xtf-t	%	0	100
836	Sulfur (S) - total	Total_xtf-t	%	0	100
893	cadmiumProperty	Total_xtf-t	%	0	100
798	molybdenumProperty	Total_xtf-t	%	0	100
874	zincProperty	Total_xtf-t	%	0	100
817	Boron (B) - total	Total_xtf-t	%	0	100
54	Carbon (C) - organic	OrgC_wc-cro3-nrcs6a1c	g/kg	0	1000
55	Carbon (C) - organic	OrgC_wc-cro3-tiurin	g/kg	0	1000
56	Carbon (C) - organic	OrgC_wc-cro3-walkleyblack	g/kg	0	1000
57	Carbon (C) - total	TotC_calcul-ic-oc	g/kg	0	1000
58	Carbon (C) - total	TotC_dc-ht	g/kg	0	1000
59	Carbon (C) - total	TotC_dc-ht-analyser	g/kg	0	1000
60	Carbon (C) - total	TotC_dc-ht-spec	g/kg	0	1000
61	Carbon (C) - total	TotC_dc-mt	g/kg	0	1000
714	totalCarbonateEquivalentProperty	CaCO3_acid-ch3cooh-dc	g/kg	0	1000
715	totalCarbonateEquivalentProperty	CaCO3_acid-ch3cooh-nodc	g/kg	0	1000
716	totalCarbonateEquivalentProperty	CaCO3_acid-ch3cooh-unkn	g/kg	0	1000
717	totalCarbonateEquivalentProperty	CaCO3_acid-dc	g/kg	0	1000
718	totalCarbonateEquivalentProperty	CaCO3_acid-h2so4-dc	g/kg	0	1000
719	totalCarbonateEquivalentProperty	CaCO3_acid-h2so4-nodc	g/kg	0	1000
720	totalCarbonateEquivalentProperty	CaCO3_acid-h2so4-unkn	g/kg	0	1000
721	totalCarbonateEquivalentProperty	CaCO3_acid-h3po4-dc	g/kg	0	1000
722	totalCarbonateEquivalentProperty	CaCO3_acid-h3po4-nodc	g/kg	0	1000
723	totalCarbonateEquivalentProperty	CaCO3_acid-h3po4-unkn	g/kg	0	1000
724	totalCarbonateEquivalentProperty	CaCO3_acid-hcl-dc	g/kg	0	1000
725	totalCarbonateEquivalentProperty	CaCO3_acid-hcl-nodc	g/kg	0	1000
726	totalCarbonateEquivalentProperty	CaCO3_acid-hcl-unkn	g/kg	0	1000
727	totalCarbonateEquivalentProperty	CaCO3_acid-nodc	g/kg	0	1000
728	totalCarbonateEquivalentProperty	CaCO3_acid-unkn	g/kg	0	1000
729	totalCarbonateEquivalentProperty	CaCO3_ca01	g/kg	0	1000
730	totalCarbonateEquivalentProperty	CaCO3_ca02	g/kg	0	1000
731	totalCarbonateEquivalentProperty	CaCO3_ca03	g/kg	0	1000
732	totalCarbonateEquivalentProperty	CaCO3_ca04	g/kg	0	1000
733	totalCarbonateEquivalentProperty	CaCO3_ca05	g/kg	0	1000
734	totalCarbonateEquivalentProperty	CaCO3_ca06	g/kg	0	1000
735	totalCarbonateEquivalentProperty	CaCO3_ca07	g/kg	0	1000
736	totalCarbonateEquivalentProperty	CaCO3_ca08	g/kg	0	1000
737	totalCarbonateEquivalentProperty	CaCO3_ca09	g/kg	0	1000
738	totalCarbonateEquivalentProperty	CaCO3_ca10	g/kg	0	1000
739	totalCarbonateEquivalentProperty	CaCO3_ca11	g/kg	0	1000
740	totalCarbonateEquivalentProperty	CaCO3_ca12	g/kg	0	1000
741	totalCarbonateEquivalentProperty	CaCO3_calcul-tc-oc	g/kg	0	1000
74	manganeseProperty	ExchBases_ph-unkn-m3	cmol/kg	0	1000
75	manganeseProperty	ExchBases_ph-unkn-m3-spec	cmol/kg	0	1000
76	manganeseProperty	ExchBases_ph0-cohex	cmol/kg	0	1000
77	manganeseProperty	ExchBases_ph0-nh4cl	cmol/kg	0	1000
78	manganeseProperty	ExchBases_ph7-nh4oac	cmol/kg	0	1000
79	manganeseProperty	ExchBases_ph7-nh4oac-aas	cmol/kg	0	1000
80	manganeseProperty	ExchBases_ph7-nh4oac-fp	cmol/kg	0	1000
81	manganeseProperty	ExchBases_ph7-unkn	cmol/kg	0	1000
82	manganeseProperty	ExchBases_ph8-bacl2tea	cmol/kg	0	1000
83	manganeseProperty	ExchBases_ph8-unkn	cmol/kg	0	1000
250	Magnesium (Mg) - extractable	Extr_ap14	cmol/kg	0	1000
150	Manganese (Mn) - extractable	Extr_ap14	cmol/kg	0	1000
225	Potassium (K) - extractable	Extr_ap14	cmol/kg	0	1000
375	Sodium (Na) - extractable	Extr_ap14	cmol/kg	0	1000
325	Calcium (Ca++) - extractable	Extr_ap14	cmol/kg	0	1000
128	Calcium (Ca++) - exchangeable	ExchBases_ph-unkn-edta	cmol/kg	0	100
96	Hydrogen (H+) - exchangeable	ExchBases_ph-unkn-m3	cmol/kg	0	100
140	Magnesium (Mg++) - exchangeable	ExchBases_ph-unkn-m3	cmol/kg	0	100
107	Potassium (K+) - exchangeable	ExchBases_ph-unkn-m3	cmol/kg	0	100
118	Aluminium (Al+++) - exchangeable	ExchBases_ph-unkn-m3	cmol/kg	0	100
129	Calcium (Ca++) - exchangeable	ExchBases_ph-unkn-m3	cmol/kg	0	100
97	Hydrogen (H+) - exchangeable	ExchBases_ph-unkn-m3-spec	cmol/kg	0	100
141	Magnesium (Mg++) - exchangeable	ExchBases_ph-unkn-m3-spec	cmol/kg	0	100
108	Potassium (K+) - exchangeable	ExchBases_ph-unkn-m3-spec	cmol/kg	0	100
119	Aluminium (Al+++) - exchangeable	ExchBases_ph-unkn-m3-spec	cmol/kg	0	100
130	Calcium (Ca++) - exchangeable	ExchBases_ph-unkn-m3-spec	cmol/kg	0	100
98	Hydrogen (H+) - exchangeable	ExchBases_ph0-cohex	cmol/kg	0	100
142	Magnesium (Mg++) - exchangeable	ExchBases_ph0-cohex	cmol/kg	0	100
109	Potassium (K+) - exchangeable	ExchBases_ph0-cohex	cmol/kg	0	100
120	Aluminium (Al+++) - exchangeable	ExchBases_ph0-cohex	cmol/kg	0	100
131	Calcium (Ca++) - exchangeable	ExchBases_ph0-cohex	cmol/kg	0	100
99	Hydrogen (H+) - exchangeable	ExchBases_ph0-nh4cl	cmol/kg	0	100
143	Magnesium (Mg++) - exchangeable	ExchBases_ph0-nh4cl	cmol/kg	0	100
110	Potassium (K+) - exchangeable	ExchBases_ph0-nh4cl	cmol/kg	0	100
121	Aluminium (Al+++) - exchangeable	ExchBases_ph0-nh4cl	cmol/kg	0	100
132	Calcium (Ca++) - exchangeable	ExchBases_ph0-nh4cl	cmol/kg	0	100
100	Hydrogen (H+) - exchangeable	ExchBases_ph7-nh4oac	cmol/kg	0	100
144	Magnesium (Mg++) - exchangeable	ExchBases_ph7-nh4oac	cmol/kg	0	100
111	Potassium (K+) - exchangeable	ExchBases_ph7-nh4oac	cmol/kg	0	100
122	Aluminium (Al+++) - exchangeable	ExchBases_ph7-nh4oac	cmol/kg	0	100
133	Calcium (Ca++) - exchangeable	ExchBases_ph7-nh4oac	cmol/kg	0	100
101	Hydrogen (H+) - exchangeable	ExchBases_ph7-nh4oac-aas	cmol/kg	0	100
145	Magnesium (Mg++) - exchangeable	ExchBases_ph7-nh4oac-aas	cmol/kg	0	100
112	Potassium (K+) - exchangeable	ExchBases_ph7-nh4oac-aas	cmol/kg	0	100
123	Aluminium (Al+++) - exchangeable	ExchBases_ph7-nh4oac-aas	cmol/kg	0	100
134	Calcium (Ca++) - exchangeable	ExchBases_ph7-nh4oac-aas	cmol/kg	0	100
102	Hydrogen (H+) - exchangeable	ExchBases_ph7-nh4oac-fp	cmol/kg	0	100
146	Magnesium (Mg++) - exchangeable	ExchBases_ph7-nh4oac-fp	cmol/kg	0	100
113	Potassium (K+) - exchangeable	ExchBases_ph7-nh4oac-fp	cmol/kg	0	100
124	Aluminium (Al+++) - exchangeable	ExchBases_ph7-nh4oac-fp	cmol/kg	0	100
135	Calcium (Ca++) - exchangeable	ExchBases_ph7-nh4oac-fp	cmol/kg	0	100
103	Hydrogen (H+) - exchangeable	ExchBases_ph7-unkn	cmol/kg	0	100
147	Magnesium (Mg++) - exchangeable	ExchBases_ph7-unkn	cmol/kg	0	100
114	Potassium (K+) - exchangeable	ExchBases_ph7-unkn	cmol/kg	0	100
125	Aluminium (Al+++) - exchangeable	ExchBases_ph7-unkn	cmol/kg	0	100
136	Calcium (Ca++) - exchangeable	ExchBases_ph7-unkn	cmol/kg	0	100
104	Hydrogen (H+) - exchangeable	ExchBases_ph8-bacl2tea	cmol/kg	0	100
148	Magnesium (Mg++) - exchangeable	ExchBases_ph8-bacl2tea	cmol/kg	0	100
115	Potassium (K+) - exchangeable	ExchBases_ph8-bacl2tea	cmol/kg	0	100
126	Aluminium (Al+++) - exchangeable	ExchBases_ph8-bacl2tea	cmol/kg	0	100
137	Calcium (Ca++) - exchangeable	ExchBases_ph8-bacl2tea	cmol/kg	0	100
105	Hydrogen (H+) - exchangeable	ExchBases_ph8-unkn	cmol/kg	0	100
149	Magnesium (Mg++) - exchangeable	ExchBases_ph8-unkn	cmol/kg	0	100
116	Potassium (K+) - exchangeable	ExchBases_ph8-unkn	cmol/kg	0	100
127	Aluminium (Al+++) - exchangeable	ExchBases_ph8-unkn	cmol/kg	0	100
138	Calcium (Ca++) - exchangeable	ExchBases_ph8-unkn	cmol/kg	0	100
85	Sodium (Na+) - exchangeable	ExchBases_ph-unkn-m3	cmol/kg	0	100
86	Sodium (Na+) - exchangeable	ExchBases_ph-unkn-m3-spec	cmol/kg	0	100
87	Sodium (Na+) - exchangeable	ExchBases_ph0-cohex	cmol/kg	0	100
88	Sodium (Na+) - exchangeable	ExchBases_ph0-nh4cl	cmol/kg	0	100
89	Sodium (Na+) - exchangeable	ExchBases_ph7-nh4oac	cmol/kg	0	100
90	Sodium (Na+) - exchangeable	ExchBases_ph7-nh4oac-aas	cmol/kg	0	100
91	Sodium (Na+) - exchangeable	ExchBases_ph7-nh4oac-fp	cmol/kg	0	100
92	Sodium (Na+) - exchangeable	ExchBases_ph7-unkn	cmol/kg	0	100
93	Sodium (Na+) - exchangeable	ExchBases_ph8-bacl2tea	cmol/kg	0	100
94	Sodium (Na+) - exchangeable	ExchBases_ph8-unkn	cmol/kg	0	100
\.


--
-- TOC entry 4366 (class 0 OID 54021862)
-- Dependencies: 216
-- Data for Name: plot; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.plot (plot_id, site_id, plot_code, altitude, time_stamp, map_sheet_code, positional_accuracy, "position", type) FROM stdin;
\.


--
-- TOC entry 4367 (class 0 OID 54021871)
-- Dependencies: 217
-- Data for Name: plot_individual; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.plot_individual (plot_id, individual_id) FROM stdin;
\.


--
-- TOC entry 4369 (class 0 OID 54021876)
-- Dependencies: 219
-- Data for Name: procedure_desc; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.procedure_desc (procedure_desc_id, reference, uri) FROM stdin;
FAO GfSD 2006	Food and Agriculture Organisation of the United Nations, Guidelines for Soil Description, Fourth Edition, 2006.	https://www.fao.org/publications/card/en/c/903943c7-f56a-521a-8d32-459e7e0cdae9/
\.


--
-- TOC entry 4370 (class 0 OID 54021884)
-- Dependencies: 220
-- Data for Name: procedure_phys_chem; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.procedure_phys_chem (procedure_phys_chem_id, broader_id, uri, definition, reference, citation) FROM stdin;
pHH2O	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHH2O	pHH2O (soil reaction) in a soil/water solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_dc-ht-dumas	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_dc-ht-dumas	Dry combustion at 800-1000 C celcius (Dumas method)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_dc-ht-leco	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_dc-ht-leco	Element analyzer (LECO analyzer), Dry Combustion	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHKCl	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHKCl	pHKCl (soil reaction) in a soil/KCl solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
SaSiCl_2-50-2000u-adj100	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-adj100	\N	\N	\N
SaSiCl_2-20-2000u-adj100	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-adj100	\N	\N	\N
SaSiCl_2-20-2000u-disp	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-disp	\N	\N	\N
SaSiCl_2-20-2000u-fld	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-fld	\N	\N	\N
SaSiCl_2-20-2000u-nodisp	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-nodisp	\N	\N	\N
SaSiCl_2-50-2000u-disp	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-disp	\N	\N	\N
SaSiCl_2-50-2000u-fld	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-fld	\N	\N	\N
SaSiCl_2-50-2000u-nodisp	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-nodisp	\N	\N	\N
SaSiCl_2-64-2000u-adj100	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-adj100	\N	\N	\N
SaSiCl_2-64-2000u-disp	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-disp	\N	\N	\N
SaSiCl_2-64-2000u-fld	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-fld	\N	\N	\N
SaSiCl_2-64-2000u-nodisp	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-nodisp	\N	\N	\N
SaSiCl_2-20-2000u	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u	\N	\N	\N
SaSiCl_2-50-2000u	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u	\N	\N	\N
SaSiCl_2-64-2000u	\N	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u	\N	\N	\N
SaSiCl_2-20-2000u-disp-beaker	SaSiCl_2-20-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-disp-beaker	\N	\N	\N
SaSiCl_2-20-2000u-disp-hydrometer	SaSiCl_2-20-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-disp-hydrometer	\N	\N	\N
SaSiCl_2-20-2000u-disp-hydrometer-bouy	SaSiCl_2-20-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-disp-hydrometer-bouy	\N	\N	\N
SaSiCl_2-20-2000u-disp-laser	SaSiCl_2-20-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-disp-laser	\N	\N	\N
SaSiCl_2-20-2000u-disp-pipette	SaSiCl_2-20-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-disp-pipette	\N	\N	\N
SaSiCl_2-20-2000u-disp-spec	SaSiCl_2-20-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-disp-spec	\N	\N	\N
SaSiCl_2-20-2000u-nodisp-hydrometer	SaSiCl_2-20-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-nodisp-hydrometer	\N	\N	\N
SaSiCl_2-20-2000u-nodisp-hydrometer-bouy	SaSiCl_2-20-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-nodisp-hydrometer-bouy	\N	\N	\N
SaSiCl_2-20-2000u-nodisp-laser	SaSiCl_2-20-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-nodisp-laser	\N	\N	\N
SaSiCl_2-20-2000u-nodisp-pipette	SaSiCl_2-20-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-nodisp-pipette	\N	\N	\N
SaSiCl_2-20-2000u-nodisp-spec	SaSiCl_2-20-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-20-2000u-nodisp-spec	\N	\N	\N
SaSiCl_2-50-2000u-disp-beaker	SaSiCl_2-50-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-disp-beaker	\N	\N	\N
SaSiCl_2-50-2000u-disp-hydrometer	SaSiCl_2-50-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-disp-hydrometer	\N	\N	\N
SaSiCl_2-50-2000u-disp-hydrometer-bouy	SaSiCl_2-50-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-disp-hydrometer-bouy	\N	\N	\N
SaSiCl_2-50-2000u-disp-laser	SaSiCl_2-50-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-disp-laser	\N	\N	\N
SaSiCl_2-50-2000u-disp-pipette	SaSiCl_2-50-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-disp-pipette	\N	\N	\N
SaSiCl_2-50-2000u-disp-spec	SaSiCl_2-50-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-disp-spec	\N	\N	\N
SaSiCl_2-50-2000u-nodisp-hydrometer	SaSiCl_2-50-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-nodisp-hydrometer	\N	\N	\N
SaSiCl_2-50-2000u-nodisp-hydrometer-bouy	SaSiCl_2-50-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-nodisp-hydrometer-bouy	\N	\N	\N
SaSiCl_2-50-2000u-nodisp-laser	SaSiCl_2-50-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-nodisp-laser	\N	\N	\N
SaSiCl_2-50-2000u-nodisp-pipette	SaSiCl_2-50-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-nodisp-pipette	\N	\N	\N
SaSiCl_2-50-2000u-nodisp-spec	SaSiCl_2-50-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-50-2000u-nodisp-spec	\N	\N	\N
SaSiCl_2-64-2000u-disp-beaker	SaSiCl_2-64-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-disp-beaker	\N	\N	\N
SaSiCl_2-64-2000u-disp-hydrometer	SaSiCl_2-64-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-disp-hydrometer	\N	\N	\N
SaSiCl_2-64-2000u-disp-hydrometer-bouy	SaSiCl_2-64-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-disp-hydrometer-bouy	\N	\N	\N
SaSiCl_2-64-2000u-disp-laser	SaSiCl_2-64-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-disp-laser	\N	\N	\N
SaSiCl_2-64-2000u-disp-pipette	SaSiCl_2-64-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-disp-pipette	\N	\N	\N
SaSiCl_2-64-2000u-disp-spec	SaSiCl_2-64-2000u-disp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-disp-spec	\N	\N	\N
SaSiCl_2-64-2000u-nodisp-hydrometer	SaSiCl_2-64-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-nodisp-hydrometer	\N	\N	\N
SaSiCl_2-64-2000u-nodisp-hydrometer-bouy	SaSiCl_2-64-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-nodisp-hydrometer-bouy	\N	\N	\N
SaSiCl_2-64-2000u-nodisp-laser	SaSiCl_2-64-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-nodisp-laser	\N	\N	\N
SaSiCl_2-64-2000u-nodisp-pipette	SaSiCl_2-64-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-nodisp-pipette	\N	\N	\N
SaSiCl_2-64-2000u-nodisp-spec	SaSiCl_2-64-2000u-nodisp	http://w3id.org/glosis/model/procedure/textureProcedure-SaSiCl_2-64-2000u-nodisp-spec	\N	\N	\N
OrgC_wc	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc	Wet oxidation or wet combustion methods	\N	\N
Extr_m1	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_m1	Mehlich1 method	https://www.ncagr.gov/AGRONOMI/pdffiles/mehlich53.pdf	\N
TotalN_h2so4	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_h2so4	H2SO4	\N	\N
TotalN_calcul	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_calcul	OC * 1.72 / 20 (gives C/N=11.6009)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_kjeldahl	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_kjeldahl	Method of Kjeldahl (digestion)	https://en.wikipedia.org/wiki/Kjeldahl_method	Kjeldahl, J. (1883) ‘Neue Methode zur Bestimmung des Stickstoffs in organischen Körpern’ (New method for the determination of nitrogen in organic substances), Zeitschrift für analytische Chemie, 22 (1) : 366-383.
TotalN_dc-spec	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_dc-spec	Spectrally measured and converted to N by dry combustion	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_kjeldahl-nh4	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_kjeldahl-nh4	Kjeldahl, and ammonia distillation	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_tn08	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_tn08	Sample digested by sulphuric acid, distillation of released ammonia, back titration against sulpuric acid	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_dtpa	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_dtpa	DiethyneleTriaminePentaAcetic acid (DTPA) method	https://doi.org/10.2136/sssaj1978.03615995004200030009x	\N
TotalN_tn04	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_tn04	Dry combustion using a CN-corder and cobalt oxide or copper oxide as an oxidation accelerator (Tanabe and Araragi, 1970)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_calcul-oc10	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_calcul-oc10	Calculated from OrgC and C/N ratio of 10	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_nelson	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_nelson	Nelson and Sommers, 1980	https://doi.org/10.1093/jaoac/63.4.770	Darrell W Nelson, Lee E Sommers, Total Nitrogen Analysis of Soil and Plant Tissues, Journal of Association of Official Analytical Chemists, Volume 63, Issue 4, 1 July 1980, Pages 770–778,
TotalN_dc	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_dc	Dry combustion	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_tn06	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_tn06	Continuous flow analyser after digestion with H2SO4/salicyclic acid/H2O2/Se	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotalN_bremner	\N	http://w3id.org/glosis/model/procedure/nitrogenTotalProcedure-TotalN_bremner	Total N (Bremner, 1965, p. 1162-1164)	https://doi.org/10.2134/agronmonogr9.2.c32	Bremner, J. M. 1965. Total Nitrogen. In: C. A. Black (ed.) Methods of soil analysis. Part 2: Chemical and microbial properties. Number 9 in series Agronomy. American Society of Agronomy, Inc. Publisher, Madison, USA. Pp. 1049-1178
PAWHC_calcul-fc200wp	\N	http://w3id.org/glosis/model/procedure/availableWaterHoldingCapacityProcedure-PAWHC_calcul-fc200wp	Plant available water holding capacity of the soil fine earth fraction, calculated with field capacity defined at 200 cm (pF 2.3)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
PAWHC_calcul-fc300wp	\N	http://w3id.org/glosis/model/procedure/availableWaterHoldingCapacityProcedure-PAWHC_calcul-fc300wp	Plant available water holding capacity of the soil fine earth fraction, calculated with field capacity defined at 300 cm (pF 2.5)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
PAWHC_calcul-fc100wp	\N	http://w3id.org/glosis/model/procedure/availableWaterHoldingCapacityProcedure-PAWHC_calcul-fc100wp	Plant available water holding capacity of the soil fine earth fraction, calculated with field capacity defined at 100 cm (pF 2.0)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
InOrgC_calcul-caco3	\N	http://w3id.org/glosis/model/procedure/carbonInorganicProcedure-InOrgC_calcul-caco3	Indirect estimate from total carbonate equivalent, with a factor of 0.12 (molar weights: CaCO3 100g/mol, C 12g/mol)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
InOrgC_calcul-tc-oc	\N	http://w3id.org/glosis/model/procedure/carbonInorganicProcedure-InOrgC_calcul-tc-oc	Indirect estimate (total carbon minus organic carbon = inorganic carbon)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
EffCEC_calcul-b	\N	http://w3id.org/glosis/model/procedure/effectiveCecProcedure-EffCEC_calcul-b	Sum of exchangeable bases (Ca, Mg, K, Na) without exchangeable acidity (H+Al), see ExchBases and ExchAcids for methods	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_unkn	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_unkn	Unspecified method	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
EffCEC_calcul-ba	\N	http://w3id.org/glosis/model/procedure/effectiveCecProcedure-EffCEC_calcul-ba	Sum of exchangeable bases (Ca, Mg, K, Na) plus exchangeable acidity (H+Al), see ExchBases and ExchAcids for methods	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_nh4-6mo7o24	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_nh4-6mo7o24	COLORIMETRIC VANADATE MOLYBDATE. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_tp05	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_tp05	8 M HCl extraction. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_hcl-aquaregia	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_hcl-aquaregia	Hydrocloric (HCl) extraction in nitric/perchloric acid mixture (totals) aqua regia	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_xrf	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_xrf	XRF	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_xrd	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_xrd	XRD	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_xrf-p	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_xrf-p	PXRF	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHCaCl2_sat	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHCaCl2_sat	pHCaCl2 (soil reaction) in saturated paste	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_tp03	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_tp03	reagent of Baeyens. Precipitation in form of Phosphomolybdate. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_hcl	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_hcl	HCl extraction. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_hclo4	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_hclo4	Perchloric acid percolation. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_tp10	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_tp10	Colorimetric, unspecified extract	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_tp07	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_tp07	1:1 H2SO4 : HNO3. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_tp04	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_tp04	acid fleischman. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_tp09	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_tp09	Walker and Adams, 1958. Particularly used for Total P.	\N	WALKER, T. W., AND A. F. R. ADAMS. 1958. Studies on soil organic matter. I. Soil Sci. 85: 307-318. 
Total_tp08	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_tp08	After Nitric acid attack (boiling with HNO3), colometric determination (method of Duval).. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_h2so4	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_h2so4	Total P-/- colorimetric in H2SO4-Se-Salicylic acid digest( sulfuric acid) Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_tp06	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_tp06	Molybdenum blue method, using ascorbic acid as reductant after heating of soil to 550 C and extraction with 6M sulphuric acid. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_xtf-t	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_xtf-t	TXRF	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Total_hno3-aquafortis	\N	http://w3id.org/glosis/model/procedure/totalElementsProcedure-Total_hno3-aquafortis	Nitric acid attack. Particularly used for Total P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca10	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca10	CaCO3 Equivalent, CO2 evolution after HCl treatment. Gravimetric	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BSat_calcul-ecec	\N	http://w3id.org/glosis/model/procedure/baseSaturationProcedure-BSat_calcul-ecec	Sum of exchangeable bases (Ca++, Mg++, K+, Na+) as percentage of EffCEC (method specified with EffCEC and ExchBases)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BSat_calcul-cec	\N	http://w3id.org/glosis/model/procedure/baseSaturationProcedure-BSat_calcul-cec	Sum of exchangeable bases (Ca++, Mg++, K+, Na+) as percentage of CEC (method specified with CEC and ExchBases)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
SlbAn_calcul-unkn	\N	http://w3id.org/glosis/model/procedure/solubleSaltsProcedure-SlbAn_calcul-unkn	Sum of soluble anions (Cl, SO4, HCO2, CO3, NO3, F)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
SlbCat_calcul-unkn	\N	http://w3id.org/glosis/model/procedure/solubleSaltsProcedure-SlbCat_calcul-unkn	Sum of soluble cations (Ca, Mg, K, Na)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-h3po4-dc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-h3po4-dc	Dissolution of carbonates by Phosphoric acid [H3PO4], external heat (dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-h2so4-nodc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-h2so4-nodc	Dissolution of carbonates by Sulfuric acid [H2SO4], no external (no dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-ch3cooh-unkn	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-ch3cooh-unkn	Dissolution of carbonates by Acetic acid [CH3COOH], external heat unknown	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-dc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-dc	Dissolution of carbonates by acid, external heat (dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-h2so4-dc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-h2so4-dc	Dissolution of carbonates by Sulfuric acid [H2SO4], external heat (dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca11	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca11	Black, 1965-HCl	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-hcl-dc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-hcl-dc	Dissolution of carbonates by Hydrochloric acid [HCl], or Perchloric acid [HClO4], external heat (dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_calcul-tc-oc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_calcul-tc-oc	Indirect estimate: inorganic carbon divided by 0.12 (computed as total carbon minus organic carbon)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca01	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca01	Method of Scheibler (volumetric)	\N	ON L 1084-99 (1999) Chemical analyses of soils—determination of carbonate. In: Austrian Standards Institute (ed) O‹ NORM L 1084. Austrian Standards Institute, Vienna
CaCO3_ca04	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca04	Calcimeter method (volumetric after adition of dilute acid)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-h2so4-unkn	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-h2so4-unkn	Dissolution of carbonates by Sulfuric acid [H2SO4], external heat unknown	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-hcl-unkn	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-hcl-unkn	Dissolution of carbonates by Hydrochloric acid [HCl], or Perchloric acid [HClO4], external heat unknown	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca12	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca12	Treatment with H2SO4 N/2 acid followed by titration with NaOH N/2 in presence of an indicator	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_dc-ht	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_dc-ht	Unacidified. Dry combustion at high temperature (e.g. 1200 C and colometric CO2 measurement (Schlichting et al. 1995)	\N	Schlichting E, Blume HP, Stahr K (1995) Soils Practical (in German). Blackwell, Berlin
CaCO3_ca08	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca08	Bernard calcimeter (Total CaCO3)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca07	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca07	Pressure calcimeter (Nelson, 1982)	https://acsess.onlinelibrary.wiley.com/doi/book/10.2134/agronmonogr9.2.2ed	Nelson, D.W., and L.E. Sommers. 1982. Total carbon, organic carbon and organic matter. p. 539-579. In A.L. Page (ed.), 1983. Methods of soil analysis. Part 2. 2nd ed. Agron. Monogr. 9. ASA and SSSA, Madison, WI.
CaCO3_ca09	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca09	Carbonates: H3PO4 treatment at 80 deg. C and CO2 measurement like TOC (OC13), transformation into CaCO3 (Schlichting et al. 1995)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-ch3cooh-nodc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-ch3cooh-nodc	Dissolution of carbonates by Acetic acid [CH3COOH], no external (no dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-ch3cooh-dc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-ch3cooh-dc	Dissolution of carbonates by Acetic acid [CH3COOH], external heat (dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca06	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca06	H3PO4 acid at 80C, conductometric in NaOH (Schlichting & Blume, 1966)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-h3po4-unkn	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-h3po4-unkn	Dissolution of carbonates by Phosphoric acid [H3PO4], external heat unknown	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca03	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca03	Method of Piper (HCl)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-h3po4-nodc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-h3po4-nodc	Dissolution of carbonates by Phosphoric acid [H3PO4], no external (no dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca05	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca05	Gravimetric (USDA Agr. Hdbk 60-/- method Richards et al., 1954)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-hcl-nodc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-hcl-nodc	Dissolution of carbonates by Hydrochloric acid [HCl], or Perchloric acid [HClO4], no external (no dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_acid-unkn	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-unkn	Dissolution of carbonates by acid, external heat unknown	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaCO3_ca02	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_ca02	Method of Wesemael	\N	Wesemael, J.C., 1955. De bepaling van van calciumcarbonaatgehalte van gronden. Chemisch Weekblad 51, 35-36.
CaCO3_acid-nodc	\N	http://w3id.org/glosis/model/procedure/totalCarbonateEquivalentProcedure-CaCO3_acid-nodc	Dissolution of carbonates by acid, no external (no dry combustion)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
SumTxtr_calcul	\N	http://w3id.org/glosis/model/procedure/textureSumProcedure-SumTxtr_calcul	Calculated sum of sand, silt and clay fractions	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CrsFrg_fld	\N	http://w3id.org/glosis/model/procedure/coarseFragmentsProcedure-CrsFrg_fld	Particles > 2 mm observed in the field. May include concretions and very hard aggregates	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CrsFrg_fldcls	\N	http://w3id.org/glosis/model/procedure/coarseFragmentsProcedure-CrsFrg_fldcls	Particles > 2 mm observed in the field and calculated from class values. May include concretions and very hard aggregates	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CrsFrg_lab	\N	http://w3id.org/glosis/model/procedure/coarseFragmentsProcedure-CrsFrg_lab	Particles > 2 mm measured in laboratory (sieved after light pounding). May include concretions and very hard aggregates	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Poros_calcul-pf0	\N	http://w3id.org/glosis/model/procedure/porosityProcedure-Poros_calcul-pf0	Porosity calculated from volumetric moisture content at pF 0 (1 cm)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHNaF_ratio1-5	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHNaF_ratio1-5	pHNaF (soil reaction) in 1:5 soil/NaF solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHNaF_ratio1-1	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHNaF_ratio1-1	pHNaF (soil reaction) in 1:1 soil/NaF solution (1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHH2O_sat	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHH2O_sat	pHH2O (soil reaction) in water saturated paste	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHNaF_ratio1-2.5	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHNaF_ratio1-2.5	pHNaF (soil reaction) in 1:2.5 soil/NaF solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHCaCl2_ratio1-1	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHCaCl2_ratio1-1	pHCaCl2 (soil reaction) in 1:1 soil/1 M CaCl2 solution (1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHKCl_sat	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHKCl_sat	pHKCl (soil reaction) in saturated paste	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHKCl_ratio1-2	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHKCl_ratio1-2	pHKCl (soil reaction) in 1:2 soil/KCl solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHH2O_unkn-spec	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHH2O_unkn-spec	Spectrally measured and converted to pHH2O (soil reaction) in unknown soil/water solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHKCl_ratio1-5	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHKCl_ratio1-5	pHKCl (soil reaction) in 1:5 soil/KCl solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHNaF_ratio1-2	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHNaF_ratio1-2	pHNaF (soil reaction) in 1:2 soil/NaF solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHH2O_ratio1-2.5	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHH2O_ratio1-2.5	pHH2O (soil reaction) in 1:2.5 soil/water solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHCaCl2_ratio1-5	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHCaCl2_ratio1-5	pHCaCl2 (soil reaction) in 1:5 soil/CaCl2 solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHH2O_ratio1-1	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHH2O_ratio1-1	pHH2O (soil reaction) in 1:1 soil/water solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHCaCl2	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHCaCl2	pHCaCl2 (soil reaction) in a soil/CaCl2 solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHH2O_ratio1-2	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHH2O_ratio1-2	pHH2O (soil reaction) in 1:2 soil/water solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHCaCl2_ratio1-10	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHCaCl2_ratio1-10	pHCaCl2 (soil reaction) in 1:10 soil/CaCl2 solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHH2O_ratio1-5	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHH2O_ratio1-5	pHH2O (soil reaction) in 1:5 soil/water solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHKCl_ratio1-1	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHKCl_ratio1-1	pHKCl (soil reaction) in 1:1 soil/KCl solution (1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHCaCl2_ratio1-2	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHCaCl2_ratio1-2	pHCaCl2 (soil reaction) in 1:2 soil/CaCl2 solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHCaCl2_ratio1-2.5	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHCaCl2_ratio1-2.5	pHCaCl2 (soil reaction) in 1:2.5 soil/CaCl2 solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHNaF_sat	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHNaF_sat	pHNaF (soil reaction) in saturated paste	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHNaF	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHNaF	pHNaF (soil reaction) in a soil/NaF solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHKCl_ratio1-2.5	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHKCl_ratio1-2.5	pHKCl (soil reaction) in 1:2.5 soil/KCl solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHNaF_ratio1-10	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHNaF_ratio1-10	pHNaF (soil reaction) in 1:10 soil/NaF solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHH2O_ratio1-10	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHH2O_ratio1-10	pHH2O (soil reaction) in 1:10 soil/water solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
pHKCl_ratio1-10	\N	http://w3id.org/glosis/model/procedure/pHProcedure-pHKCl_ratio1-10	pHKCl (soil reaction) in 1:10 soil/KCl solution (0.01-1 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
RetentP_unkn-spec	\N	http://w3id.org/glosis/model/procedure/phosphorusRetentionProcedure-RetentP_unkn-spec	Spectrally measured and converted to P retention (P buffer index)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
RetentP_blakemore	\N	http://w3id.org/glosis/model/procedure/phosphorusRetentionProcedure-RetentP_blakemore	P retention at ~pH4.6  (acc. Blakemore 1987)	\N	Blakemore L.C. Searle P.L. and Daly, B.K. (1987) Methods for chemical analysis of soils. NZ Soil Bureau, Lower Hutt, New Zealand.
BlkDensW_we-unkn	\N	http://w3id.org/glosis/model/procedure/bulkDensityWholeSoilProcedure-BlkDensW_we-unkn	Whole earth. Type of sample unknown, at unknown humidity, not corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensW_we-cl-fc	\N	http://w3id.org/glosis/model/procedure/bulkDensityWholeSoilProcedure-BlkDensW_we-cl-fc	Whole earth. Clod samples (natural clods), at field capacity (0.33 bar, 33 kPa, 330 cm, pF 2.5), not corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensW_we-cl-od	\N	http://w3id.org/glosis/model/procedure/bulkDensityWholeSoilProcedure-BlkDensW_we-cl-od	Whole earth. Clod samples (natural clods), at oven dry, not corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensW_we-co-od	\N	http://w3id.org/glosis/model/procedure/bulkDensityWholeSoilProcedure-BlkDensW_we-co-od	Whole earth. Core sampling (pF rings), at oven dry, not corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensW_we-cl-unkn	\N	http://w3id.org/glosis/model/procedure/bulkDensityWholeSoilProcedure-BlkDensW_we-cl-unkn	Whole earth. Clod samples (natural clods), at unknown humidity, not corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensW_we-co-fc	\N	http://w3id.org/glosis/model/procedure/bulkDensityWholeSoilProcedure-BlkDensW_we-co-fc	Whole earth. Core sampling (pF rings), at field capacity (0.33 bar, 33 kPa, 336 cm, pF 2.5), not corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensW_we-co-unkn	\N	http://w3id.org/glosis/model/procedure/bulkDensityWholeSoilProcedure-BlkDensW_we-co-unkn	Whole earth. Core sampling (pF rings), at unknown humidity, not corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensW_we-rpl-unkn	\N	http://w3id.org/glosis/model/procedure/bulkDensityWholeSoilProcedure-BlkDensW_we-rpl-unkn	Whole earth. Excavation and replacement (i.e. soils too fragile to remove a stable sample) e.g. by auger, at unknown humidity, not corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph0-cohex	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph0-cohex	CEC unbuffered at pH of the soil, in Cobalt(III) hexamine chloride solution 0,0166M (Cohex) [Co[NH3]6]Cl3 ), ISO 23470 (2007)  exchange solution	https://www.iso.org/standard/36879.html	\N
CEC_ph8-baoac	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph8-baoac	CEC buffered at pH 8.0-8.5, in 0.5 M Ba-acetate exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph8-nh4oac	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph8-nh4oac	CEC buffered at pH 8.0-8.5, in 1 M NH4-acetate exchange solution (0.25-1.0 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph0-nh4cl	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph0-nh4cl	CEC unbuffered at pH of the soil, in 1 M NH4-chloride exchange solution (0.2-1.0 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph8-unkn	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph8-unkn	CEC buffered at pH 8.0-8.5, in unknown exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph-unkn-m3	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph-unkn-m3	CEC at unknown buffer, in Mehlich III exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph7-nh4oac	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph7-nh4oac	CEC buffered at pH 7, in 1 M NH4-acetate (NH4OAc) exchange solution (0.25-1.0 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph7-unkn	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph7-unkn	CEC buffered at pH 7, in unknown exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph8-naoac	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph8-naoac	CEC buffered at pH 8.0-8.5, in 1 M Na-acetate exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph-unkn-cacl2	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph-unkn-cacl2	CEC at unknown buffer, in 0.1 M CaCl2 exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph0-kcl	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph0-kcl	CEC unbuffered at pH of the soil, in 1 M KCl exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph7-edta	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph7-edta	CEC buffered at pH 7, in 0.1 M Li-EDTA exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph0-unkn	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph0-unkn	CEC unbuffered at pH of the soil, in unknown exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph8-licl2tea	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph8-licl2tea	CEC buffered at pH 8.0-8.5, in 0.5 M Li-chloride - TEA exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph0-ag-thioura	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph0-ag-thioura	CEC unbuffered at pH of the soil, in 0.01 M Ag-thioura exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph0-bacl2	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph0-bacl2	CEC unbuffered at pH o the soil, in 0.5 M BaCl2 exchange solution (0.1.1.0 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph8-bacl2tea	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph8-bacl2tea	CEC buffered at pH 8.0-8.5, in 0.5 M BaCl2-TEA exchange solution (0.1.1.0 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph0-nh4oac	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph0-nh4oac	CEC unbuffered at pH of the soil, in 1 M NH4-acetate (NH4OAc) exchange solution (0.25-1.0 M)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CEC_ph-unkn-lioac	\N	http://w3id.org/glosis/model/procedure/cationExchangeCapacitySoilProcedure-CEC_ph-unkn-lioac	CEC at unknown buffer, in 0.5 M Li-acetate exchange solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_ud	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_ud	Undisturbed samples	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_d-cl-ww	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_d-cl-ww	Pressure-plate extraction, disturbed -clod- samples (wt%) * density on weight/weight basis; to be converted to v/v (with BD at appropriate humidity)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_calcul-ptf-brookscorey	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_calcul-ptf-brookscorey	Calculated by PTF of brooks - corey	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_d-ww	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_d-ww	Volumetric moisture content in disturbed samples on weight/weight basis to be converted to v/v (with BD at appropriate humidity)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_calcul-ptf	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_calcul-ptf	Calculated by PTF	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_d-cl	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_d-cl	Pressure-plate extraction, disturbed -clod- samples (wt%) * density	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_d	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_d	Volumetric moisture content in disturbed samples	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_ud-co	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_ud-co	Volumetric moisture content in undisturbed samples (pF rings cores)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
VMC_ud-cl	\N	http://w3id.org/glosis/model/procedure/moistureContentProcedure-VMC_ud-cl	Natural clod	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaSO4_gy01	\N	http://w3id.org/glosis/model/procedure/gypsumProcedure-CaSO4_gy01	Dissolved in water and precipitated by acetone	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaSO4_gy06	\N	http://w3id.org/glosis/model/procedure/gypsumProcedure-CaSO4_gy06	Total-S, using LECO furnace, minus easily soluble MgSO4 and Na2SO4	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaSO4_gy07	\N	http://w3id.org/glosis/model/procedure/gypsumProcedure-CaSO4_gy07	Schleiff method, electrometric	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaSO4_gy04	\N	http://w3id.org/glosis/model/procedure/gypsumProcedure-CaSO4_gy04	In 0.1 M Na3-EDTA-/- turbidimetric (Begheijn, 1993)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaSO4_gy03	\N	http://w3id.org/glosis/model/procedure/gypsumProcedure-CaSO4_gy03	Calculated from conductivity of successive dilutions	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaSO4_gy05	\N	http://w3id.org/glosis/model/procedure/gypsumProcedure-CaSO4_gy05	Gravimetric after dissolution in 0.2 N HCl (USSR-method)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
CaSO4_gy02	\N	http://w3id.org/glosis/model/procedure/gypsumProcedure-CaSO4_gy02	Differ. between Ca-conc. in sat. extr. and Ca-conc. in 1/50 s/w solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
EC_ratio1-10	\N	http://w3id.org/glosis/model/procedure/electricalConductivityProcedure-EC_ratio1-10	Elec. conductivity at 1:10 soil/water ratio	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
EC_ratio1-2	\N	http://w3id.org/glosis/model/procedure/electricalConductivityProcedure-EC_ratio1-2	Elec. conductivity at 1:2 soil/water ratio	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
EC_ratio1-2.5	\N	http://w3id.org/glosis/model/procedure/electricalConductivityProcedure-EC_ratio1-2.5	Elec. conductivity at 1:2.5 soil/water ratio	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
EC_ratio1-5	\N	http://w3id.org/glosis/model/procedure/electricalConductivityProcedure-EC_ratio1-5	Elec. conductivity at 1:5 soil/water ratio	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ECe_sat	\N	http://w3id.org/glosis/model/procedure/electricalConductivityProcedure-ECe_sat	Elec. conductivity in saturated paste (ECe)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
EC_ratio1-1	\N	http://w3id.org/glosis/model/procedure/electricalConductivityProcedure-EC_ratio1-1	Elec. conductivity at 1:1 soil/water ratio	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchBases_ph7-nh4oac-fp	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph7-nh4oac-fp	Exch bases (Ca, Mg, K, Na) buffered at pH 7, in 1M NH4OAc, K and Na with FP (Flame Photometry)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchBases_ph8-bacl2tea	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph8-bacl2tea	Exch bases (Ca, Mg, K, Na) buffered at pH 8.0-8.5, in 0.5 M BaCl2 - TEA solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchBases_ph-unkn-edta	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph-unkn-edta	Exch bases (Ca, Mg, K, Na) unknown buffer, in EDTA solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchBases_ph-unkn-m3	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph-unkn-m3	Exch bases (Ca, Mg, K, Na) unknown buffer, in Mehlich3 solution with extractable ppm assumed exchangeable cmolc/kg	https://doi.org/10.1080/00103628409367568	\N
ExchBases_ph0-nh4cl	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph0-nh4cl	Exch bases (Ca, Mg, K, Na) unbuffered, in 1 M NH4Cl (0.05-1.0 m?)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchBases_ph8-unkn	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph8-unkn	Exch bases (Ca, Mg, K, Na) buffered at pH 8.0-8.5, in unknown solution	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchBases_ph7-nh4oac	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph7-nh4oac	Exch bases (Ca, Mg, K, Na) buffered at pH 7, in 1M NH4OAc	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchBases_ph0-cohex	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph0-cohex	Exch bases (Ca, Mg, K, Na) unbuffered, in Cobalt(III) hexamine chloride solution 0,0166M (Cohex) [Co[NH3]6]Cl3 ), ISO 23470 (2007)	https://www.iso.org/standard/36879.html	\N
ExchBases_ph7-unkn	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph7-unkn	Exch bases (Ca, Mg, K, Na) buffered at pH 7, in unknown solution	https://www.isric.org/sites/default/files/WOSISprocedureManual_2020nov17web.pdf#page=70	\N
ExchBases_ph-unkn-m3-spec	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph-unkn-m3-spec	Exch bases (Ca, Mg, K, Na) spectrally measured and converted to, unknown buffer, in Mehlich3 solution with extractable ppm assumed exchangeable cmolc/kg	https://doi.org/10.1080/00103628409367568	\N
ExchBases_ph7-nh4oac-aas	\N	http://w3id.org/glosis/model/procedure/exchangeableBasesProcedure-ExchBases_ph7-nh4oac-aas	Exch bases (Ca, Mg, K, Na) buffered at pH 7, in 1M NH4OAc, Ca and Mg with AAS (Atomic Absorption Spectrometry)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_dc-lt-loi	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_dc-lt-loi	Unacidified. Loss on ignition (NL) is total Organic Carbon	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_calcul-tc-ic	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_calcul-tc-ic	Calculated as total carbon minus inorganic carbon	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_wc-cro3-tiurin	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc-cro3-tiurin	Wet oxidation according to Tiurin with K-dichromate	\N	I. V. TIURIN, Pochvovodenie (Pedology), (1931) 36.
OrgC_dc-lt	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_dc-lt	Unacidified. Dry combustion at low temperature e.g. 500 C	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_acid-dc	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_acid-dc	Acidified dry combustion or dry oxidation methods (after removal of carbonates)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_acid-dc-ht-analyser	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_acid-dc-ht-analyser	Acidified. Furnace combustion (e.g., LECO combustion analyzer, Dumas method)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_acid-dc-lt	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_acid-dc-lt	Acidified. Dry combustion at 500 C	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_wc-cro3-nelson	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc-cro3-nelson	Wet oxidation according to Nelson and Sommers (1996)	\N	Nelson and Sommers (1996) in: Sparks DL (ed.). Soil Sci. Soc. Am. book series 5, part 3, pp 961-1010.
OrgC_dc	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_dc	Unacidified. Dry combustion or dry oxidation methods (without prior removal of carbonates)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_acid-dc-lt-loi	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_acid-dc-lt-loi	Acidified. Loss on ignition (NL)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_wc-cro3-walkleyblack	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc-cro3-walkleyblack	Walkley-Black method (chromic acid digestion)	\N	Walkley, A. and I. A. Black. 1934. An Examination of Degtjareff Method for Determining Soil Organic Matter and a Proposed Modification of the Chromic Acid Titration Method. Soil Sci. 37:29–37.
OrgC_acid-dc-ht	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_acid-dc-ht	Acidified. Dry combustion at 1200 C and colometric CO2 measurement (Schlichting et al. 1995)	\N	Schlichting E, Blume HP, Stahr K (1995) Soils Practical (in German). Blackwell, Berlin
OrgC_dc-spec	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_dc-spec	Spectrally measured and converted to Unacidified Dry combustion or dry oxidation methods	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_wc-cro3-knopp	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc-cro3-knopp	Wet oxidation according to Knopp with chromic acid and gravimetric determination of CO2	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_dc-ht-analyser	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_dc-ht-analyser	Unacidified. Dry combustion by furnace (e.g., LECO combustion analyzer, Dumas method). Is total Carbon?	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_wc-cro3-nrcs6a1c	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc-cro3-nrcs6a1c	Wet oxidation according to USDA-NRCS method 6A1c with acid dichromate digestion, FeSO4 titration, automatic titrator	https://www.nrcs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb1253872.pdf	\N
OrgC_wc-cro3-kalembra	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc-cro3-kalembra	Wet oxidation according to Kalembra and Jenkinson (1973) with acid dichromate	https://doi.org/10.1002/jsfa.2740240910	\N
OrgC_acid-dc-mt	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_acid-dc-mt	Acidified. Dry combustion at 840 C	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_wc-cro3-jackson	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc-cro3-jackson	Wet oxidation according to Jackson (1958) with chromic acid digestion	\N	Jackson, M. L. (1958) Soil Chemical Analysis. Prentice-Hall, Englewood Cliffs, New Jersey.
OrgC_acid-dc-spec	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_acid-dc-spec	Spectrally measured and converted to Acidified dry combustion or dry oxidation methods (after removal of carbonates)	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgC_wc-cro3-kurmies	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_wc-cro3-kurmies	Wet oxidation according to Kurmies with K2Cr2O7+H2SO4	\N	B. KURMIES, Z. Pflanzenernühr. Dung. u Bodenk., 44 (1949) 121
OrgC_dc-mt	\N	http://w3id.org/glosis/model/procedure/carbonOrganicProcedure-OrgC_dc-mt	Unacidified. Dry combustion at medium temperature e.g. 840 C	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchAcid_ph7-unkn	\N	http://w3id.org/glosis/model/procedure/acidityExchangeableProcedure-ExchAcid_ph7-unkn	Exch acidity (H+Al) buffered at pH 7, in unknown extract	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchAcid_ph0-unkn	\N	http://w3id.org/glosis/model/procedure/acidityExchangeableProcedure-ExchAcid_ph0-unkn	Exch acidity (H+Al) unbuffered, in unknown extract	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchAcid_ph8-bacl2tea	\N	http://w3id.org/glosis/model/procedure/acidityExchangeableProcedure-ExchAcid_ph8-bacl2tea	Exch (extractable / potential) acidity (Al) buffered at pH 8.0-8.5, in 1 M BaCl2 - TEA	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchAcid_ph0-kcl1m	\N	http://w3id.org/glosis/model/procedure/acidityExchangeableProcedure-ExchAcid_ph0-kcl1m	Exch acidity (H+Al) unbuffered, in 1 M KCl extract	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchAcid_ph0-nh4cl	\N	http://w3id.org/glosis/model/procedure/acidityExchangeableProcedure-ExchAcid_ph0-nh4cl	Exch acidity (H+Al) unbuffered, in 0.05-0.1 M NH4Cl extract	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchAcid_ph7-caoac	\N	http://w3id.org/glosis/model/procedure/acidityExchangeableProcedure-ExchAcid_ph7-caoac	Exch acidity (H+Al) buffered at pH 7, in 1M Ca-acetate extract	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
ExchAcid_ph8-unkn	\N	http://w3id.org/glosis/model/procedure/acidityExchangeableProcedure-ExchAcid_ph8-unkn	Exch (extractable / potential) acidity (Al) buffered at pH 8.0-8.5, in unknown extract	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
HumAcidC_unkn	\N	http://w3id.org/glosis/model/procedure/organicMatterProcedure-HumAcidC_unkn	Humic acid carbon_unknown method	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
FulAcidC_unkn	\N	http://w3id.org/glosis/model/procedure/organicMatterProcedure-FulAcidC_unkn	Fulvic acid carbon_unknown method	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotHumC_unkn	\N	http://w3id.org/glosis/model/procedure/organicMatterProcedure-TotHumC_unkn	Total humic carbon_unknown method	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
OrgM_calcul-oc1.73	\N	http://w3id.org/glosis/model/procedure/organicMatterProcedure-OrgM_calcul-oc1.73	Organic carbon * 1,73	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-co-od	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-co-od	Fine earth. Core sampling (pF rings), at oven dry, corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-co-unkn	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-co-unkn	Fine earth. Core sampling (pF rings), at unknown humidity, corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-unkn-od	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-unkn-od	Fine earth. Type of sample unknown, at oven dry, corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-co-fc	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-co-fc	Fine earth. Core sampling (pF rings), at field capacity (0.33 bar, 33 kPa, 336 cm, pF 2.5), corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-rpl-unkn	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-rpl-unkn	Fine earth. Excavation and replacement (i.e. soils too fragile to remove a stable sample) e.g. by auger, at unknown humidity, corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-cl-unkn	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-cl-unkn	Fine earth. Clod samples (natural clods or reconstituted from < 2mm sample), at unknown humidity, corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-unkn-fc	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-unkn-fc	Fine earth. Type of sample unknown, at field capacity (0.33 bar, 33 kPa, 330 cm, pF 2.5), corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-cl-od	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-cl-od	Fine earth. Clod samples (natural clods or reconstituted from < 2mm sample), at oven dry, corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-cl-fc	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-cl-fc	Fine earth. Clod samples (natural clods or reconstituted from < 2mm sample), at field capacity (0.33 bar, 33 kPa, 330 cm, pF 2.5), corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
BlkDensF_fe-unkn	\N	http://w3id.org/glosis/model/procedure/bulkDensityFineEarthProcedure-BlkDensF_fe-unkn	Fine earth. Type of sample unknown, at unknown humidity, corrected for coarse fragments if any	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
KSat_calcul-ptf-saxton	\N	http://w3id.org/glosis/model/procedure/hydraulicConductivityProcedure-KSat_calcul-ptf-saxton	Saturated hydraulic conductivity.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Ksat_invbhole	\N	http://w3id.org/glosis/model/procedure/hydraulicConductivityProcedure-Ksat_invbhole	Saturated hydraulic conductivity. Inverse bore hole method	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
KSat_calcul-ptf	\N	http://w3id.org/glosis/model/procedure/hydraulicConductivityProcedure-KSat_calcul-ptf	Saturated hydraulic conductivity.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
KSat_calcul-ptf-genuchten	\N	http://w3id.org/glosis/model/procedure/hydraulicConductivityProcedure-KSat_calcul-ptf-genuchten	Saturated and not saturated hydraulic conductivity.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Ksat_column	\N	http://w3id.org/glosis/model/procedure/hydraulicConductivityProcedure-Ksat_column	Saturated hydraulic conductivity. Permeability in cm/hr determined in column filled with fine earth fraction	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Ksat_dblring	\N	http://w3id.org/glosis/model/procedure/hydraulicConductivityProcedure-Ksat_dblring	Saturated hydraulic conductivity. Double ring method	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Ksat_bhole	\N	http://w3id.org/glosis/model/procedure/hydraulicConductivityProcedure-Ksat_bhole	Saturated hydraulic conductivity. Bore hole method	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_ap15	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_ap15	Method of Hunter (1975) modified after ISFEI method. Particularly used for available P.	\N	Hunter, A. 1975. New techniques and equipment for routine soil/plant analytical procedures. In: Soil Management in Tropical America. (eds E. Borremiza & A. Alvarado). N.C. State University, Raleigh, NC.
Extr_edta	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_edta	EthyleneDiamineTetraAcetic acid (EDTA) method	https://journals.lww.com/soilsci/Citation/1954/10000/SOIL_AND_PLANT_STUDIES_WITH_CHELATES_OF.8.aspx	\N
Extr_nahco3-olsen	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_nahco3-olsen	Method of Olsen (0.5 M Sodium Bicarbonate (NaHCO3) extraction at pH8.5). Particularly used for available P.	https://acsess.onlinelibrary.wiley.com/doi/book/10.2134/agronmonogr9.2	\N
Extr_hcl-nh4f-bray1	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_hcl-nh4f-bray1	Method of Bray I  (dilute HCl/NH4F). Particularly used for available P.	https://doi.org/10.1097/00010694-194501000-00006	\N
Extr_ap20	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_ap20	Olsen (not acid soils) resp. Bray I (acid soils). Particularly used for available P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_hotwater	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_hotwater	Hot water. Particularly used for available B	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_m3	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_m3	Mehlich3 method (extractant 0.2 N CH3COOH + 0.25 N NH4NO3 + 0.015 N NH4F + 0.013 N HNO3 + 0.001 M EDTA)	https://doi.org/10.1080/00103628409367568	\N
Extr_nahco3-olsen-dabin	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_nahco3-olsen-dabin	Method of Olsen, modified by Dabin (ORSTOM). Particularly used for available P.	https://docplayer.fr/81912854-Application-des-dosages-automatiques-a-l-analyse-des-sols-2e-partie-par.html	\N
Extr_hcl-nh4f-kurtz-bray	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_hcl-nh4f-kurtz-bray	Method of Kurtz-Bray I (0.025 M HCl + 0.03 M NH4F). Particularly used for available P.	https://doi.org/10.1097/00010694-194501000-00006	\N
Extr_ap21	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_ap21	Olsen (if pH > 7) resp. Mehlich (if pH < 7). Particularly used for available P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_capo4	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_capo4	Ca phosphate. Particularly used for available S.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_hcl-h2so4-nelson	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_hcl-h2so4-nelson	Method of Nelson (dilute HCl/H2SO4). Particularly used for available P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_nh4ch3ch-oh-cooh-leuven	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_nh4ch3ch-oh-cooh-leuven	NH4-lactate extraction method (KU-Leuven). Particularly used for available P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_cacl2	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_cacl2	CaCl2. Particularly used for soluble P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_c6h8o7-reeuwijk	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_c6h8o7-reeuwijk	Complexation with citric acid (van Reeuwijk). Particularly used for available P.	https://www.isric.org/documents/document-type/technical-paper-09-procedures-soil-analysis-6th-edition	\N
Extr_hno3	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_hno3	Nitric acid (HNO3) method	https://www.iso.org/standard/60060.html	ISO. ISO/DIS 17586 Soil Quality - Extraction of Trace Elements Using Dilute Nitric Acid, 2016; p 14
Extr_m2	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_m2	Mehlich2 method	https://doi.org/10.1080/00103627609366673	\N
Extr_m3-spec	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_m3-spec	Spectrally measured and converted to Mehlich3 method (extractant 0.2 N CH3COOH + 0.25 N NH4NO3 + 0.015 N NH4F + 0.013 N HNO3 + 0.001 M EDTA)	https://doi.org/10.1080/00103628409367568	\N
Extr_naoac-morgan	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_naoac-morgan	Method of Morgan (Na-acetate/acetic acid). Particularly used for available P.	https://portal.ct.gov/-/media/CAES/DOCUMENTS/Publications/Bulletins/B450pdf.pdf?la=en	\N
Extr_h2so4-truog	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_h2so4-truog	Method of Truog (dilute H2SO4). Particularly used for available P.	https://doi.org/10.2134/agronj1930.00021962002200100008x	\N
Extr_nh4-co3-2-ambic1	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_nh4-co3-2-ambic1	Ambic1 method (ammonium bicarbonate) (South Africa). Particularly used for available P.	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
Extr_ap14	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_ap14	Method of Saunders and Metelerkamp (anion-exch. resin). Particularly used for available P.	\N	Saunders and Metelerkamp
Extr_hcl-nh4f-bray2	\N	http://w3id.org/glosis/model/procedure/extractableElementsProcedure-Extr_hcl-nh4f-bray2	Method of Bray II (dilute HCl/NH4F). Particularly used for available P.	https://doi.org/10.1097/00010694-194501000-00006	\N
TotC_dc-mt	\N	http://w3id.org/glosis/model/procedure/carbonTotalProcedure-TotC_dc-mt	Unacidified dry combustion at medium temperature (550-950 C).	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotC_dc-ht-analyser	\N	http://w3id.org/glosis/model/procedure/carbonTotalProcedure-TotC_dc-ht-analyser	Unacidified dry combustion at high temperature (950-1400 C). Total Carbon (USDA-NRCS method 6A), LECO analyzer at 1140 C	https://www.nrcs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb1253872.pdf	\N
TotC_dc-ht-spec	\N	http://w3id.org/glosis/model/procedure/carbonTotalProcedure-TotC_dc-ht-spec	Spectrally measured and converted to Unacidified dry combustion at high temperature (950-1400 C).	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotC_calcul-ic-oc	\N	http://w3id.org/glosis/model/procedure/carbonTotalProcedure-TotC_calcul-ic-oc	Calculated as sum of inorganic carbon and organic carbon	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
TotC_dc-ht	\N	http://w3id.org/glosis/model/procedure/carbonTotalProcedure-TotC_dc-ht	Unacidified dry combustion at high temperature (950-1400 C). Total Carbon	https://www.isric.org/sites/default/files/isric_report_2014_01.pdf	Leenaars J.G.B., A.J.M. van Oostrum and M. Ruiperez Gonzalez, 2014. Africa Soil Profiles Database, Version 1.2. A compilation of georeferenced and standardised legacy soil profile data for Sub-Saharan Africa (with dataset). ISRIC Report 2014/01. Africa Soil Information Service (AfSIS) project and ISRIC - World Soil Information, Wageningen, the Netherlands. See Annex 4.
\.


--
-- TOC entry 4371 (class 0 OID 54021892)
-- Dependencies: 221
-- Data for Name: profile; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.profile (profile_id, plot_id, surface_id, profile_code) FROM stdin;
\.


--
-- TOC entry 4373 (class 0 OID 54021901)
-- Dependencies: 223
-- Data for Name: project; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.project (project_id, name) FROM stdin;
\.


--
-- TOC entry 4376 (class 0 OID 54021912)
-- Dependencies: 226
-- Data for Name: project_related; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.project_related (project_source_id, project_target_id, role) FROM stdin;
\.


--
-- TOC entry 4387 (class 0 OID 54022004)
-- Dependencies: 237
-- Data for Name: project_site; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.project_site (project_id, site_id) FROM stdin;
\.


--
-- TOC entry 4377 (class 0 OID 54021918)
-- Dependencies: 227
-- Data for Name: property_desc_element; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.property_desc_element (property_desc_element_id, uri) FROM stdin;
saltProperty	http://w3id.org/glosis/model/layerhorizon/saltProperty
biologicalAbundanceProperty	http://w3id.org/glosis/model/layerhorizon/biologicalAbundanceProperty
biologicalFeaturesProperty	http://w3id.org/glosis/model/layerhorizon/biologicalFeaturesProperty
boundaryDistinctnessProperty	http://w3id.org/glosis/model/layerhorizon/boundaryDistinctnessProperty
boundaryTopographyProperty	http://w3id.org/glosis/model/layerhorizon/boundaryTopographyProperty
bulkDensityMineralProperty	http://w3id.org/glosis/model/layerhorizon/bulkDensityMineralProperty
bulkDensityPeatProperty	http://w3id.org/glosis/model/layerhorizon/bulkDensityPeatProperty
carbonatesContentProperty	http://w3id.org/glosis/model/layerhorizon/carbonatesContentProperty
carbonatesFormsProperty	http://w3id.org/glosis/model/layerhorizon/carbonatesFormsProperty
cationExchangeCapacityEffectiveProperty	http://w3id.org/glosis/model/layerhorizon/cationExchangeCapacityEffectiveProperty
cationExchangeCapacityProperty	http://w3id.org/glosis/model/layerhorizon/cationExchangeCapacityProperty
cationsSumProperty	http://w3id.org/glosis/model/layerhorizon/cationsSumProperty
cementationContinuityProperty	http://w3id.org/glosis/model/layerhorizon/cementationContinuityProperty
cementationDegreeProperty	http://w3id.org/glosis/model/layerhorizon/cementationDegreeProperty
cementationFabricProperty	http://w3id.org/glosis/model/layerhorizon/cementationFabricProperty
cementationNatureProperty	http://w3id.org/glosis/model/layerhorizon/cementationNatureProperty
coatingAbundanceProperty	http://w3id.org/glosis/model/layerhorizon/coatingAbundanceProperty
coatingContrastProperty	http://w3id.org/glosis/model/layerhorizon/coatingContrastProperty
coatingFormProperty	http://w3id.org/glosis/model/layerhorizon/coatingFormProperty
coatingLocationProperty	http://w3id.org/glosis/model/layerhorizon/coatingLocationProperty
coatingNatureProperty	http://w3id.org/glosis/model/layerhorizon/coatingNatureProperty
consistenceDryProperty	http://w3id.org/glosis/model/layerhorizon/consistenceDryProperty
consistenceMoistProperty	http://w3id.org/glosis/model/layerhorizon/consistenceMoistProperty
dryConsistencyProperty	http://w3id.org/glosis/model/layerhorizon/dryConsistencyProperty
gypsumContentProperty	http://w3id.org/glosis/model/layerhorizon/gypsumContentProperty
gypsumFormsProperty	http://w3id.org/glosis/model/layerhorizon/gypsumFormsProperty
gypsumWeightProperty	http://w3id.org/glosis/model/layerhorizon/gypsumWeightProperty
mineralConcAbundanceProperty	http://w3id.org/glosis/model/layerhorizon/mineralConcAbundanceProperty
mineralConcColourProperty	http://w3id.org/glosis/model/layerhorizon/mineralConcColourProperty
mineralConcHardnessProperty	http://w3id.org/glosis/model/layerhorizon/mineralConcHardnessProperty
mineralConcKindProperty	http://w3id.org/glosis/model/layerhorizon/mineralConcKindProperty
mineralConcNatureProperty	http://w3id.org/glosis/model/layerhorizon/mineralConcNatureProperty
mineralConcShapeProperty	http://w3id.org/glosis/model/layerhorizon/mineralConcShapeProperty
mineralConcSizeeProperty	http://w3id.org/glosis/model/layerhorizon/mineralConcSizeProperty
mineralConcVolumeProperty	http://w3id.org/glosis/model/layerhorizon/mineralConcVolumeProperty
mineralContentProperty	http://w3id.org/glosis/model/layerhorizon/mineralContentProperty
mineralFragmentsProperty	http://w3id.org/glosis/model/layerhorizon/mineralFragmentsProperty
moistConsistencyProperty	http://w3id.org/glosis/model/layerhorizon/moistConsistencyProperty
mottlesAbundanceProperty	http://w3id.org/glosis/model/layerhorizon/mottlesAbundanceProperty
mottlesColourProperty	http://w3id.org/glosis/model/layerhorizon/mottlesColourProperty
mottlesBoundaryClassificationProperty	http://w3id.org/glosis/model/layerhorizon/mottlesBoundaryClassificationProperty
mottlesContrastProperty	http://w3id.org/glosis/model/layerhorizon/mottlesContrastProperty
mottlesPresenceProperty	http://w3id.org/glosis/model/layerhorizon/mottlesPresenceProperty
mottlesSizeProperty	http://w3id.org/glosis/model/layerhorizon/mottlesSizeProperty
oxalateExtractableOpticalDensityProperty	http://w3id.org/glosis/model/layerhorizon/oxalateExtractableOpticalDensityProperty
ParticleSizeFractionsSumProperty	http://w3id.org/glosis/model/layerhorizon/particleSizeFractionsSumProperty
peatDecompostionProperty	http://w3id.org/glosis/model/layerhorizon/peatDecompostionProperty
peatDrainageProperty	http://w3id.org/glosis/model/layerhorizon/peatDrainageProperty
peatVolumeProperty	http://w3id.org/glosis/model/layerhorizon/peatVolumeProperty
plasticityProperty	http://w3id.org/glosis/model/layerhorizon/plasticityProperty
poresAbundanceProperty	http://w3id.org/glosis/model/layerhorizon/poresAbundanceProperty
poresSizeProperty	http://w3id.org/glosis/model/layerhorizon/poresSizeProperty
porosityClassProperty	http://w3id.org/glosis/model/layerhorizon/porosityClassProperty
rootsAbundanceProperty	http://w3id.org/glosis/model/layerhorizon/rootsAbundanceProperty
RootsPresenceProperty	http://w3id.org/glosis/model/layerhorizon/rootsPresenceProperty
saltContentProperty	http://w3id.org/glosis/model/layerhorizon/saltContentProperty
sandyTextureProperty	http://w3id.org/glosis/model/layerhorizon/sandyTextureProperty
solubleAnionsTotalProperty	http://w3id.org/glosis/model/layerhorizon/solubleAnionsTotalProperty
solubleCationsTotalProperty	http://w3id.org/glosis/model/layerhorizon/solubleCationsTotalProperty
stickinessProperty	http://w3id.org/glosis/model/layerhorizon/stickinessProperty
structureGradeProperty	http://w3id.org/glosis/model/layerhorizon/structureGradeProperty
structureSizeProperty	http://w3id.org/glosis/model/layerhorizon/structureSizeProperty
textureFieldClassProperty	http://w3id.org/glosis/model/layerhorizon/textureFieldClassProperty
textureLabClassProperty	http://w3id.org/glosis/model/layerhorizon/textureLabClassProperty
VoidsClassificationProperty	http://w3id.org/glosis/model/layerhorizon/voidsClassificationProperty
voidsDiameterProperty	http://w3id.org/glosis/model/layerhorizon/voidsDiameterProperty
wetPlasticityProperty	http://w3id.org/glosis/model/layerhorizon/wetPlasticityProperty
bleachedSandProperty	http://w3id.org/glosis/model/common/bleachedSandProperty
colourDryProperty	http://w3id.org/glosis/model/common/colourDryProperty
colourWetProperty	http://w3id.org/glosis/model/common/colourWetProperty
cracksDepthProperty	http://w3id.org/glosis/model/common/cracksDepthProperty
cracksDistanceProperty	http://w3id.org/glosis/model/common/cracksDistanceProperty
cracksWidthProperty	http://w3id.org/glosis/model/common/cracksWidthProperty
fragmentCoverProperty	http://w3id.org/glosis/model/common/fragmentCoverProperty
fragmentSizeProperty	http://w3id.org/glosis/model/common/fragmentSizeProperty
infiltrationRateClassProperty	http://w3id.org/glosis/model/common/infiltrationRateClassProperty
infiltrationRateNumericProperty	http://w3id.org/glosis/model/common/infiltrationRateNumericProperty
organicMatterClassProperty	http://w3id.org/glosis/model/common/organicMatterClassProperty
rockAbundanceProperty	http://w3id.org/glosis/model/common/rockAbundanceProperty
rockShapeProperty	http://w3id.org/glosis/model/common/rockShapeProperty
rockSizeProperty	http://w3id.org/glosis/model/common/rockSizeProperty
textureProperty	http://w3id.org/glosis/model/common/textureProperty
weatheringFragmentsProperty	http://w3id.org/glosis/model/common/weatheringFragmentsProperty
\.


--
-- TOC entry 4378 (class 0 OID 54021926)
-- Dependencies: 228
-- Data for Name: property_desc_plot; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.property_desc_plot (property_desc_plot_id, uri) FROM stdin;
ForestAbundanceProperty	http://w3id.org/glosis/model/siteplot/ForestAbundanceProperty
GrassAbundanceProperty	http://w3id.org/glosis/model/siteplot/GrassAbundanceProperty
PavedAbundanceProperty	http://w3id.org/glosis/model/siteplot/PavedAbundanceProperty
ShrubsAbundaceProperty	http://w3id.org/glosis/model/siteplot/ShrubsAbundanceProperty
bareCoverAbundanceProperty	http://w3id.org/glosis/model/siteplot/bareCoverAbundanceProperty
erosionActivityPeriodProperty	http://w3id.org/glosis/model/siteplot/erosionActivityPeriodProperty
erosionAreaAffectedProperty	http://w3id.org/glosis/model/siteplot/erosionAreaAffectedProperty
erosionCategoryProperty	http://w3id.org/glosis/model/siteplot/erosionCategoryProperty
erosionDegreeProperty	http://w3id.org/glosis/model/siteplot/erosionDegreeProperty
erosionTotalAreaAffectedProperty	http://w3id.org/glosis/model/siteplot/erosionTotalAreaAffectedProperty
floodDurationProperty	http://w3id.org/glosis/model/siteplot/floodDurationProperty
floodFrequencyProperty	http://w3id.org/glosis/model/siteplot/floodFrequencyProperty
geologyProperty	http://w3id.org/glosis/model/siteplot/geologyProperty
groundwaterDepthProperty	http://w3id.org/glosis/model/siteplot/groundwaterDepthProperty
humanInfluenceClassProperty	http://w3id.org/glosis/model/siteplot/humanInfluenceClassProperty
koeppenClassProperty	http://w3id.org/glosis/model/siteplot/koeppenClassProperty
landUseClassProperty	http://w3id.org/glosis/model/siteplot/landUseClassProperty
LandformComplexProperty	http://w3id.org/glosis/model/siteplot/landformComplexProperty
lithologyProperty	http://w3id.org/glosis/model/siteplot/lithologyProperty
MajorLandFormProperty	http://w3id.org/glosis/model/siteplot/majorLandFormProperty
ParentDepositionProperty	http://w3id.org/glosis/model/siteplot/parentDepositionProperty
parentLithologyProperty	http://w3id.org/glosis/model/siteplot/parentLithologyProperty
parentTextureUnconsolidatedProperty	http://w3id.org/glosis/model/siteplot/parentTextureUnconsolidatedProperty
PhysiographyProperty	http://w3id.org/glosis/model/siteplot/physiographyProperty
rockOutcropsCoverProperty	http://w3id.org/glosis/model/siteplot/rockOutcropsCoverProperty
rockOutcropsDistanceProperty	http://w3id.org/glosis/model/siteplot/rockOutcropsDistanceProperty
slopeFormProperty	http://w3id.org/glosis/model/siteplot/slopeFormProperty
slopeGradientClassProperty	http://w3id.org/glosis/model/siteplot/slopeGradientClassProperty
slopeGradientProperty	http://w3id.org/glosis/model/siteplot/slopeGradientProperty
slopeOrientationClassProperty	http://w3id.org/glosis/model/siteplot/slopeOrientationClassProperty
slopeOrientationProperty	http://w3id.org/glosis/model/siteplot/slopeOrientationProperty
slopePathwaysProperty	http://w3id.org/glosis/model/siteplot/slopePathwaysProperty
surfaceAgeProperty	http://w3id.org/glosis/model/siteplot/surfaceAgeProperty
treeDensityProperty	http://w3id.org/glosis/model/siteplot/treeDensityProperty
VegetationClassProperty	http://w3id.org/glosis/model/siteplot/vegetationClassProperty
weatherConditionsCurrentProperty	http://w3id.org/glosis/model/siteplot/weatherConditionsCurrentProperty
weatherConditionsPastProperty	http://w3id.org/glosis/model/siteplot/weatherConditionsPastProperty
weatheringRockProperty	http://w3id.org/glosis/model/siteplot/weatheringRockProperty
soilDepthBedrockProperty	http://w3id.org/glosis/model/common/soilDepthBedrockProperty
soilDepthProperty	http://w3id.org/glosis/model/common/soilDepthProperty
soilDepthRootableClassProperty	http://w3id.org/glosis/model/common/soilDepthRootableClassProperty
soilDepthRootableProperty	http://w3id.org/glosis/model/common/soilDepthRootableProperty
soilDepthSampledProperty	http://w3id.org/glosis/model/common/soilDepthSampledProperty
weatheringFragmentsProperty	http://w3id.org/glosis/model/common/weatheringFragmentsProperty
cropClassProperty	http://w3id.org/glosis/model/siteplot/cropClassProperty
SaltCoverProperty	http://w3id.org/glosis/model/surface/saltCoverProperty
saltPresenceProperty	http://w3id.org/glosis/model/surface/saltPresenceProperty
SaltThicknessProperty	http://w3id.org/glosis/model/surface/saltThicknessProperty
sealingConsistenceProperty	http://w3id.org/glosis/model/surface/sealingConsistenceProperty
sealingThicknessProperty	http://w3id.org/glosis/model/surface/sealingThicknessProperty
bleachedSandProperty	http://w3id.org/glosis/model/common/bleachedSandProperty
colourDryProperty	http://w3id.org/glosis/model/common/colourDryProperty
colourWetProperty	http://w3id.org/glosis/model/common/colourWetProperty
cracksDepthProperty	http://w3id.org/glosis/model/common/cracksDepthProperty
cracksDistanceProperty	http://w3id.org/glosis/model/common/cracksDistanceProperty
cracksWidthProperty	http://w3id.org/glosis/model/common/cracksWidthProperty
fragmentCoverProperty	http://w3id.org/glosis/model/common/fragmentCoverProperty
fragmentSizeProperty	http://w3id.org/glosis/model/common/fragmentSizeProperty
organicMatterClassProperty	http://w3id.org/glosis/model/common/organicMatterClassProperty
rockAbundanceProperty	http://w3id.org/glosis/model/common/rockAbundanceProperty
rockShapeProperty	http://w3id.org/glosis/model/common/rockShapeProperty
rockSizeProperty	http://w3id.org/glosis/model/common/rockSizeProperty
textureProperty	http://w3id.org/glosis/model/common/textureProperty
\.


--
-- TOC entry 4379 (class 0 OID 54021934)
-- Dependencies: 229
-- Data for Name: property_desc_profile; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.property_desc_profile (property_desc_profile_id, uri) FROM stdin;
profileDescriptionStatusProperty	http://w3id.org/glosis/model/profile/profileDescriptionStatusProperty
soilClassificationFAOProperty	http://w3id.org/glosis/model/profile/soilClassificationFAOProperty
soilClassificationUSDAProperty	http://w3id.org/glosis/model/profile/soilClassificationUSDAProperty
soilClassificationWRBProperty	http://w3id.org/glosis/model/profile/soilClassificationWRBProperty
infiltrationRateClassProperty	http://w3id.org/glosis/model/common/infiltrationRateClassProperty
infiltrationRateNumericProperty	http://w3id.org/glosis/model/common/infiltrationRateNumericProperty
soilDepthBedrockProperty	http://w3id.org/glosis/model/common/soilDepthBedrockProperty
soilDepthProperty	http://w3id.org/glosis/model/common/soilDepthProperty
soilDepthRootableClassProperty	http://w3id.org/glosis/model/common/soilDepthRootableClassProperty
soilDepthRootableProperty	http://w3id.org/glosis/model/common/soilDepthRootableProperty
soilDepthSampledProperty	http://w3id.org/glosis/model/common/soilDepthSampledProperty
\.


--
-- TOC entry 4380 (class 0 OID 54021958)
-- Dependencies: 230
-- Data for Name: property_phys_chem; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.property_phys_chem (property_phys_chem_id, uri) FROM stdin;
aluminiumProperty	http://w3id.org/glosis/model/layerhorizon/aluminiumProperty
Calcium (Ca++) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Caltot
Carbon (C) - organic	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Carorg
Carbon (C) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Cartot
Copper (Cu) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Copext
Copper (Cu) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Coptot
Hydrogen (H+) - exchangeable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Hydexc
Iron (Fe) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Iroext
Iron (Fe) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Irotot
Magnesium (Mg++) - exchangeable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Magexc
Magnesium (Mg) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Magext
Magnesium (Mg) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Magtot
Manganese (Mn) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Manext
Manganese (Mn) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Mantot
Nitrogen (N) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Nittot
Phosphorus (P) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Phoext
Phosphorus (P) - retention	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Phoret
Phosphorus (P) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Photot
Potassium (K+) - exchangeable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Potexc
Potassium (K) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Potext
Potassium (K) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Pottot
Sodium (Na) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Sodext
Sodium (Na) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Sodtot
Sulfur (S) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Sulext
Sulfur (S) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Sultot
Clay texture fraction	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Textclay
Sand texture fraction	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Textsand
Silt texture fraction	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Textsilt
Zinc (Zn) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Zinext
pH - Hydrogen potential	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-pH
bulkDensityFineEarthProperty	http://w3id.org/glosis/model/layerhorizon/bulkDensityFineEarthProperty
bulkDensityWholeSoilProperty	http://w3id.org/glosis/model/layerhorizon/bulkDensityWholeSoilProperty
cadmiumProperty	http://w3id.org/glosis/model/layerhorizon/cadmiumProperty
carbonInorganicProperty	http://w3id.org/glosis/model/layerhorizon/carbonInorganicProperty
cationExchangeCapacitycSoilProperty	http://w3id.org/glosis/model/layerhorizon/cationExchangeCapacitycSoilProperty
coarseFragmentsProperty	http://w3id.org/glosis/model/layerhorizon/coarseFragmentsProperty
effectiveCecProperty	http://w3id.org/glosis/model/layerhorizon/effectiveCecProperty
electricalConductivityProperty	http://w3id.org/glosis/model/layerhorizon/electricalConductivityProperty
gypsumProperty	http://w3id.org/glosis/model/layerhorizon/gypsumProperty
hydraulicConductivityProperty	http://w3id.org/glosis/model/layerhorizon/hydraulicConductivityProperty
manganeseProperty	http://w3id.org/glosis/model/layerhorizon/manganeseProperty
molybdenumProperty	http://w3id.org/glosis/model/layerhorizon/molybdenumProperty
organicMatterProperty	http://w3id.org/glosis/model/layerhorizon/organicMatterProperty
pHProperty	http://w3id.org/glosis/model/layerhorizon/pHProperty
porosityProperty	http://w3id.org/glosis/model/layerhorizon/porosityProperty
solubleSaltsProperty	http://w3id.org/glosis/model/layerhorizon/solubleSaltsProperty
totalCarbonateEquivalentProperty	http://w3id.org/glosis/model/layerhorizon/totalCarbonateEquivalentProperty
zincProperty	http://w3id.org/glosis/model/layerhorizon/zincProperty
Acidity - exchangeable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Aciexc
Boron (B) - total	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Bortot
Aluminium (Al+++) - exchangeable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Aluexc
Available water capacity - volumetric (FC to WP)	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Avavol
Base saturation - calculated	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Bascal
Boron (B) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Borext
Calcium (Ca++) - exchangeable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Calexc
Calcium (Ca++) - extractable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Calext
Sodium (Na+) - exchangeable	http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Sodexp
\.


--
-- TOC entry 4381 (class 0 OID 54021966)
-- Dependencies: 231
-- Data for Name: result_desc_element; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.result_desc_element (element_id, property_desc_element_id, thesaurus_desc_element_id) FROM stdin;
\.


--
-- TOC entry 4382 (class 0 OID 54021969)
-- Dependencies: 232
-- Data for Name: result_desc_plot; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.result_desc_plot (plot_id, property_desc_plot_id, thesaurus_desc_plot_id) FROM stdin;
\.


--
-- TOC entry 4383 (class 0 OID 54021972)
-- Dependencies: 233
-- Data for Name: result_desc_profile; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.result_desc_profile (profile_id, property_desc_profile_id, thesaurus_desc_profile_id) FROM stdin;
\.


--
-- TOC entry 4384 (class 0 OID 54021978)
-- Dependencies: 234
-- Data for Name: result_desc_surface; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.result_desc_surface (surface_id, property_desc_plot_id, thesaurus_desc_plot_id) FROM stdin;
\.


--
-- TOC entry 4385 (class 0 OID 54021981)
-- Dependencies: 235
-- Data for Name: result_phys_chem; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.result_phys_chem (result_phys_chem_id, observation_phys_chem_id, specimen_id, individual_id, value) FROM stdin;
\.


--
-- TOC entry 4419 (class 0 OID 54023246)
-- Dependencies: 269
-- Data for Name: result_spectrum; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.result_spectrum (result_spectrum_id, specimen_id, individual_id, spectrum) FROM stdin;
\.


--
-- TOC entry 4386 (class 0 OID 54021997)
-- Dependencies: 236
-- Data for Name: site; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.site (site_id, site_code, typical_profile, "position", extent) FROM stdin;
\.


--
-- TOC entry 4389 (class 0 OID 54022009)
-- Dependencies: 239
-- Data for Name: specimen; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.specimen (specimen_id, element_id, specimen_prep_process_id, organisation_id, code) FROM stdin;
\.


--
-- TOC entry 4390 (class 0 OID 54022015)
-- Dependencies: 240
-- Data for Name: specimen_prep_process; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.specimen_prep_process (specimen_prep_process_id, specimen_transport_id, specimen_storage_id, definition) FROM stdin;
\.


--
-- TOC entry 4393 (class 0 OID 54022025)
-- Dependencies: 243
-- Data for Name: specimen_storage; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.specimen_storage (specimen_storage_id, label, definition) FROM stdin;
\.


--
-- TOC entry 4395 (class 0 OID 54022033)
-- Dependencies: 245
-- Data for Name: specimen_transport; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.specimen_transport (specimen_transport_id, label, definition) FROM stdin;
\.


--
-- TOC entry 4397 (class 0 OID 54022041)
-- Dependencies: 247
-- Data for Name: surface; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.surface (surface_id, super_surface_id, site_id, shape, time_stamp) FROM stdin;
\.


--
-- TOC entry 4398 (class 0 OID 54022047)
-- Dependencies: 248
-- Data for Name: surface_individual; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.surface_individual (surface_id, individual_id) FROM stdin;
\.


--
-- TOC entry 4400 (class 0 OID 54022052)
-- Dependencies: 250
-- Data for Name: thesaurus_desc_element; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.thesaurus_desc_element (thesaurus_desc_element_id, label, uri) FROM stdin;
1	Common	http://w3id.org/glosis/model/codelists/biologicalAbundanceValueCode-C
2	Few	http://w3id.org/glosis/model/codelists/biologicalAbundanceValueCode-F
3	Many	http://w3id.org/glosis/model/codelists/biologicalAbundanceValueCode-M
4	None	http://w3id.org/glosis/model/codelists/biologicalAbundanceValueCode-N
5	Artefacts	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-A
6	Burrows (unspecified)	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-B
7	Infilled large burrows	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-BI
8	Open large burrows	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-BO
9	Charcoal	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-C
10	Earthworm channels	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-E
11	Other insect activity	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-I
12	Pedotubules	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-P
13	Termite or ant channels and nests	http://w3id.org/glosis/model/codelists/biologicalFeaturesValueCode-T
14	Clear	http://w3id.org/glosis/model/codelists/boundaryClassificationValueCode-C
15	Diffuse	http://w3id.org/glosis/model/codelists/boundaryClassificationValueCode-D
16	Sharp	http://w3id.org/glosis/model/codelists/boundaryClassificationValueCode-S
17	Abrupt	http://w3id.org/glosis/model/codelists/boundaryDistinctnessValueCode-A
18	Clear	http://w3id.org/glosis/model/codelists/boundaryDistinctnessValueCode-C
19	Diffuse	http://w3id.org/glosis/model/codelists/boundaryDistinctnessValueCode-D
20	Gradual	http://w3id.org/glosis/model/codelists/boundaryDistinctnessValueCode-G
316	Few	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-F
202	Mica	http://w3id.org/glosis/model/codelists/mineralFragmentsValueCode-MI
21	Broken	http://w3id.org/glosis/model/codelists/boundaryTopographyValueCode-B
22	Irregular	http://w3id.org/glosis/model/codelists/boundaryTopographyValueCode-I
23	Smooth	http://w3id.org/glosis/model/codelists/boundaryTopographyValueCode-S
24	Wavy	http://w3id.org/glosis/model/codelists/boundaryTopographyValueCode-W
25	Many pores, moist materials drop easily out of the auger.	http://w3id.org/glosis/model/codelists/bulkDensityMineralValueCode-BD1
26	Sample disintegrates into numerous fragments after application of weak pressure.	http://w3id.org/glosis/model/codelists/bulkDensityMineralValueCode-BD2
27	Knife can be pushed into the moist soil with weak pressure, sample disintegrates into few fragments, which may be further divided.	http://w3id.org/glosis/model/codelists/bulkDensityMineralValueCode-BD3
28	Knife penetrates only 1–2 cm into the moist soil, some effort required, sample disintegrates into few fragments, which cannot be subdivided further.	http://w3id.org/glosis/model/codelists/bulkDensityMineralValueCode-BD4
29	Very large pressure necessary to force knife into the soil, no further disintegration of sample.	http://w3id.org/glosis/model/codelists/bulkDensityMineralValueCode-BD5
30	< 0.04g cm-3	http://w3id.org/glosis/model/codelists/bulkDensityPeatValueCode-BD1
31	0.04–0.07g cm-3	http://w3id.org/glosis/model/codelists/bulkDensityPeatValueCode-BD2
32	0.07–0.11g cm-3	http://w3id.org/glosis/model/codelists/bulkDensityPeatValueCode-BD3
33	0.11–0.17g cm-3	http://w3id.org/glosis/model/codelists/bulkDensityPeatValueCode-BD4
34	> 0.17g cm-3	http://w3id.org/glosis/model/codelists/bulkDensityPeatValueCode-BD5
35	≈ > 25 Extremely calcareous Extremely strong reaction. Thick foam forms quickly.	http://w3id.org/glosis/model/codelists/carbonatesContentValueCode-EX
36	≈ 2–10 Moderately calcareous Visible effervescence.	http://w3id.org/glosis/model/codelists/carbonatesContentValueCode-MO
37	0 Non-calcareous No detectable visible or audible effervescence.	http://w3id.org/glosis/model/codelists/carbonatesContentValueCode-N
38	≈ 0–2 Slightly calcareous Audible effervescence but not visible.	http://w3id.org/glosis/model/codelists/carbonatesContentValueCode-SL
39	≈ 10–25 Strongly calcareous Strong visible effervescence. Bubbles form a low foam.	http://w3id.org/glosis/model/codelists/carbonatesContentValueCode-ST
40	disperse powdery lime	http://w3id.org/glosis/model/codelists/carbonatesFormsValueCode-D
41	hard concretions	http://w3id.org/glosis/model/codelists/carbonatesFormsValueCode-HC
42	hard hollow concretions	http://w3id.org/glosis/model/codelists/carbonatesFormsValueCode-HHC
43	hard cemented layer or layers of carbonates (less than 10 cm thick)	http://w3id.org/glosis/model/codelists/carbonatesFormsValueCode-HL
44	marl layer	http://w3id.org/glosis/model/codelists/carbonatesFormsValueCode-M
45	pseudomycelia* (carbonate infillings in pores, resembling mycelia)	http://w3id.org/glosis/model/codelists/carbonatesFormsValueCode-PM
46	soft concretions	http://w3id.org/glosis/model/codelists/carbonatesFormsValueCode-SC
47	Broken	http://w3id.org/glosis/model/codelists/cementationContinuityValueCode-B
48	Continuous	http://w3id.org/glosis/model/codelists/cementationContinuityValueCode-C
49	Discontinuous	http://w3id.org/glosis/model/codelists/cementationContinuityValueCode-D
50	Cemented	http://w3id.org/glosis/model/codelists/cementationDegreeValueCode-C
51	Indurated	http://w3id.org/glosis/model/codelists/cementationDegreeValueCode-I
52	Moderately cemented	http://w3id.org/glosis/model/codelists/cementationDegreeValueCode-M
53	Non-cemented and non-compacted	http://w3id.org/glosis/model/codelists/cementationDegreeValueCode-N
54	Weakly cemented	http://w3id.org/glosis/model/codelists/cementationDegreeValueCode-W
55	Compacted but non-cemented	http://w3id.org/glosis/model/codelists/cementationDegreeValueCode-Y
56	Nodular	http://w3id.org/glosis/model/codelists/cementationFabricValueCode-D
57	Pisolithic	http://w3id.org/glosis/model/codelists/cementationFabricValueCode-Pi
58	Platy	http://w3id.org/glosis/model/codelists/cementationFabricValueCode-Pl
59	Vesicular	http://w3id.org/glosis/model/codelists/cementationFabricValueCode-V
60	Clay	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-C
61	Clay–sesquioxides	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-CS
62	Iron	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-F
63	Iron–manganese (sesquioxides)	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-FM
64	Iron–organic matter	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-FO
65	Gypsum	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-GY
66	Ice	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-I
67	Carbonates	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-K
68	Carbonates–silica	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-KQ
69	Mechanical	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-M
70	Not known	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-NK
71	Ploughing	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-P
72	Silica	http://w3id.org/glosis/model/codelists/cementationNatureValueCode-Q
73	Abundant	http://w3id.org/glosis/model/codelists/coatingAbundanceValueCode-A
74	Common	http://w3id.org/glosis/model/codelists/coatingAbundanceValueCode-C
75	Dominant	http://w3id.org/glosis/model/codelists/coatingAbundanceValueCode-D
76	Few	http://w3id.org/glosis/model/codelists/coatingAbundanceValueCode-F
77	Many	http://w3id.org/glosis/model/codelists/coatingAbundanceValueCode-M
78	None	http://w3id.org/glosis/model/codelists/coatingAbundanceValueCode-N
79	Very few 	http://w3id.org/glosis/model/codelists/coatingAbundanceValueCode-V
80	Distinct	http://w3id.org/glosis/model/codelists/coatingContrastValueCode-D
81	Faint	http://w3id.org/glosis/model/codelists/coatingContrastValueCode-F
82	Prominent	http://w3id.org/glosis/model/codelists/coatingContrastValueCode-P
83	Continuous	http://w3id.org/glosis/model/codelists/coatingFormValueCode-C
84	Continuous irregular (non-uniform, heterogeneous)	http://w3id.org/glosis/model/codelists/coatingFormValueCode-CI
85	Discontinuous circular	http://w3id.org/glosis/model/codelists/coatingFormValueCode-DC
86	Dendroidal	http://w3id.org/glosis/model/codelists/coatingFormValueCode-DE
87	Discontinuous irregular	http://w3id.org/glosis/model/codelists/coatingFormValueCode-DI
88	Other	http://w3id.org/glosis/model/codelists/coatingFormValueCode-O
89	Bridges between sand grains	http://w3id.org/glosis/model/codelists/coatingLocationValueCode-BR
90	Coarse fragments	http://w3id.org/glosis/model/codelists/coatingLocationValueCode-CF
91	Lamellae (clay bands)	http://w3id.org/glosis/model/codelists/coatingLocationValueCode-LA
92	No specific location	http://w3id.org/glosis/model/codelists/coatingLocationValueCode-NS
93	Pedfaces	http://w3id.org/glosis/model/codelists/coatingLocationValueCode-P
94	Horizontal pedfaces	http://w3id.org/glosis/model/codelists/coatingLocationValueCode-PH
95	Vertical pedfaces	http://w3id.org/glosis/model/codelists/coatingLocationValueCode-PV
96	Voids	http://w3id.org/glosis/model/codelists/coatingLocationValueCode-VO
97	Clay	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-C
98	Calcium carbonate	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-CC
99	Clay and humus (organic matter)	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-CH
100	Clay and sesquioxides	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-CS
101	Gibbsite	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-GB
102	Humus	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-H
103	Hypodermic coatings (Hypodermic coatings, as used here, are field-scale features, commonly only expressed as hydromorphic features. Micromorphological hypodermic coatings include non-redox features [Bullock et al., 1985].)	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-HC
104	Jarosite	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-JA
105	Manganese	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-MN
106	Pressure faces	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-PF
107	Sesquioxides	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-S
108	Sand coatings	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-SA
109	Shiny faces (as in nitic horizon)	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-SF
110	Slickensides, predominantly intersecting (Slickensides are polished and grooved ped surfaces that are produced by aggregates sliding one past another.)	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-SI
111	Silica (opal)	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-SL
112	Slickensides, non intersecting	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-SN
113	Slickensides, partly intersecting	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-SP
114	Silt coatings	http://w3id.org/glosis/model/codelists/coatingNatureValueCode-ST
115	Extremely hard	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-EHA
116	Hard	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-HA
117	hard to very hard	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-HVH
118	Loose	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-LO
119	Slightly hard	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-SHA
120	slightly hard to hard	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-SHH
121	Soft	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-SO
122	soft to slightly hard	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-SSH
123	Very hard	http://w3id.org/glosis/model/codelists/consistenceDryValueCode-VHA
124	Extremely firm	http://w3id.org/glosis/model/codelists/consistenceMoistValueCode-EFI
125	Firm	http://w3id.org/glosis/model/codelists/consistenceMoistValueCode-FI
126	Friable	http://w3id.org/glosis/model/codelists/consistenceMoistValueCode-FR
127	Loose	http://w3id.org/glosis/model/codelists/consistenceMoistValueCode-LO
128	Very firm 	http://w3id.org/glosis/model/codelists/consistenceMoistValueCode-VFI
129	Very friable	http://w3id.org/glosis/model/codelists/consistenceMoistValueCode-VFR
130	Distinct	http://w3id.org/glosis/model/codelists/contrastValueCode-D
131	Faint	http://w3id.org/glosis/model/codelists/contrastValueCode-F
132	Prominent	http://w3id.org/glosis/model/codelists/contrastValueCode-P
133	Extremely gypsiric	http://w3id.org/glosis/model/codelists/gypsumContentValueCode-EX
134	Moderately gypsiric	http://w3id.org/glosis/model/codelists/gypsumContentValueCode-MO
135	Non-gypsiric	http://w3id.org/glosis/model/codelists/gypsumContentValueCode-N
136	Slightly gypsiric	http://w3id.org/glosis/model/codelists/gypsumContentValueCode-SL
137	Strongly gypsiric	http://w3id.org/glosis/model/codelists/gypsumContentValueCode-ST
138	disperse powdery gypsum	http://w3id.org/glosis/model/codelists/gypsumFormsValueCode-D
139	“gazha” (clayey water-saturated layer with high gypsum content)	http://w3id.org/glosis/model/codelists/gypsumFormsValueCode-G
140	hard cemented layer or layers of gypsum (less than 10 cm thick)	http://w3id.org/glosis/model/codelists/gypsumFormsValueCode-HL
141	soft concretions	http://w3id.org/glosis/model/codelists/gypsumFormsValueCode-SC
142	Bluish-black	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-BB
143	Black	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-BL
144	Brown	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-BR
145	Brownish	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-BS
146	Blue	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-BU
147	Greenish	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-GE
148	Grey	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-GR
149	Greyish	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-GS
150	Multicoloured	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-MC
151	Reddish brown	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-RB
152	Red	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-RE
153	Reddish	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-RS
154	Reddish yellow	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-RY
155	White	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-WH
156	Yellowish brown	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-YB
157	Yellow	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-YE
158	Yellowish red	http://w3id.org/glosis/model/codelists/mineralConcColourValueCode-YR
159	Both hard and soft.	http://w3id.org/glosis/model/codelists/mineralConcHardnessValueCode-B
160	Hard	http://w3id.org/glosis/model/codelists/mineralConcHardnessValueCode-H
161	Soft	http://w3id.org/glosis/model/codelists/mineralConcHardnessValueCode-S
162	Concretion	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-C
163	Crack infillings	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-IC
164	Pore infillings	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-IP
165	Nodule	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-N
166	Other	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-O
167	Residual rock fragment	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-R
168	Soft segregation (or soft accumulation)	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-S
169	Soft concretion	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-SC
170	Crystal	http://w3id.org/glosis/model/codelists/mineralConcKindValueCode-T
171	Clay (argillaceous)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-C
172	Clay–sesquioxides	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-CS
173	Iron (ferruginous)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-F
174	Iron–manganese (sesquioxides)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-FM
175	Gibbsite	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-GB
176	Gypsum (gypsiferous)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-GY
177	Jarosite	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-JA
178	Carbonates (calcareous)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-K
179	Carbonates–silica	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-KQ
180	Manganese (manganiferous)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-M
181	Not known	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-NK
182	Silica (siliceous)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-Q
183	Sulphur (sulphurous)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-S
184	Salt (saline)	http://w3id.org/glosis/model/codelists/mineralConcNatureValueCode-SA
185	Angular	http://w3id.org/glosis/model/codelists/mineralConcShapeValueCode-A
186	Elongated	http://w3id.org/glosis/model/codelists/mineralConcShapeValueCode-E
187	Flat	http://w3id.org/glosis/model/codelists/mineralConcShapeValueCode-F
188	Irregular	http://w3id.org/glosis/model/codelists/mineralConcShapeValueCode-I
189	Rounded (spherical)	http://w3id.org/glosis/model/codelists/mineralConcShapeValueCode-R
190	Coarse	http://w3id.org/glosis/model/codelists/mineralConcSizeValueCode-C
191	Fine	http://w3id.org/glosis/model/codelists/mineralConcSizeValueCode-F
192	Medium	http://w3id.org/glosis/model/codelists/mineralConcSizeValueCode-M
193	Very fine	http://w3id.org/glosis/model/codelists/mineralConcSizeValueCode-V
194	Abundant	http://w3id.org/glosis/model/codelists/mineralConcVolumeValueCode-A
195	Common	http://w3id.org/glosis/model/codelists/mineralConcVolumeValueCode-C
196	Dominant	http://w3id.org/glosis/model/codelists/mineralConcVolumeValueCode-D
197	Few	http://w3id.org/glosis/model/codelists/mineralConcVolumeValueCode-F
198	Many	http://w3id.org/glosis/model/codelists/mineralConcVolumeValueCode-M
199	None	http://w3id.org/glosis/model/codelists/mineralConcVolumeValueCode-N
200	Very few	http://w3id.org/glosis/model/codelists/mineralConcVolumeValueCode-V
201	Feldspar	http://w3id.org/glosis/model/codelists/mineralFragmentsValueCode-FE
203	<Quartz	http://w3id.org/glosis/model/codelists/mineralFragmentsValueCode-QU
204	Abundant	http://w3id.org/glosis/model/codelists/mottlesAbundanceValueCode-A
205	Common	http://w3id.org/glosis/model/codelists/mottlesAbundanceValueCode-C
206	Few	http://w3id.org/glosis/model/codelists/mottlesAbundanceValueCode-F
207	Many	http://w3id.org/glosis/model/codelists/mottlesAbundanceValueCode-M
208	None	http://w3id.org/glosis/model/codelists/mottlesAbundanceValueCode-N
209	Very few	http://w3id.org/glosis/model/codelists/mottlesAbundanceValueCode-V
210	A Coarse	http://w3id.org/glosis/model/codelists/mottlesSizeValueCode-A
211	F Fine	http://w3id.org/glosis/model/codelists/mottlesSizeValueCode-F
212	M Medium	http://w3id.org/glosis/model/codelists/mottlesSizeValueCode-M
213	Very fine	http://w3id.org/glosis/model/codelists/mottlesSizeValueCode-V
214	very low	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-D1
215	low	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-D2
216	moderate	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-D3
217	strong	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-D4
218	moderately strong	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-D5.1
219	very strong	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-D5.2
220	Fibric	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-Fibric
221	Hemic	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-Hemic
222	Sapric	http://w3id.org/glosis/model/codelists/peatDecompostionValueCode-Sapric
223	Undrained	http://w3id.org/glosis/model/codelists/peatDrainageValueCode-DC1
224	Weakly drained	http://w3id.org/glosis/model/codelists/peatDrainageValueCode-DC2
225	Moderately drained	http://w3id.org/glosis/model/codelists/peatDrainageValueCode-DC3
226	Well drained	http://w3id.org/glosis/model/codelists/peatDrainageValueCode-DC4
227	< 3%	http://w3id.org/glosis/model/codelists/peatVolumeValueCode-SV1
228	3– < 5%	http://w3id.org/glosis/model/codelists/peatVolumeValueCode-SV2
229	5– < 8%	http://w3id.org/glosis/model/codelists/peatVolumeValueCode-SV3
230	8– < 12%	http://w3id.org/glosis/model/codelists/peatVolumeValueCode-SV4
231	≥ 12%	http://w3id.org/glosis/model/codelists/peatVolumeValueCode-SV5
232	Non-plastic	http://w3id.org/glosis/model/codelists/plasticityValueCode-NPL
233	Plastic	http://w3id.org/glosis/model/codelists/plasticityValueCode-PL
234	plastic to very plastic	http://w3id.org/glosis/model/codelists/plasticityValueCode-PVP
235	Slightly plastic	http://w3id.org/glosis/model/codelists/plasticityValueCode-SPL
236	slightly plastic to plastic	http://w3id.org/glosis/model/codelists/plasticityValueCode-SPP
237	Very plastic	http://w3id.org/glosis/model/codelists/plasticityValueCode-VPL
238	Common	http://w3id.org/glosis/model/codelists/poresAbundanceValueCode-C
239	Few	http://w3id.org/glosis/model/codelists/poresAbundanceValueCode-F
240	Many	http://w3id.org/glosis/model/codelists/poresAbundanceValueCode-M
241	None	http://w3id.org/glosis/model/codelists/poresAbundanceValueCode-N
242	Very few	http://w3id.org/glosis/model/codelists/poresAbundanceValueCode-V
243	Very low	http://w3id.org/glosis/model/codelists/porosityClassValueCode-1
244	Low	http://w3id.org/glosis/model/codelists/porosityClassValueCode-2
245	Medium	http://w3id.org/glosis/model/codelists/porosityClassValueCode-3
246	High	http://w3id.org/glosis/model/codelists/porosityClassValueCode-4
247	Very high	http://w3id.org/glosis/model/codelists/porosityClassValueCode-5
248	Common	http://w3id.org/glosis/model/codelists/rootsAbundanceValueCode-C
249	Few	http://w3id.org/glosis/model/codelists/rootsAbundanceValueCode-F
250	Many	http://w3id.org/glosis/model/codelists/rootsAbundanceValueCode-M
251	None	http://w3id.org/glosis/model/codelists/rootsAbundanceValueCode-N
252	Very few	http://w3id.org/glosis/model/codelists/rootsAbundanceValueCode-V
253	Extremely salty	http://w3id.org/glosis/model/codelists/saltContentValueCode-EX
254	Moderately salty	http://w3id.org/glosis/model/codelists/saltContentValueCode-MO
255	(nearly)Not salty	http://w3id.org/glosis/model/codelists/saltContentValueCode-N
256	Slightly salty	http://w3id.org/glosis/model/codelists/saltContentValueCode-SL
257	Strongly salty	http://w3id.org/glosis/model/codelists/saltContentValueCode-ST
258	Very strongly salty	http://w3id.org/glosis/model/codelists/saltContentValueCode-VST
259	Coarse sand	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-CS
260	Coarse sandy loam	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-CSL
261	Fine sand	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-FS
262	Fine sandy loam	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-FSL
263	Loamy coarse sand	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-LCS
264	Loamy fine sand	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-LFS
265	Loamy very fine sand	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-LVFS
266	Medium sand	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-MS
267	Sand, unsorted	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-US
268	Very fine sand	http://w3id.org/glosis/model/codelists/sandyTextureValueCode-VFS
269	Non-sticky	http://w3id.org/glosis/model/codelists/stickinessValueCode-NST
270	slightly sticky to sticky	http://w3id.org/glosis/model/codelists/stickinessValueCode-SSS
271	Slightly sticky	http://w3id.org/glosis/model/codelists/stickinessValueCode-SST
272	Sticky	http://w3id.org/glosis/model/codelists/stickinessValueCode-ST
273	sticky to very sticky	http://w3id.org/glosis/model/codelists/stickinessValueCode-SVS
274	Very sticky	http://w3id.org/glosis/model/codelists/stickinessValueCode-VST
275	Moderate	http://w3id.org/glosis/model/codelists/structureGradeValueCode-MO
276	Moderate to strong	http://w3id.org/glosis/model/codelists/structureGradeValueCode-MS
277	Strong	http://w3id.org/glosis/model/codelists/structureGradeValueCode-ST
278	Weak	http://w3id.org/glosis/model/codelists/structureGradeValueCode-WE
279	Weak to moderate	http://w3id.org/glosis/model/codelists/structureGradeValueCode-WM
280	Coarse/thick	http://w3id.org/glosis/model/codelists/structureSizeValueCode-CO
281	Extremely coarse	http://w3id.org/glosis/model/codelists/structureSizeValueCode-EC
282	Fine/thin	http://w3id.org/glosis/model/codelists/structureSizeValueCode-FI
283	Medium	http://w3id.org/glosis/model/codelists/structureSizeValueCode-ME
284	Very coarse/thick	http://w3id.org/glosis/model/codelists/structureSizeValueCode-VC
285	Very fine/thin	http://w3id.org/glosis/model/codelists/structureSizeValueCode-VF
286	Vesicular	http://w3id.org/glosis/model/codelists/voidsClassificationValueCode-B
287	Channels	http://w3id.org/glosis/model/codelists/voidsClassificationValueCode-C
288	Interstitial	http://w3id.org/glosis/model/codelists/voidsClassificationValueCode-I
289	Planes	http://w3id.org/glosis/model/codelists/voidsClassificationValueCode-P
290	Vughs	http://w3id.org/glosis/model/codelists/voidsClassificationValueCode-V
291	Coarse	http://w3id.org/glosis/model/codelists/voidsDiameterValueCode-C
292	Fine	http://w3id.org/glosis/model/codelists/voidsDiameterValueCode-F
293	fine and very fine	http://w3id.org/glosis/model/codelists/voidsDiameterValueCode-FF
294	fine and medium	http://w3id.org/glosis/model/codelists/voidsDiameterValueCode-FM
295	Medium	http://w3id.org/glosis/model/codelists/voidsDiameterValueCode-M
296	medium and coarse	http://w3id.org/glosis/model/codelists/voidsDiameterValueCode-MC
297	Very fine	http://w3id.org/glosis/model/codelists/voidsDiameterValueCode-V
298	Very coarse	http://w3id.org/glosis/model/codelists/voidsDiameterValueCode-VC
299	Deep 10–20	http://w3id.org/glosis/model/codelists/cracksDepthValueCode-D
300	Medium 2–10	http://w3id.org/glosis/model/codelists/cracksDepthValueCode-M
301	Surface < 2	http://w3id.org/glosis/model/codelists/cracksDepthValueCode-S
302	Very deep > 20	http://w3id.org/glosis/model/codelists/cracksDepthValueCode-V
303	Very closely spaced < 0.2	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-C
304	Closely spaced 0.2–0.5	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-D
305	Moderately widely spaced 0.5–2	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-M
306	Very widely spaced > 5	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-V
307	Widely spaced 2–5	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-W
308	Extremely wide > 10cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-E
309	Fine < 1cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-F
310	Medium 1cm–2cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-M
311	Very wide 5cm–10cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-V
312	Wide 2cm–5cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-W
313	Abundant	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-A
314	Common 	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-C
315	Dominant	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-D
317	Many	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-M
318	None	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-N
319	Very few	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-V
320	Boulders	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-B
321	Coarse gravel	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-C
322	Fine gravel	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-F
323	Large boulders	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-L
324	Medium gravel	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-M
325	Stones	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-S
326	Abundant 	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-A
327	Common	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-C
328	Dominant	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-D
329	Few	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-F
330	Many	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-M
331	None	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-N
332	Stone line	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-S
333	Very few	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-V
334	Angular	http://w3id.org/glosis/model/codelists/rockShapeValueCode-A
335	Flat	http://w3id.org/glosis/model/codelists/rockShapeValueCode-F
336	Rounded	http://w3id.org/glosis/model/codelists/rockShapeValueCode-R
337	Subrounded	http://w3id.org/glosis/model/codelists/rockShapeValueCode-S
338	Artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-A
339	Coarse artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-AC
340	Fine artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-AF
341	Medium artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-AM
342	Very fine artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-AV
343	Boulders and large boulders	http://w3id.org/glosis/model/codelists/rockSizeValueCode-BL
344	Combination of classes	http://w3id.org/glosis/model/codelists/rockSizeValueCode-C
345	Coarse gravel and stones	http://w3id.org/glosis/model/codelists/rockSizeValueCode-CS
346	Fine and medium gravel/artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-FM
347	Medium and coarse gravel/artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-MC
348	Rock fragments	http://w3id.org/glosis/model/codelists/rockSizeValueCode-R
349	Boulders	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RB
350	Coarse gravel	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RC
351	Fine gravel	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RF
352	Large boulders	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RL
353	Medium gravel	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RM
354	Stones	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RS
355	Stones and boulders	http://w3id.org/glosis/model/codelists/rockSizeValueCode-SB
356	Fresh or slightly weathered	http://w3id.org/glosis/model/codelists/weatheringValueCode-F
357	Strongly weathered	http://w3id.org/glosis/model/codelists/weatheringValueCode-S
358	Weathered	http://w3id.org/glosis/model/codelists/weatheringValueCode-W
\.


--
-- TOC entry 4402 (class 0 OID 54022060)
-- Dependencies: 252
-- Data for Name: thesaurus_desc_plot; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.thesaurus_desc_plot (thesaurus_desc_plot_id, label, uri) FROM stdin;
1	Cereals	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce
68	Mass movement	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-M
2	Barley	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_Ba
3	Maize	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_Ma
4	Millet	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_Mi
5	Oats	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_Oa
6	Rice, paddy	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_Pa
7	Rice, dry	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_Ri
8	Rye	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_Ry
9	Sorghum	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_So
10	Wheat	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ce_Wh
11	Fibre crops	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fi
12	Cotton	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fi_Co
13	Jute	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fi_Ju
14	Fodder plants	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fo
18	Hay	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fo_Ha
180	Terraced	http://w3id.org/glosis/model/codelists/landformComplexValueCode-TE
246	glacial	http://w3id.org/glosis/model/codelists/lithologyValueCode-UG
15	Alfalfa	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fo_Al
16	Clover	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fo_Cl
17	Grasses	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fo_Gr
19	Leguminous	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fo_Le
20	Maize	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fo_Ma
21	Pumpkins	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fo_Pu
22	Fruits and melons	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fr
23	Apples	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fr_Ap
24	Bananas	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fr_Ba
25	Citrus	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fr_Ci
26	Grapes, Wine, Raisins	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fr_Gr
27	Mangoes	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fr_Ma
28	Melons	http://w3id.org/glosis/model/codelists/cropClassValueCode-Fr_Me
29	Semi-luxury foods and tobacco	http://w3id.org/glosis/model/codelists/cropClassValueCode-Lu
30	Cocoa	http://w3id.org/glosis/model/codelists/cropClassValueCode-Lu_Cc
31	Coffee	http://w3id.org/glosis/model/codelists/cropClassValueCode-Lu_Co
32	Tea	http://w3id.org/glosis/model/codelists/cropClassValueCode-Lu_Te
33	Tobacco	http://w3id.org/glosis/model/codelists/cropClassValueCode-Lu_To
34	Oilcrops	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi
35	Coconuts	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi_Cc
36	Groundnuts	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi_Gr
37	Linseed	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi_Li
38	Oil-palm	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi_Op
39	Rape	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi_Ra
40	Sesame	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi_Se
41	Soybeans	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi_So
42	Sunflower	http://w3id.org/glosis/model/codelists/cropClassValueCode-Oi_Su
43	Olives	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ol
44	Other crops	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ot
45	Palm (fibres, kernels)	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ot_Pa
46	Rubber	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ot_Ru
47	Sugar cane	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ot_Sc
48	Pulses	http://w3id.org/glosis/model/codelists/cropClassValueCode-Pu
49	Beans	http://w3id.org/glosis/model/codelists/cropClassValueCode-Pu_Be
50	Lentils	http://w3id.org/glosis/model/codelists/cropClassValueCode-Pu_Le
51	Peas	http://w3id.org/glosis/model/codelists/cropClassValueCode-Pu_Pe
52	Roots and tubers	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ro
53	Cassava	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ro_Ca
54	Potatoes	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ro_Po
55	Sugar beets	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ro_Su
56	Yams	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ro_Ya
57	Vegetables	http://w3id.org/glosis/model/codelists/cropClassValueCode-Ve
58	Active at present	http://w3id.org/glosis/model/codelists/erosionActivityPeriodValueCode-A
59	Active in historical times	http://w3id.org/glosis/model/codelists/erosionActivityPeriodValueCode-H
60	Period of activity not known	http://w3id.org/glosis/model/codelists/erosionActivityPeriodValueCode-N
61	Active in recent past	http://w3id.org/glosis/model/codelists/erosionActivityPeriodValueCode-R
62	Accelerated and natural erosion not distinguished	http://w3id.org/glosis/model/codelists/erosionActivityPeriodValueCode-X
63	Wind (aeolian) erosion or deposition	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-A
64	Wind deposition	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-AD
65	Wind erosion and deposition	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-AM
66	Shifting sands	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-AS
67	Salt deposition	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-AZ
69	No evidence of erosion	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-N
70	Not known	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-NK
71	Water erosion or deposition	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-W
72	Water and wind erosion	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-WA
73	Deposition by water	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-WD
74	Gully erosion	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-WG
75	Rill erosion	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-WR
76	Sheet erosion	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-WS
77	Tunnel erosion	http://w3id.org/glosis/model/codelists/erosionCategoryValueCode-WT
78	Extreme	http://w3id.org/glosis/model/codelists/erosionDegreeValueCode-E
79	Moderate	http://w3id.org/glosis/model/codelists/erosionDegreeValueCode-M
80	Slight	http://w3id.org/glosis/model/codelists/erosionDegreeValueCode-S
81	Severe	http://w3id.org/glosis/model/codelists/erosionDegreeValueCode-V
82	0	http://w3id.org/glosis/model/codelists/erosionTotalAreaAffectedValueCode-0
83	0–5	http://w3id.org/glosis/model/codelists/erosionTotalAreaAffectedValueCode-1
84	5–10	http://w3id.org/glosis/model/codelists/erosionTotalAreaAffectedValueCode-2
85	10–25	http://w3id.org/glosis/model/codelists/erosionTotalAreaAffectedValueCode-3
86	25–50	http://w3id.org/glosis/model/codelists/erosionTotalAreaAffectedValueCode-4
87	> 50	http://w3id.org/glosis/model/codelists/erosionTotalAreaAffectedValueCode-5
88	Archaeological (burial mound, midden)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-AC
89	Artificial drainage	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-AD
90	Borrow pit	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-BP
91	Burning	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-BR
92	Bunding	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-BU
93	Clearing	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-CL
94	Impact crater	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-CR
95	Dump (not specified)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-DU
96	Application of fertilizers	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-FE
97	Border irrigation	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-IB
98	Drip irrigation	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-ID
99	Furrow irrigation	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-IF
100	Flood irrigation	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-IP
101	Sprinkler irrigation	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-IS
102	Irrigation (not specified)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-IU
103	Landfill (also sanitary)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-LF
104	Levelling	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-LV
105	Raised beds (engineering purposes)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-ME
106	Mine (surface, including openpit, gravel and quarries)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-MI
107	Organic additions (not specified)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-MO
108	Plaggen	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-MP
109	Raised beds (agricultural purposes)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-MR
110	Sand additions	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-MS
111	Mineral additions (not specified)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-MU
112	No influence	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-N
113	Not known	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-NK
114	Ploughing	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-PL
115	Pollution	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-PO
116	Scalped area	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-SA
117	Surface compaction	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-SC
118	Terracing	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-TE
119	Vegetation strongly disturbed	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-VE
120	Vegetation moderately disturbed	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-VM
121	Vegetation slightly disturbed	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-VS
122	Vegetation disturbed (not specified)	http://w3id.org/glosis/model/codelists/humanInfluenceClassValueCode-VU
123	A = Crop agriculture (cropping)	http://w3id.org/glosis/model/codelists/landUseClassValueCode-A
124	Annual field cropping	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AA
125	Shifting cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AA1
126	Fallow system cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AA2
127	Ley system cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AA3
128	Rainfed arable cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AA4
129	Wet rice cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AA5
130	Irrigated cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AA6
131	Perennial field cropping	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AP
132	Non-irrigated cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AP1
133	Irrigated cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AP2
134	Tree and shrub cropping	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AT
135	Non-irrigated tree crop cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AT1
136	Irrigated tree crop cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AT2
137	Non-irrigated shrub crop cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AT3
138	Irrigated shrub crop cultivation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-AT4
139	F = Forestry	http://w3id.org/glosis/model/codelists/landUseClassValueCode-F
140	Natural forest and woodland	http://w3id.org/glosis/model/codelists/landUseClassValueCode-FN
141	Selective felling	http://w3id.org/glosis/model/codelists/landUseClassValueCode-FN1
142	Clear felling	http://w3id.org/glosis/model/codelists/landUseClassValueCode-FN2
143	Plantation forestry	http://w3id.org/glosis/model/codelists/landUseClassValueCode-FP
144	H = Animal husbandry	http://w3id.org/glosis/model/codelists/landUseClassValueCode-H
145	Extensive grazing	http://w3id.org/glosis/model/codelists/landUseClassValueCode-HE
146	Nomadism	http://w3id.org/glosis/model/codelists/landUseClassValueCode-HE1
147	Semi-nomadism	http://w3id.org/glosis/model/codelists/landUseClassValueCode-HE2
148	Ranching	http://w3id.org/glosis/model/codelists/landUseClassValueCode-HE3
149	Intensive grazing	http://w3id.org/glosis/model/codelists/landUseClassValueCode-HI
150	Animal production	http://w3id.org/glosis/model/codelists/landUseClassValueCode-HI1
151	Dairying	http://w3id.org/glosis/model/codelists/landUseClassValueCode-HI2
152	M = Mixed farming	http://w3id.org/glosis/model/codelists/landUseClassValueCode-M
153	Agroforestry	http://w3id.org/glosis/model/codelists/landUseClassValueCode-MF
154	Agropastoralism	http://w3id.org/glosis/model/codelists/landUseClassValueCode-MP
155	Other land uses	http://w3id.org/glosis/model/codelists/landUseClassValueCode-Oi
156	P = Nature protection	http://w3id.org/glosis/model/codelists/landUseClassValueCode-P
157	Degradation control	http://w3id.org/glosis/model/codelists/landUseClassValueCode-PD
158	Without interference	http://w3id.org/glosis/model/codelists/landUseClassValueCode-PD1
159	With interference	http://w3id.org/glosis/model/codelists/landUseClassValueCode-PD2
160	Nature and game preservation	http://w3id.org/glosis/model/codelists/landUseClassValueCode-PN
161	Reserves	http://w3id.org/glosis/model/codelists/landUseClassValueCode-PN1
162	Parks	http://w3id.org/glosis/model/codelists/landUseClassValueCode-PN2
163	Wildlife management	http://w3id.org/glosis/model/codelists/landUseClassValueCode-PN3
164	S = Settlement, industry	http://w3id.org/glosis/model/codelists/landUseClassValueCode-S
165	Recreational use	http://w3id.org/glosis/model/codelists/landUseClassValueCode-SC
166	Disposal sites	http://w3id.org/glosis/model/codelists/landUseClassValueCode-SD
167	Industrial use	http://w3id.org/glosis/model/codelists/landUseClassValueCode-SI
168	Residential use	http://w3id.org/glosis/model/codelists/landUseClassValueCode-SR
169	Transport	http://w3id.org/glosis/model/codelists/landUseClassValueCode-ST
170	Excavations	http://w3id.org/glosis/model/codelists/landUseClassValueCode-SX
171	Not used and not managed	http://w3id.org/glosis/model/codelists/landUseClassValueCode-U
172	Military area	http://w3id.org/glosis/model/codelists/landUseClassValueCode-Y
173	Cuesta-shaped	http://w3id.org/glosis/model/codelists/landformComplexValueCode-CU
174	Dome-shaped	http://w3id.org/glosis/model/codelists/landformComplexValueCode-DO
175	Dune-shaped	http://w3id.org/glosis/model/codelists/landformComplexValueCode-DU
176	With intermontane plains (occupying > 15%) 	http://w3id.org/glosis/model/codelists/landformComplexValueCode-IM
177	Inselberg covered (occupying > 1% of level land) 	http://w3id.org/glosis/model/codelists/landformComplexValueCode-IN
178	Strong karst	http://w3id.org/glosis/model/codelists/landformComplexValueCode-KA
179	Ridged 	http://w3id.org/glosis/model/codelists/landformComplexValueCode-RI
181	With wetlands (occupying > 15%)	http://w3id.org/glosis/model/codelists/landformComplexValueCode-WE
182	igneous rock	http://w3id.org/glosis/model/codelists/lithologyValueCode-I
183	acid igneous	http://w3id.org/glosis/model/codelists/lithologyValueCode-IA
184	diorite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IA1
185	grano-diorite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IA2
186	quartz-diorite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IA3
187	rhyolite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IA4
188	basic igneous	http://w3id.org/glosis/model/codelists/lithologyValueCode-IB
189	gabbro	http://w3id.org/glosis/model/codelists/lithologyValueCode-IB1
190	basalt	http://w3id.org/glosis/model/codelists/lithologyValueCode-IB2
191	dolerite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IB3
192	intermediate igneous	http://w3id.org/glosis/model/codelists/lithologyValueCode-II
193	andesite, trachyte, phonolite	http://w3id.org/glosis/model/codelists/lithologyValueCode-II1
194	diorite-syenite	http://w3id.org/glosis/model/codelists/lithologyValueCode-II2
195	pyroclastic	http://w3id.org/glosis/model/codelists/lithologyValueCode-IP
196	tuff, tuffite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IP1
197	volcanic scoria/breccia	http://w3id.org/glosis/model/codelists/lithologyValueCode-IP2
198	volcanic ash	http://w3id.org/glosis/model/codelists/lithologyValueCode-IP3
199	ignimbrite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IP4
200	ultrabasic igneous	http://w3id.org/glosis/model/codelists/lithologyValueCode-IU
201	peridotite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IU1
202	pyroxenite	http://w3id.org/glosis/model/codelists/lithologyValueCode-IU2
203	ilmenite, magnetite, ironstone, serpentine	http://w3id.org/glosis/model/codelists/lithologyValueCode-IU3
204	metamorphic rock	http://w3id.org/glosis/model/codelists/lithologyValueCode-M
205	acid metamorphic	http://w3id.org/glosis/model/codelists/lithologyValueCode-MA
206	quartzite	http://w3id.org/glosis/model/codelists/lithologyValueCode-MA1
207	gneiss, migmatite	http://w3id.org/glosis/model/codelists/lithologyValueCode-MA2
208	slate, phyllite (pelitic rocks)	http://w3id.org/glosis/model/codelists/lithologyValueCode-MA3
209	schist	http://w3id.org/glosis/model/codelists/lithologyValueCode-MA4
210	basic metamorphic	http://w3id.org/glosis/model/codelists/lithologyValueCode-MB
211	slate, phyllite (pelitic rocks)	http://w3id.org/glosis/model/codelists/lithologyValueCode-MB1
212	(green)schist	http://w3id.org/glosis/model/codelists/lithologyValueCode-MB2
213	gneiss rich in Fe–Mg minerals	http://w3id.org/glosis/model/codelists/lithologyValueCode-MB3
214	metamorphic limestone (marble)	http://w3id.org/glosis/model/codelists/lithologyValueCode-MB4
215	amphibolite	http://w3id.org/glosis/model/codelists/lithologyValueCode-MB5
216	eclogite	http://w3id.org/glosis/model/codelists/lithologyValueCode-MB6
217	ultrabasic metamorphic	http://w3id.org/glosis/model/codelists/lithologyValueCode-MU
218	serpentinite, greenstone	http://w3id.org/glosis/model/codelists/lithologyValueCode-MU1
219	sedimentary rock (consolidated)	http://w3id.org/glosis/model/codelists/lithologyValueCode-S
220	clastic sediments	http://w3id.org/glosis/model/codelists/lithologyValueCode-SC
221	conglomerate, breccia	http://w3id.org/glosis/model/codelists/lithologyValueCode-SC1
222	sandstone, greywacke, arkose	http://w3id.org/glosis/model/codelists/lithologyValueCode-SC2
223	silt-, mud-, claystone	http://w3id.org/glosis/model/codelists/lithologyValueCode-SC3
224	shale	http://w3id.org/glosis/model/codelists/lithologyValueCode-SC4
225	ironstone	http://w3id.org/glosis/model/codelists/lithologyValueCode-SC5
226	evaporites	http://w3id.org/glosis/model/codelists/lithologyValueCode-SE
227	anhydrite, gypsum	http://w3id.org/glosis/model/codelists/lithologyValueCode-SE1
228	halite	http://w3id.org/glosis/model/codelists/lithologyValueCode-SE2
229	carbonatic, organic	http://w3id.org/glosis/model/codelists/lithologyValueCode-SO
230	limestone, other carbonate rock	http://w3id.org/glosis/model/codelists/lithologyValueCode-SO1
231	marl and other mixtures	http://w3id.org/glosis/model/codelists/lithologyValueCode-SO2
232	coals, bitumen and related rocks	http://w3id.org/glosis/model/codelists/lithologyValueCode-SO3
233	sedimentary rock (unconsolidated)	http://w3id.org/glosis/model/codelists/lithologyValueCode-U
234	anthropogenic/technogenic	http://w3id.org/glosis/model/codelists/lithologyValueCode-UA
235	redeposited natural material	http://w3id.org/glosis/model/codelists/lithologyValueCode-UA1
236	industrial/artisanal deposits	http://w3id.org/glosis/model/codelists/lithologyValueCode-UA2
237	colluvial	http://w3id.org/glosis/model/codelists/lithologyValueCode-UC
238	slope deposits	http://w3id.org/glosis/model/codelists/lithologyValueCode-UC1
239	lahar	http://w3id.org/glosis/model/codelists/lithologyValueCode-UC2
240	eolian	http://w3id.org/glosis/model/codelists/lithologyValueCode-UE
241	loess	http://w3id.org/glosis/model/codelists/lithologyValueCode-UE1
242	sand	http://w3id.org/glosis/model/codelists/lithologyValueCode-UE2
243	fluvial	http://w3id.org/glosis/model/codelists/lithologyValueCode-UF
244	sand and gravel	http://w3id.org/glosis/model/codelists/lithologyValueCode-UF1
245	clay, silt and loam	http://w3id.org/glosis/model/codelists/lithologyValueCode-UF2
247	moraine	http://w3id.org/glosis/model/codelists/lithologyValueCode-UG1
248	UG2 glacio-fluvial sand	http://w3id.org/glosis/model/codelists/lithologyValueCode-UG2
249	UG3 glacio-fluvial gravel	http://w3id.org/glosis/model/codelists/lithologyValueCode-UG3
250	kryogenic	http://w3id.org/glosis/model/codelists/lithologyValueCode-UK
251	periglacial rock debris	http://w3id.org/glosis/model/codelists/lithologyValueCode-UK1
252	periglacial solifluction layer	http://w3id.org/glosis/model/codelists/lithologyValueCode-UK2
253	lacustrine	http://w3id.org/glosis/model/codelists/lithologyValueCode-UL
254	sand	http://w3id.org/glosis/model/codelists/lithologyValueCode-UL1
255	silt and clay	http://w3id.org/glosis/model/codelists/lithologyValueCode-UL2
256	marine, estuarine	http://w3id.org/glosis/model/codelists/lithologyValueCode-UM
257	sand	http://w3id.org/glosis/model/codelists/lithologyValueCode-UM1
258	clay and silt	http://w3id.org/glosis/model/codelists/lithologyValueCode-UM2
259	organic	http://w3id.org/glosis/model/codelists/lithologyValueCode-UO
260	rainwater-fed moor peat	http://w3id.org/glosis/model/codelists/lithologyValueCode-UO1
261	groundwater-fed bog peat	http://w3id.org/glosis/model/codelists/lithologyValueCode-UO2
262	weathered residuum	http://w3id.org/glosis/model/codelists/lithologyValueCode-UR
263	bauxite, laterite	http://w3id.org/glosis/model/codelists/lithologyValueCode-UR1
264	unspecified deposits	http://w3id.org/glosis/model/codelists/lithologyValueCode-UU
265	clay	http://w3id.org/glosis/model/codelists/lithologyValueCode-UU1
266	loam and silt	http://w3id.org/glosis/model/codelists/lithologyValueCode-UU2
267	sand	http://w3id.org/glosis/model/codelists/lithologyValueCode-UU3
268	gravelly sand	http://w3id.org/glosis/model/codelists/lithologyValueCode-UU4
269	gravel, broken rock	http://w3id.org/glosis/model/codelists/lithologyValueCode-UU5
270	level land 	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-L
271	depression	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-LD
272	plateau	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-LL
273	plain	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-LP
274	valley floor	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-LV
275	sloping land 	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-S
276	medium-gradient escarpment zone	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-SE
277	medium-gradient hill	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-SH
278	medium-gradient mountain	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-SM
279	dissected plain	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-SP
280	medium-gradient valley	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-SV
281	steep land	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-T
282	high-gradient escarpment zone	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-TE
283	high-gradient hill	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-TH
284	high-gradient mountain	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-TM
285	high-gradient valley	http://w3id.org/glosis/model/codelists/majorLandFormValueCode-TV
286	Bottom (drainage line)	http://w3id.org/glosis/model/codelists/physiographyValueCode-BOdl
287	Bottom (flat)	http://w3id.org/glosis/model/codelists/physiographyValueCode-BOf
288	Crest (summit)	http://w3id.org/glosis/model/codelists/physiographyValueCode-CR
289	Higher part (rise)	http://w3id.org/glosis/model/codelists/physiographyValueCode-HI
290	Intermediate part (talf)	http://w3id.org/glosis/model/codelists/physiographyValueCode-IN
291	Lower part (and dip)	http://w3id.org/glosis/model/codelists/physiographyValueCode-LO
292	Lower slope (foot slope)	http://w3id.org/glosis/model/codelists/physiographyValueCode-LS
293	Middle slope (back slope) 	http://w3id.org/glosis/model/codelists/physiographyValueCode-MS
294	Toe slope	http://w3id.org/glosis/model/codelists/physiographyValueCode-TS
295	Upper slope (shoulder) 	http://w3id.org/glosis/model/codelists/physiographyValueCode-UP
296	Abundant	http://w3id.org/glosis/model/codelists/rockOutcropsCoverValueCode-A
297	Common	http://w3id.org/glosis/model/codelists/rockOutcropsCoverValueCode-C
298	Dominant	http://w3id.org/glosis/model/codelists/rockOutcropsCoverValueCode-D
299	Few	http://w3id.org/glosis/model/codelists/rockOutcropsCoverValueCode-F
300	Many	http://w3id.org/glosis/model/codelists/rockOutcropsCoverValueCode-M
301	None	http://w3id.org/glosis/model/codelists/rockOutcropsCoverValueCode-N
302	Very few	http://w3id.org/glosis/model/codelists/rockOutcropsCoverValueCode-V
303	> 50	http://w3id.org/glosis/model/codelists/rockOutcropsDistanceValueCode-1
304	20–50	http://w3id.org/glosis/model/codelists/rockOutcropsDistanceValueCode-2
305	5–20	http://w3id.org/glosis/model/codelists/rockOutcropsDistanceValueCode-3
306	2–5	http://w3id.org/glosis/model/codelists/rockOutcropsDistanceValueCode-4
307	< 2	http://w3id.org/glosis/model/codelists/rockOutcropsDistanceValueCode-5
308	concave	http://w3id.org/glosis/model/codelists/slopeFormValueCode-C
309	straight	http://w3id.org/glosis/model/codelists/slopeFormValueCode-S
310	terraced	http://w3id.org/glosis/model/codelists/slopeFormValueCode-T
311	convex	http://w3id.org/glosis/model/codelists/slopeFormValueCode-V
312	complex (irregular)	http://w3id.org/glosis/model/codelists/slopeFormValueCode-X
313	Flat	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-01
314	Level	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-02
315	Nearly level	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-03
316	Very gently sloping 	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-04
317	Gently sloping	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-05
318	Sloping	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-06
319	Strongly sloping	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-07
320	Moderately steep	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-08
321	Steep	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-09
322	Very steep	http://w3id.org/glosis/model/codelists/slopeGradientClassValueCode-10
323	CC	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-CC
324	CS	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-CS
325	CV	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-CV
326	SC	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-SC
327	SS	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-SS
328	SV	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-SV
329	VC	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-VC
330	VS	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-VS
331	VV	http://w3id.org/glosis/model/codelists/slopePathwaysValueCode-VV
332	Holocene anthropogeomorphic	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-Ha
333	Holocene natural	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-Hn
334	Older, pre-Tertiary land surfaces	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-O
335	Tertiary land surfaces	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-T
336	Young anthropogeomorphic	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-Ya
337	Young natural	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-Yn
338	Late Pleistocene, without periglacial influence.	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-lPf
339	Late Pleistocene, ice covered	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-lPi
340	Late Pleistocene, periglacial	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-lPp
341	Older Pleistocene, without periglacial influence.	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-oPf
342	Older Pleistocene, ice covered	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-oPi
343	Older Pleistocene, with periglacial influence	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-oPp
344	Very young anthropogeomorphic	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-vYa
345	Very young natural	http://w3id.org/glosis/model/codelists/surfaceAgeValueCode-vYn
346	Groundwater-fed bog peat	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-B
347	Dwarf shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-D
348	Deciduous dwarf shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-DD
349	Evergreen dwarf shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-DE
350	Semi-deciduous dwarf shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-DS
351	Tundra	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-DT
352	Xermomorphic dwarf shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-DX
353	Closed forest	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-F
354	Coniferous forest	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-FC
355	Deciduous forest	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-FD
356	Evergreen broad-leaved forest	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-FE
357	Semi-deciduous forest	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-FS
358	Xeromorphic forest	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-FX
359	Herbaceous	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-H
360	Forb	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-HF
361	Medium grassland	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-HM
362	Short grassland	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-HS
363	Tall grassland	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-HT
364	Rainwater-fed moor peat	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-M
365	Shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-S
366	Deciduous shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-SD
367	Evergreen shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-SE
368	Semi-deciduous shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-SS
369	Xeromorphic shrub	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-SX
370	Woodland	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-W
371	Deciduous woodland	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-WD
372	Evergreen woodland	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-WE
373	Semi-deciduous woodland	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-WS
374	Xeromorphic woodland	http://w3id.org/glosis/model/codelists/vegetationClassValueCode-WX
375	overcast	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-OV
376	partly cloudy	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-PC
377	rain	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-RA
378	sleet	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-SL
379	snow	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-SN
380	sunny/clear	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-SU
381	no rain in the last month	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-WC1
382	no rain in the last week	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-WC2
383	no rain in the last 24 hours	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-WC3
384	rainy without heavy rain in the last 24 hours	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-WC4
385	heavier rain for some days or rainstorm in the last 24 hours	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-WC5
386	extremely rainy time or snow melting	http://w3id.org/glosis/model/codelists/weatherConditionsValueCode-WC6
387	Fresh or slightly weathered	http://w3id.org/glosis/model/codelists/weatheringValueCode-F
388	Strongly weathered	http://w3id.org/glosis/model/codelists/weatheringValueCode-S
389	Weathered	http://w3id.org/glosis/model/codelists/weatheringValueCode-W
390	Deep 10–20	http://w3id.org/glosis/model/codelists/cracksDepthValueCode-D
391	Medium 2–10	http://w3id.org/glosis/model/codelists/cracksDepthValueCode-M
392	Surface < 2	http://w3id.org/glosis/model/codelists/cracksDepthValueCode-S
393	Very deep > 20	http://w3id.org/glosis/model/codelists/cracksDepthValueCode-V
394	Very closely spaced < 0.2	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-C
395	Closely spaced 0.2–0.5	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-D
396	Moderately widely spaced 0.5–2	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-M
397	Very widely spaced > 5	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-V
398	Widely spaced 2–5	http://w3id.org/glosis/model/codelists/cracksDistanceValueCode-W
399	Extremely wide > 10cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-E
400	Fine < 1cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-F
401	Medium 1cm–2cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-M
402	Very wide 5cm–10cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-V
403	Wide 2cm–5cm	http://w3id.org/glosis/model/codelists/cracksWidthValueCode-W
404	Abundant	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-A
405	Common 	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-C
406	Dominant	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-D
407	Few	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-F
408	Many	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-M
409	None	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-N
410	Very few	http://w3id.org/glosis/model/codelists/fragmentCoverValueCode-V
411	Boulders	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-B
412	Coarse gravel	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-C
413	Fine gravel	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-F
414	Large boulders	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-L
415	Medium gravel	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-M
416	Stones	http://w3id.org/glosis/model/codelists/fragmentSizeValueCode-S
417	Abundant 	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-A
418	Common	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-C
419	Dominant	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-D
420	Few	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-F
421	Many	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-M
422	None	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-N
423	Stone line	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-S
424	Very few	http://w3id.org/glosis/model/codelists/rockAbundanceValueCode-V
425	Angular	http://w3id.org/glosis/model/codelists/rockShapeValueCode-A
426	Flat	http://w3id.org/glosis/model/codelists/rockShapeValueCode-F
427	Rounded	http://w3id.org/glosis/model/codelists/rockShapeValueCode-R
428	Subrounded	http://w3id.org/glosis/model/codelists/rockShapeValueCode-S
429	Artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-A
430	Coarse artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-AC
431	Fine artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-AF
432	Medium artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-AM
433	Very fine artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-AV
434	Boulders and large boulders	http://w3id.org/glosis/model/codelists/rockSizeValueCode-BL
435	Combination of classes	http://w3id.org/glosis/model/codelists/rockSizeValueCode-C
436	Coarse gravel and stones	http://w3id.org/glosis/model/codelists/rockSizeValueCode-CS
437	Fine and medium gravel/artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-FM
438	Medium and coarse gravel/artefacts	http://w3id.org/glosis/model/codelists/rockSizeValueCode-MC
439	Rock fragments	http://w3id.org/glosis/model/codelists/rockSizeValueCode-R
440	Boulders	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RB
441	Coarse gravel	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RC
442	Fine gravel	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RF
443	Large boulders	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RL
444	Medium gravel	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RM
445	Stones	http://w3id.org/glosis/model/codelists/rockSizeValueCode-RS
446	Stones and boulders	http://w3id.org/glosis/model/codelists/rockSizeValueCode-SB
447	None	http://w3id.org/glosis/model/codelists/saltCoverValueCode-0
448	Low	http://w3id.org/glosis/model/codelists/saltCoverValueCode-1
449	Moderate	http://w3id.org/glosis/model/codelists/saltCoverValueCode-2
450	High	http://w3id.org/glosis/model/codelists/saltCoverValueCode-3
451	Dominant	http://w3id.org/glosis/model/codelists/saltCoverValueCode-4
452	Thick	http://w3id.org/glosis/model/codelists/saltThicknessValueCode-C
453	Thin	http://w3id.org/glosis/model/codelists/saltThicknessValueCode-F
454	Medium	http://w3id.org/glosis/model/codelists/saltThicknessValueCode-M
455	None	http://w3id.org/glosis/model/codelists/saltThicknessValueCode-N
456	Very thick	http://w3id.org/glosis/model/codelists/saltThicknessValueCode-V
457	Extremely hard	http://w3id.org/glosis/model/codelists/sealingConsistenceValueCode-E
458	Hard	http://w3id.org/glosis/model/codelists/sealingConsistenceValueCode-H
459	Slightly hard	http://w3id.org/glosis/model/codelists/sealingConsistenceValueCode-S
460	Very hard	http://w3id.org/glosis/model/codelists/sealingConsistenceValueCode-V
461	Thick	http://w3id.org/glosis/model/codelists/sealingThicknessValueCode-C
462	Thin	http://w3id.org/glosis/model/codelists/sealingThicknessValueCode-F
463	Medium	http://w3id.org/glosis/model/codelists/sealingThicknessValueCode-M
464	None	http://w3id.org/glosis/model/codelists/sealingThicknessValueCode-N
465	Very thick	http://w3id.org/glosis/model/codelists/sealingThicknessValueCode-V
\.


--
-- TOC entry 4404 (class 0 OID 54022068)
-- Dependencies: 254
-- Data for Name: thesaurus_desc_profile; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.thesaurus_desc_profile (thesaurus_desc_profile_id, label, uri) FROM stdin;
1	Reference profile description	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-1
2	Reference profile description - no sampling	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-1.1
3	Routine profile description 	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-2
4	Routine profile description - no sampling	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-2.1
5	Incomplete description 	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-3
6	Incomplete description - no sampling	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-3.1
7	Soil augering description 	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-4
8	Soil augering description - no sampling	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-4.1
9	Other descriptions 	http://w3id.org/glosis/model/codelists/profileDescriptionStatusValueCode-5
\.


--
-- TOC entry 4406 (class 0 OID 54022092)
-- Dependencies: 256
-- Data for Name: unit_of_measure; Type: TABLE DATA; Schema: core; Owner: glosis
--

COPY core.unit_of_measure (unit_of_measure_id, label, uri) FROM stdin;
cm/h	Centimetre per hour	http://qudt.org/vocab/unit/CentiM-PER-HR
%	Percent	http://qudt.org/vocab/unit/PERCENT
cmol/kg	Centimole per kilogram	http://qudt.org/vocab/unit/CentiMOL-PER-KiloGM
dS/m	Decisiemens per metre	http://qudt.org/vocab/unit/DeciS-PER-M
g/kg	Gram per kilogram	http://qudt.org/vocab/unit/GM-PER-KiloGM
kg/dm³	Kilogram per cubic decimetre	http://qudt.org/vocab/unit/KiloGM-PER-DeciM3
pH	Acidity	http://qudt.org/vocab/unit/PH
cmol/L	Centimol per litre	http://w3id.org/glosis/model/unit/CentiMOL-PER-L
g/hg	Gram per hectogram	http://w3id.org/glosis/model/unit/GM-PER-HectoGM
m³/100 m³	Cubic metre per one hundred cubic metre	http://w3id.org/glosis/model/unit/M3-PER-HundredM3
\.


--
-- TOC entry 4407 (class 0 OID 54022100)
-- Dependencies: 257
-- Data for Name: address; Type: TABLE DATA; Schema: metadata; Owner: glosis
--

COPY metadata.address (address_id, street_address, postal_code, locality, country) FROM stdin;
\.


--
-- TOC entry 4409 (class 0 OID 54022108)
-- Dependencies: 259
-- Data for Name: individual; Type: TABLE DATA; Schema: metadata; Owner: glosis
--

COPY metadata.individual (individual_id, address_id, name, honorific_title, email, telephone, url) FROM stdin;
\.


--
-- TOC entry 4411 (class 0 OID 54022116)
-- Dependencies: 261
-- Data for Name: organisation; Type: TABLE DATA; Schema: metadata; Owner: glosis
--

COPY metadata.organisation (organisation_id, parent_id, address_id, name, email, telephone, url) FROM stdin;
\.


--
-- TOC entry 4412 (class 0 OID 54022122)
-- Dependencies: 262
-- Data for Name: organisation_individual; Type: TABLE DATA; Schema: metadata; Owner: glosis
--

COPY metadata.organisation_individual (organisation_id, organisation_unit_id, individual_id, role) FROM stdin;
\.


--
-- TOC entry 4374 (class 0 OID 54021907)
-- Dependencies: 224
-- Data for Name: organisation_project; Type: TABLE DATA; Schema: metadata; Owner: glosis
--

COPY metadata.organisation_project (organisation_id, project_id) FROM stdin;
\.


--
-- TOC entry 4414 (class 0 OID 54022130)
-- Dependencies: 264
-- Data for Name: organisation_unit; Type: TABLE DATA; Schema: metadata; Owner: glosis
--

COPY metadata.organisation_unit (organisation_unit_id, organisation_id, name) FROM stdin;
\.


--
-- TOC entry 4026 (class 0 OID 54021049)
-- Dependencies: 206
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: glosis
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- TOC entry 4610 (class 0 OID 0)
-- Dependencies: 211
-- Name: element_element_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.element_element_id_seq', 1, false);


--
-- TOC entry 4611 (class 0 OID 0)
-- Dependencies: 266
-- Name: observation_phys_chem_element_observation_phys_chem_element_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.observation_phys_chem_element_observation_phys_chem_element_seq', 1008, false);


--
-- TOC entry 4612 (class 0 OID 0)
-- Dependencies: 218
-- Name: plot_plot_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.plot_plot_id_seq', 1, false);


--
-- TOC entry 4613 (class 0 OID 0)
-- Dependencies: 222
-- Name: profile_profile_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.profile_profile_id_seq', 1, false);


--
-- TOC entry 4614 (class 0 OID 0)
-- Dependencies: 225
-- Name: project_project_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.project_project_id_seq', 1, false);


--
-- TOC entry 4615 (class 0 OID 0)
-- Dependencies: 267
-- Name: result_phys_chem_specimen_result_phys_chem_specimen_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.result_phys_chem_specimen_result_phys_chem_specimen_id_seq', 1, false);


--
-- TOC entry 4616 (class 0 OID 0)
-- Dependencies: 268
-- Name: result_spectrum_result_spectrum_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.result_spectrum_result_spectrum_id_seq', 1, false);


--
-- TOC entry 4617 (class 0 OID 0)
-- Dependencies: 238
-- Name: site_site_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.site_site_id_seq', 1, false);


--
-- TOC entry 4618 (class 0 OID 0)
-- Dependencies: 241
-- Name: specimen_prep_process_specimen_prep_process_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.specimen_prep_process_specimen_prep_process_id_seq', 1, false);


--
-- TOC entry 4619 (class 0 OID 0)
-- Dependencies: 242
-- Name: specimen_specimen_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.specimen_specimen_id_seq', 1, false);


--
-- TOC entry 4620 (class 0 OID 0)
-- Dependencies: 244
-- Name: specimen_storage_specimen_storage_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.specimen_storage_specimen_storage_id_seq', 1, false);


--
-- TOC entry 4621 (class 0 OID 0)
-- Dependencies: 246
-- Name: specimen_transport_specimen_transport_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.specimen_transport_specimen_transport_id_seq', 1, false);


--
-- TOC entry 4622 (class 0 OID 0)
-- Dependencies: 249
-- Name: surface_surface_id_seq; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.surface_surface_id_seq', 1, false);


--
-- TOC entry 4623 (class 0 OID 0)
-- Dependencies: 251
-- Name: thesaurus_desc_element_thesaurus_desc_element_id_seq1; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.thesaurus_desc_element_thesaurus_desc_element_id_seq1', 358, true);


--
-- TOC entry 4624 (class 0 OID 0)
-- Dependencies: 253
-- Name: thesaurus_desc_plot_thesaurus_desc_plot_id_seq1; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.thesaurus_desc_plot_thesaurus_desc_plot_id_seq1', 389, true);


--
-- TOC entry 4625 (class 0 OID 0)
-- Dependencies: 255
-- Name: thesaurus_desc_profile_thesaurus_desc_profile_id_seq1; Type: SEQUENCE SET; Schema: core; Owner: glosis
--

SELECT pg_catalog.setval('core.thesaurus_desc_profile_thesaurus_desc_profile_id_seq1', 9, true);


--
-- TOC entry 4626 (class 0 OID 0)
-- Dependencies: 258
-- Name: address_address_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: glosis
--

SELECT pg_catalog.setval('metadata.address_address_id_seq', 1, false);


--
-- TOC entry 4627 (class 0 OID 0)
-- Dependencies: 260
-- Name: individual_individual_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: glosis
--

SELECT pg_catalog.setval('metadata.individual_individual_id_seq', 1, false);


--
-- TOC entry 4628 (class 0 OID 0)
-- Dependencies: 263
-- Name: organisation_organisation_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: glosis
--

SELECT pg_catalog.setval('metadata.organisation_organisation_id_seq', 1, false);


--
-- TOC entry 4629 (class 0 OID 0)
-- Dependencies: 265
-- Name: organisation_unit_organisation_unit_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: glosis
--

SELECT pg_catalog.setval('metadata.organisation_unit_organisation_unit_id_seq', 1, false);


--
-- TOC entry 4042 (class 2606 OID 54022172)
-- Name: element element_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.element
    ADD CONSTRAINT element_pkey PRIMARY KEY (element_id);


--
-- TOC entry 4046 (class 2606 OID 54022937)
-- Name: observation_desc_element observation_desc_element_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_element
    ADD CONSTRAINT observation_desc_element_pkey PRIMARY KEY (property_desc_element_id, thesaurus_desc_element_id);


--
-- TOC entry 4048 (class 2606 OID 54022949)
-- Name: observation_desc_plot observation_desc_plot_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_plot
    ADD CONSTRAINT observation_desc_plot_pkey PRIMARY KEY (property_desc_plot_id, thesaurus_desc_plot_id);


--
-- TOC entry 4050 (class 2606 OID 54022961)
-- Name: observation_desc_profile observation_desc_profile_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_profile
    ADD CONSTRAINT observation_desc_profile_pkey PRIMARY KEY (property_desc_profile_id, thesaurus_desc_profile_id);


--
-- TOC entry 4052 (class 2606 OID 54022194)
-- Name: observation_phys_chem observation_phys_chem_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_phys_chem
    ADD CONSTRAINT observation_phys_chem_pkey PRIMARY KEY (observation_phys_chem_id);


--
-- TOC entry 4054 (class 2606 OID 54023197)
-- Name: observation_phys_chem observation_phys_chem_property_phys_chem_id_procedure_phys__key; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_phys_chem
    ADD CONSTRAINT observation_phys_chem_property_phys_chem_id_procedure_phys__key UNIQUE (property_phys_chem_id, procedure_phys_chem_id);


--
-- TOC entry 4060 (class 2606 OID 54022845)
-- Name: plot_individual plot_individual_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.plot_individual
    ADD CONSTRAINT plot_individual_pkey PRIMARY KEY (plot_id, individual_id);


--
-- TOC entry 4056 (class 2606 OID 54022202)
-- Name: plot plot_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.plot
    ADD CONSTRAINT plot_pkey PRIMARY KEY (plot_id);


--
-- TOC entry 4062 (class 2606 OID 54023073)
-- Name: procedure_desc procedure_desc_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.procedure_desc
    ADD CONSTRAINT procedure_desc_pkey PRIMARY KEY (procedure_desc_id);


--
-- TOC entry 4064 (class 2606 OID 54022699)
-- Name: procedure_desc procedure_desc_uri_key; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.procedure_desc
    ADD CONSTRAINT procedure_desc_uri_key UNIQUE (uri);


--
-- TOC entry 4066 (class 2606 OID 54023172)
-- Name: procedure_phys_chem procedure_phys_chem_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.procedure_phys_chem
    ADD CONSTRAINT procedure_phys_chem_pkey PRIMARY KEY (procedure_phys_chem_id);


--
-- TOC entry 4070 (class 2606 OID 54022210)
-- Name: profile profile_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.profile
    ADD CONSTRAINT profile_pkey PRIMARY KEY (profile_id);


--
-- TOC entry 4074 (class 2606 OID 54022216)
-- Name: project project_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (project_id);


--
-- TOC entry 4080 (class 2606 OID 54022847)
-- Name: project_related project_related_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.project_related
    ADD CONSTRAINT project_related_pkey PRIMARY KEY (project_source_id, project_target_id);


--
-- TOC entry 4114 (class 2606 OID 54022248)
-- Name: project_site project_site_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.project_site
    ADD CONSTRAINT project_site_pkey PRIMARY KEY (project_id, site_id);


--
-- TOC entry 4082 (class 2606 OID 54022904)
-- Name: property_desc_element property_desc_element_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.property_desc_element
    ADD CONSTRAINT property_desc_element_pkey PRIMARY KEY (property_desc_element_id);


--
-- TOC entry 4086 (class 2606 OID 54022915)
-- Name: property_desc_plot property_desc_plot_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.property_desc_plot
    ADD CONSTRAINT property_desc_plot_pkey PRIMARY KEY (property_desc_plot_id);


--
-- TOC entry 4090 (class 2606 OID 54022926)
-- Name: property_desc_profile property_desc_profile_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.property_desc_profile
    ADD CONSTRAINT property_desc_profile_pkey PRIMARY KEY (property_desc_profile_id);


--
-- TOC entry 4094 (class 2606 OID 54023146)
-- Name: property_phys_chem property_phys_chem_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.property_phys_chem
    ADD CONSTRAINT property_phys_chem_pkey PRIMARY KEY (property_phys_chem_id);


--
-- TOC entry 4098 (class 2606 OID 54022985)
-- Name: result_desc_element result_desc_element_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_element
    ADD CONSTRAINT result_desc_element_pkey PRIMARY KEY (element_id, property_desc_element_id);


--
-- TOC entry 4100 (class 2606 OID 54022997)
-- Name: result_desc_plot result_desc_plot_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_plot
    ADD CONSTRAINT result_desc_plot_pkey PRIMARY KEY (plot_id, property_desc_plot_id);


--
-- TOC entry 4102 (class 2606 OID 54023021)
-- Name: result_desc_profile result_desc_profile_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_profile
    ADD CONSTRAINT result_desc_profile_pkey PRIMARY KEY (profile_id, property_desc_profile_id);


--
-- TOC entry 4104 (class 2606 OID 54023009)
-- Name: result_desc_surface result_desc_surface_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_surface
    ADD CONSTRAINT result_desc_surface_pkey PRIMARY KEY (surface_id, property_desc_plot_id);


--
-- TOC entry 4106 (class 2606 OID 54022234)
-- Name: result_phys_chem result_numerical_specimen_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_phys_chem
    ADD CONSTRAINT result_numerical_specimen_pkey PRIMARY KEY (result_phys_chem_id);


--
-- TOC entry 4108 (class 2606 OID 54022887)
-- Name: result_phys_chem result_phys_chem_specimen_observation_phys_chem_id_specimen_key; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_phys_chem
    ADD CONSTRAINT result_phys_chem_specimen_observation_phys_chem_id_specimen_key UNIQUE (observation_phys_chem_id, specimen_id);


--
-- TOC entry 4170 (class 2606 OID 54023253)
-- Name: result_spectrum result_spectrum_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_spectrum
    ADD CONSTRAINT result_spectrum_pkey PRIMARY KEY (result_spectrum_id);


--
-- TOC entry 4110 (class 2606 OID 54022246)
-- Name: site site_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.site
    ADD CONSTRAINT site_pkey PRIMARY KEY (site_id);


--
-- TOC entry 4116 (class 2606 OID 54022735)
-- Name: specimen specimen_code_key; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen
    ADD CONSTRAINT specimen_code_key UNIQUE (code);


--
-- TOC entry 4118 (class 2606 OID 54022252)
-- Name: specimen specimen_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen
    ADD CONSTRAINT specimen_pkey PRIMARY KEY (specimen_id);


--
-- TOC entry 4120 (class 2606 OID 54022737)
-- Name: specimen_prep_process specimen_prep_process_definition_key; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_prep_process
    ADD CONSTRAINT specimen_prep_process_definition_key UNIQUE (definition);


--
-- TOC entry 4122 (class 2606 OID 54022256)
-- Name: specimen_prep_process specimen_prep_process_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_prep_process
    ADD CONSTRAINT specimen_prep_process_pkey PRIMARY KEY (specimen_prep_process_id);


--
-- TOC entry 4124 (class 2606 OID 54022739)
-- Name: specimen_storage specimen_storage_definition_key; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_storage
    ADD CONSTRAINT specimen_storage_definition_key UNIQUE (definition);


--
-- TOC entry 4126 (class 2606 OID 54022260)
-- Name: specimen_storage specimen_storage_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_storage
    ADD CONSTRAINT specimen_storage_pkey PRIMARY KEY (specimen_storage_id);


--
-- TOC entry 4130 (class 2606 OID 54022743)
-- Name: specimen_transport specimen_transport_definition_key; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_transport
    ADD CONSTRAINT specimen_transport_definition_key UNIQUE (definition);


--
-- TOC entry 4132 (class 2606 OID 54022264)
-- Name: specimen_transport specimen_transport_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_transport
    ADD CONSTRAINT specimen_transport_pkey PRIMARY KEY (specimen_transport_id);


--
-- TOC entry 4140 (class 2606 OID 54022859)
-- Name: surface_individual surface_individual_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.surface_individual
    ADD CONSTRAINT surface_individual_pkey PRIMARY KEY (surface_id, individual_id);


--
-- TOC entry 4136 (class 2606 OID 54022268)
-- Name: surface surface_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.surface
    ADD CONSTRAINT surface_pkey PRIMARY KEY (surface_id);


--
-- TOC entry 4142 (class 2606 OID 54022270)
-- Name: thesaurus_desc_element thesaurus_desc_element_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.thesaurus_desc_element
    ADD CONSTRAINT thesaurus_desc_element_pkey PRIMARY KEY (thesaurus_desc_element_id);


--
-- TOC entry 4146 (class 2606 OID 54022272)
-- Name: thesaurus_desc_plot thesaurus_desc_plot_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.thesaurus_desc_plot
    ADD CONSTRAINT thesaurus_desc_plot_pkey PRIMARY KEY (thesaurus_desc_plot_id);


--
-- TOC entry 4150 (class 2606 OID 54022274)
-- Name: thesaurus_desc_profile thesaurus_desc_profile_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.thesaurus_desc_profile
    ADD CONSTRAINT thesaurus_desc_profile_pkey PRIMARY KEY (thesaurus_desc_profile_id);


--
-- TOC entry 4154 (class 2606 OID 54023120)
-- Name: unit_of_measure unit_of_measure_pkey; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.unit_of_measure
    ADD CONSTRAINT unit_of_measure_pkey PRIMARY KEY (unit_of_measure_id);


--
-- TOC entry 4044 (class 2606 OID 54022282)
-- Name: element unq_element_profile_order_element; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.element
    ADD CONSTRAINT unq_element_profile_order_element UNIQUE (profile_id, order_element);


--
-- TOC entry 4058 (class 2606 OID 54022695)
-- Name: plot unq_plot_code; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.plot
    ADD CONSTRAINT unq_plot_code UNIQUE (plot_code);


--
-- TOC entry 4068 (class 2606 OID 54022703)
-- Name: procedure_phys_chem unq_procedure_phys_chem_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.procedure_phys_chem
    ADD CONSTRAINT unq_procedure_phys_chem_uri UNIQUE (uri);


--
-- TOC entry 4072 (class 2606 OID 54022705)
-- Name: profile unq_profile_code; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.profile
    ADD CONSTRAINT unq_profile_code UNIQUE (profile_code);


--
-- TOC entry 4076 (class 2606 OID 54022709)
-- Name: project unq_project_name; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.project
    ADD CONSTRAINT unq_project_name UNIQUE (name);


--
-- TOC entry 4084 (class 2606 OID 54022713)
-- Name: property_desc_element unq_property_desc_element_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.property_desc_element
    ADD CONSTRAINT unq_property_desc_element_uri UNIQUE (uri);


--
-- TOC entry 4088 (class 2606 OID 54022717)
-- Name: property_desc_plot unq_property_desc_plot_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.property_desc_plot
    ADD CONSTRAINT unq_property_desc_plot_uri UNIQUE (uri);


--
-- TOC entry 4092 (class 2606 OID 54022721)
-- Name: property_desc_profile unq_property_desc_profile_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.property_desc_profile
    ADD CONSTRAINT unq_property_desc_profile_uri UNIQUE (uri);


--
-- TOC entry 4096 (class 2606 OID 54022731)
-- Name: property_phys_chem unq_property_phys_chem_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.property_phys_chem
    ADD CONSTRAINT unq_property_phys_chem_uri UNIQUE (uri);


--
-- TOC entry 4112 (class 2606 OID 54022733)
-- Name: site unq_site_code; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.site
    ADD CONSTRAINT unq_site_code UNIQUE (site_code);


--
-- TOC entry 4128 (class 2606 OID 54022741)
-- Name: specimen_storage unq_specimen_storage_label; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_storage
    ADD CONSTRAINT unq_specimen_storage_label UNIQUE (label);


--
-- TOC entry 4134 (class 2606 OID 54022745)
-- Name: specimen_transport unq_specimen_transport_label; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_transport
    ADD CONSTRAINT unq_specimen_transport_label UNIQUE (label);


--
-- TOC entry 4138 (class 2606 OID 54022332)
-- Name: surface unq_surface_super; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.surface
    ADD CONSTRAINT unq_surface_super UNIQUE (surface_id, super_surface_id);


--
-- TOC entry 4144 (class 2606 OID 54022747)
-- Name: thesaurus_desc_element unq_thesaurus_desc_element_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.thesaurus_desc_element
    ADD CONSTRAINT unq_thesaurus_desc_element_uri UNIQUE (uri);


--
-- TOC entry 4148 (class 2606 OID 54022749)
-- Name: thesaurus_desc_plot unq_thesaurus_desc_plot_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.thesaurus_desc_plot
    ADD CONSTRAINT unq_thesaurus_desc_plot_uri UNIQUE (uri);


--
-- TOC entry 4152 (class 2606 OID 54022751)
-- Name: thesaurus_desc_profile unq_thesaurus_desc_profile_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.thesaurus_desc_profile
    ADD CONSTRAINT unq_thesaurus_desc_profile_uri UNIQUE (uri);


--
-- TOC entry 4156 (class 2606 OID 54022757)
-- Name: unit_of_measure unq_unit_of_measure_uri; Type: CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.unit_of_measure
    ADD CONSTRAINT unq_unit_of_measure_uri UNIQUE (uri);


--
-- TOC entry 4158 (class 2606 OID 54022346)
-- Name: address address_pkey; Type: CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);


--
-- TOC entry 4160 (class 2606 OID 54022348)
-- Name: individual individual_pkey; Type: CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.individual
    ADD CONSTRAINT individual_pkey PRIMARY KEY (individual_id);


--
-- TOC entry 4164 (class 2606 OID 54022350)
-- Name: organisation_individual organisation_individual_individual_id_organisation_id_key; Type: CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_individual
    ADD CONSTRAINT organisation_individual_individual_id_organisation_id_key UNIQUE (individual_id, organisation_id);


--
-- TOC entry 4162 (class 2606 OID 54022352)
-- Name: organisation organisation_pkey; Type: CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation
    ADD CONSTRAINT organisation_pkey PRIMARY KEY (organisation_id);


--
-- TOC entry 4078 (class 2606 OID 54022214)
-- Name: organisation_project organisation_project_pkey; Type: CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_project
    ADD CONSTRAINT organisation_project_pkey PRIMARY KEY (organisation_id, project_id);


--
-- TOC entry 4166 (class 2606 OID 54022759)
-- Name: organisation_unit organisation_unit_name_organisation_id_key; Type: CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_unit
    ADD CONSTRAINT organisation_unit_name_organisation_id_key UNIQUE (name, organisation_id);


--
-- TOC entry 4168 (class 2606 OID 54022356)
-- Name: organisation_unit organisation_unit_pkey; Type: CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_unit
    ADD CONSTRAINT organisation_unit_pkey PRIMARY KEY (organisation_unit_id);


--
-- TOC entry 4171 (class 1259 OID 54023264)
-- Name: result_spectrum_specimen_id_idx; Type: INDEX; Schema: core; Owner: glosis
--

CREATE INDEX result_spectrum_specimen_id_idx ON core.result_spectrum USING btree (specimen_id);


--
-- TOC entry 4172 (class 1259 OID 54023265)
-- Name: result_spectrum_spectrum_idx; Type: INDEX; Schema: core; Owner: glosis
--

CREATE INDEX result_spectrum_spectrum_idx ON core.result_spectrum USING gin (spectrum);


--
-- TOC entry 4228 (class 2620 OID 54023267)
-- Name: result_phys_chem trg_check_result_value; Type: TRIGGER; Schema: core; Owner: glosis
--

CREATE TRIGGER trg_check_result_value BEFORE INSERT OR UPDATE ON core.result_phys_chem FOR EACH ROW EXECUTE FUNCTION core.check_result_value();


--
-- TOC entry 4630 (class 0 OID 0)
-- Dependencies: 4228
-- Name: TRIGGER trg_check_result_value ON result_phys_chem; Type: COMMENT; Schema: core; Owner: glosis
--

COMMENT ON TRIGGER trg_check_result_value ON core.result_phys_chem IS 'Verifies if the value assigned to the result is valid. See the function core.ceck_result_value function for implementation.';


--
-- TOC entry 4196 (class 2606 OID 54022369)
-- Name: result_desc_element fk_element; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_element
    ADD CONSTRAINT fk_element FOREIGN KEY (element_id) REFERENCES core.element(element_id);


--
-- TOC entry 4217 (class 2606 OID 54022374)
-- Name: surface_individual fk_individual; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.surface_individual
    ADD CONSTRAINT fk_individual FOREIGN KEY (individual_id) REFERENCES metadata.individual(individual_id);


--
-- TOC entry 4187 (class 2606 OID 54022379)
-- Name: plot_individual fk_individual; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.plot_individual
    ADD CONSTRAINT fk_individual FOREIGN KEY (individual_id) REFERENCES metadata.individual(individual_id);


--
-- TOC entry 4210 (class 2606 OID 54022404)
-- Name: specimen fk_organisation; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen
    ADD CONSTRAINT fk_organisation FOREIGN KEY (organisation_id) REFERENCES metadata.organisation(organisation_id);


--
-- TOC entry 4188 (class 2606 OID 54022419)
-- Name: plot_individual fk_plot; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.plot_individual
    ADD CONSTRAINT fk_plot FOREIGN KEY (plot_id) REFERENCES core.plot(plot_id);


--
-- TOC entry 4190 (class 2606 OID 54022424)
-- Name: profile fk_plot; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.profile
    ADD CONSTRAINT fk_plot FOREIGN KEY (plot_id) REFERENCES core.plot(plot_id);


--
-- TOC entry 4198 (class 2606 OID 54022429)
-- Name: result_desc_plot fk_plot; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_plot
    ADD CONSTRAINT fk_plot FOREIGN KEY (plot_id) REFERENCES core.plot(plot_id);


--
-- TOC entry 4173 (class 2606 OID 54022469)
-- Name: element fk_profile; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.element
    ADD CONSTRAINT fk_profile FOREIGN KEY (profile_id) REFERENCES core.profile(profile_id);


--
-- TOC entry 4200 (class 2606 OID 54022474)
-- Name: result_desc_profile fk_profile; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_profile
    ADD CONSTRAINT fk_profile FOREIGN KEY (profile_id) REFERENCES core.profile(profile_id);


--
-- TOC entry 4207 (class 2606 OID 54022479)
-- Name: site fk_profile; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.site
    ADD CONSTRAINT fk_profile FOREIGN KEY (typical_profile) REFERENCES core.profile(profile_id);


--
-- TOC entry 4208 (class 2606 OID 54022484)
-- Name: project_site fk_project; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.project_site
    ADD CONSTRAINT fk_project FOREIGN KEY (project_id) REFERENCES core.project(project_id);


--
-- TOC entry 4194 (class 2606 OID 54022494)
-- Name: project_related fk_project_source; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.project_related
    ADD CONSTRAINT fk_project_source FOREIGN KEY (project_source_id) REFERENCES core.project(project_id);


--
-- TOC entry 4195 (class 2606 OID 54022499)
-- Name: project_related fk_project_target; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.project_related
    ADD CONSTRAINT fk_project_target FOREIGN KEY (project_target_id) REFERENCES core.project(project_id);


--
-- TOC entry 4215 (class 2606 OID 54022539)
-- Name: surface fk_site; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.surface
    ADD CONSTRAINT fk_site FOREIGN KEY (site_id) REFERENCES core.site(site_id);


--
-- TOC entry 4186 (class 2606 OID 54022544)
-- Name: plot fk_site; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.plot
    ADD CONSTRAINT fk_site FOREIGN KEY (site_id) REFERENCES core.site(site_id);


--
-- TOC entry 4209 (class 2606 OID 54022549)
-- Name: project_site fk_site; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.project_site
    ADD CONSTRAINT fk_site FOREIGN KEY (site_id) REFERENCES core.site(site_id);


--
-- TOC entry 4204 (class 2606 OID 54022559)
-- Name: result_phys_chem fk_specimen; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_phys_chem
    ADD CONSTRAINT fk_specimen FOREIGN KEY (specimen_id) REFERENCES core.specimen(specimen_id);


--
-- TOC entry 4226 (class 2606 OID 54023254)
-- Name: result_spectrum fk_specimen; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_spectrum
    ADD CONSTRAINT fk_specimen FOREIGN KEY (specimen_id) REFERENCES core.specimen(specimen_id);


--
-- TOC entry 4211 (class 2606 OID 54022564)
-- Name: specimen fk_specimen_prep_process; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen
    ADD CONSTRAINT fk_specimen_prep_process FOREIGN KEY (specimen_prep_process_id) REFERENCES core.specimen_prep_process(specimen_prep_process_id);


--
-- TOC entry 4213 (class 2606 OID 54022569)
-- Name: specimen_prep_process fk_specimen_storage; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_prep_process
    ADD CONSTRAINT fk_specimen_storage FOREIGN KEY (specimen_storage_id) REFERENCES core.specimen_storage(specimen_storage_id);


--
-- TOC entry 4214 (class 2606 OID 54022574)
-- Name: specimen_prep_process fk_specimen_transport; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen_prep_process
    ADD CONSTRAINT fk_specimen_transport FOREIGN KEY (specimen_transport_id) REFERENCES core.specimen_transport(specimen_transport_id);


--
-- TOC entry 4191 (class 2606 OID 54022579)
-- Name: profile fk_surface; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.profile
    ADD CONSTRAINT fk_surface FOREIGN KEY (surface_id) REFERENCES core.surface(surface_id);


--
-- TOC entry 4202 (class 2606 OID 54022584)
-- Name: result_desc_surface fk_surface; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_surface
    ADD CONSTRAINT fk_surface FOREIGN KEY (surface_id) REFERENCES core.surface(surface_id);


--
-- TOC entry 4218 (class 2606 OID 54022589)
-- Name: surface_individual fk_surface; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.surface_individual
    ADD CONSTRAINT fk_surface FOREIGN KEY (surface_id) REFERENCES core.surface(surface_id);


--
-- TOC entry 4216 (class 2606 OID 54022594)
-- Name: surface fk_surface; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.surface
    ADD CONSTRAINT fk_surface FOREIGN KEY (super_surface_id) REFERENCES core.surface(surface_id);


--
-- TOC entry 4174 (class 2606 OID 54022599)
-- Name: observation_desc_element fk_thesaurus_desc_element; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_element
    ADD CONSTRAINT fk_thesaurus_desc_element FOREIGN KEY (thesaurus_desc_element_id) REFERENCES core.thesaurus_desc_element(thesaurus_desc_element_id);


--
-- TOC entry 4177 (class 2606 OID 54022604)
-- Name: observation_desc_plot fk_thesaurus_desc_plot; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_plot
    ADD CONSTRAINT fk_thesaurus_desc_plot FOREIGN KEY (thesaurus_desc_plot_id) REFERENCES core.thesaurus_desc_plot(thesaurus_desc_plot_id);


--
-- TOC entry 4180 (class 2606 OID 54022609)
-- Name: observation_desc_profile fk_thesaurus_desc_profile; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_profile
    ADD CONSTRAINT fk_thesaurus_desc_profile FOREIGN KEY (thesaurus_desc_profile_id) REFERENCES core.thesaurus_desc_profile(thesaurus_desc_profile_id);


--
-- TOC entry 4175 (class 2606 OID 54023104)
-- Name: observation_desc_element observation_desc_element_procedure_desc_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_element
    ADD CONSTRAINT observation_desc_element_procedure_desc_id_fkey FOREIGN KEY (procedure_desc_id) REFERENCES core.procedure_desc(procedure_desc_id) ON UPDATE CASCADE;


--
-- TOC entry 4176 (class 2606 OID 54023032)
-- Name: observation_desc_element observation_desc_element_property_desc_element_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_element
    ADD CONSTRAINT observation_desc_element_property_desc_element_id_fkey FOREIGN KEY (property_desc_element_id) REFERENCES core.property_desc_element(property_desc_element_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4178 (class 2606 OID 54023109)
-- Name: observation_desc_plot observation_desc_plot_procedure_desc_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_plot
    ADD CONSTRAINT observation_desc_plot_procedure_desc_id_fkey FOREIGN KEY (procedure_desc_id) REFERENCES core.procedure_desc(procedure_desc_id) ON UPDATE CASCADE;


--
-- TOC entry 4179 (class 2606 OID 54023037)
-- Name: observation_desc_plot observation_desc_plot_property_desc_plot_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_plot
    ADD CONSTRAINT observation_desc_plot_property_desc_plot_id_fkey FOREIGN KEY (property_desc_plot_id) REFERENCES core.property_desc_plot(property_desc_plot_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4181 (class 2606 OID 54023114)
-- Name: observation_desc_profile observation_desc_profile_procedure_desc_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_profile
    ADD CONSTRAINT observation_desc_profile_procedure_desc_id_fkey FOREIGN KEY (procedure_desc_id) REFERENCES core.procedure_desc(procedure_desc_id) ON UPDATE CASCADE;


--
-- TOC entry 4182 (class 2606 OID 54023042)
-- Name: observation_desc_profile observation_desc_profile_property_desc_profile_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_desc_profile
    ADD CONSTRAINT observation_desc_profile_property_desc_profile_id_fkey FOREIGN KEY (property_desc_profile_id) REFERENCES core.property_desc_profile(property_desc_profile_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4183 (class 2606 OID 54023206)
-- Name: observation_phys_chem observation_phys_chem_procedure_phys_chem_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_phys_chem
    ADD CONSTRAINT observation_phys_chem_procedure_phys_chem_id_fkey FOREIGN KEY (procedure_phys_chem_id) REFERENCES core.procedure_phys_chem(procedure_phys_chem_id) ON UPDATE CASCADE;


--
-- TOC entry 4184 (class 2606 OID 54023166)
-- Name: observation_phys_chem observation_phys_chem_property_phys_chem_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_phys_chem
    ADD CONSTRAINT observation_phys_chem_property_phys_chem_id_fkey FOREIGN KEY (property_phys_chem_id) REFERENCES core.property_phys_chem(property_phys_chem_id) ON UPDATE CASCADE;


--
-- TOC entry 4185 (class 2606 OID 54023140)
-- Name: observation_phys_chem observation_phys_chem_unit_of_measure_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.observation_phys_chem
    ADD CONSTRAINT observation_phys_chem_unit_of_measure_id_fkey FOREIGN KEY (unit_of_measure_id) REFERENCES core.unit_of_measure(unit_of_measure_id) ON UPDATE CASCADE;


--
-- TOC entry 4189 (class 2606 OID 54023191)
-- Name: procedure_phys_chem procedure_phys_chem_broader_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.procedure_phys_chem
    ADD CONSTRAINT procedure_phys_chem_broader_id_fkey FOREIGN KEY (broader_id) REFERENCES core.procedure_phys_chem(procedure_phys_chem_id) ON UPDATE CASCADE;


--
-- TOC entry 4197 (class 2606 OID 54023052)
-- Name: result_desc_element result_desc_element_property_desc_element_id_thesaurus_des_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_element
    ADD CONSTRAINT result_desc_element_property_desc_element_id_thesaurus_des_fkey FOREIGN KEY (property_desc_element_id, thesaurus_desc_element_id) REFERENCES core.observation_desc_element(property_desc_element_id, thesaurus_desc_element_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4199 (class 2606 OID 54023057)
-- Name: result_desc_plot result_desc_plot_property_desc_plot_id_thesaurus_desc_plot_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_plot
    ADD CONSTRAINT result_desc_plot_property_desc_plot_id_thesaurus_desc_plot_fkey FOREIGN KEY (property_desc_plot_id, thesaurus_desc_plot_id) REFERENCES core.observation_desc_plot(property_desc_plot_id, thesaurus_desc_plot_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4201 (class 2606 OID 54023067)
-- Name: result_desc_profile result_desc_profile_property_desc_profile_id_thesaurus_des_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_profile
    ADD CONSTRAINT result_desc_profile_property_desc_profile_id_thesaurus_des_fkey FOREIGN KEY (property_desc_profile_id, thesaurus_desc_profile_id) REFERENCES core.observation_desc_profile(property_desc_profile_id, thesaurus_desc_profile_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4203 (class 2606 OID 54023062)
-- Name: result_desc_surface result_desc_surface_property_desc_plot_id_thesaurus_desc_p_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_desc_surface
    ADD CONSTRAINT result_desc_surface_property_desc_plot_id_thesaurus_desc_p_fkey FOREIGN KEY (property_desc_plot_id, thesaurus_desc_plot_id) REFERENCES core.observation_desc_plot(property_desc_plot_id, thesaurus_desc_plot_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4205 (class 2606 OID 54022821)
-- Name: result_phys_chem result_phys_chem_specimen_individual_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_phys_chem
    ADD CONSTRAINT result_phys_chem_specimen_individual_id_fkey FOREIGN KEY (individual_id) REFERENCES metadata.individual(individual_id);


--
-- TOC entry 4206 (class 2606 OID 54022888)
-- Name: result_phys_chem result_phys_chem_specimen_observation_phys_chem_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_phys_chem
    ADD CONSTRAINT result_phys_chem_specimen_observation_phys_chem_id_fkey FOREIGN KEY (observation_phys_chem_id) REFERENCES core.observation_phys_chem(observation_phys_chem_id);


--
-- TOC entry 4227 (class 2606 OID 54023259)
-- Name: result_spectrum result_spectrum_individual_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.result_spectrum
    ADD CONSTRAINT result_spectrum_individual_id_fkey FOREIGN KEY (individual_id) REFERENCES metadata.individual(individual_id);


--
-- TOC entry 4212 (class 2606 OID 54023211)
-- Name: specimen specimen_element_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: glosis
--

ALTER TABLE ONLY core.specimen
    ADD CONSTRAINT specimen_element_id_fkey FOREIGN KEY (element_id) REFERENCES core.element(element_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4219 (class 2606 OID 54022659)
-- Name: individual fk_address; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.individual
    ADD CONSTRAINT fk_address FOREIGN KEY (address_id) REFERENCES metadata.address(address_id);


--
-- TOC entry 4220 (class 2606 OID 54022664)
-- Name: organisation fk_address; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation
    ADD CONSTRAINT fk_address FOREIGN KEY (address_id) REFERENCES metadata.address(address_id);


--
-- TOC entry 4222 (class 2606 OID 54022669)
-- Name: organisation_individual fk_individual; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_individual
    ADD CONSTRAINT fk_individual FOREIGN KEY (individual_id) REFERENCES metadata.individual(individual_id);


--
-- TOC entry 4192 (class 2606 OID 54022409)
-- Name: organisation_project fk_organisation; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_project
    ADD CONSTRAINT fk_organisation FOREIGN KEY (organisation_id) REFERENCES metadata.organisation(organisation_id);


--
-- TOC entry 4223 (class 2606 OID 54022674)
-- Name: organisation_individual fk_organisation; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_individual
    ADD CONSTRAINT fk_organisation FOREIGN KEY (organisation_id) REFERENCES metadata.organisation(organisation_id);


--
-- TOC entry 4225 (class 2606 OID 54022679)
-- Name: organisation_unit fk_organisation; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_unit
    ADD CONSTRAINT fk_organisation FOREIGN KEY (organisation_id) REFERENCES metadata.organisation(organisation_id);


--
-- TOC entry 4224 (class 2606 OID 54022684)
-- Name: organisation_individual fk_organisation_unit; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_individual
    ADD CONSTRAINT fk_organisation_unit FOREIGN KEY (organisation_unit_id) REFERENCES metadata.organisation_unit(organisation_unit_id);


--
-- TOC entry 4193 (class 2606 OID 54022489)
-- Name: organisation_project fk_project; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation_project
    ADD CONSTRAINT fk_project FOREIGN KEY (project_id) REFERENCES core.project(project_id);


--
-- TOC entry 4221 (class 2606 OID 54022816)
-- Name: organisation organisation_parent_id_fkey; Type: FK CONSTRAINT; Schema: metadata; Owner: glosis
--

ALTER TABLE ONLY metadata.organisation
    ADD CONSTRAINT organisation_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES metadata.organisation(organisation_id);


--
-- TOC entry 4427 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 4526 (class 0 OID 0)
-- Dependencies: 269
-- Name: TABLE result_spectrum; Type: ACL; Schema: core; Owner: glosis
--

GRANT SELECT ON TABLE core.result_spectrum TO glosis_r;


--
-- TOC entry 2820 (class 826 OID 54023242)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: core; Owner: glosis
--

ALTER DEFAULT PRIVILEGES FOR ROLE glosis IN SCHEMA core GRANT SELECT ON TABLES TO glosis_r;


--
-- TOC entry 2821 (class 826 OID 54023243)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: metadata; Owner: glosis
--

ALTER DEFAULT PRIVILEGES FOR ROLE glosis IN SCHEMA metadata GRANT SELECT ON TABLES TO glosis_r;


-- Completed on 2025-03-11 11:30:02 CET

--
-- PostgreSQL database dump complete
--

