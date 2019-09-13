CREATE TABLE IF NOT EXISTS gcdefault.dbversion (
  version INTEGER DEFAULT 0 NOT NULL,
  updateon TIMESTAMP(6) DEFAULT now() NOT NULL,
  CONSTRAINT PK_dbversion PRIMARY KEY (version)
);

CREATE TABLE IF NOT EXISTS gcdefault.mapnotecategory (
  mapnotecategoryid INTEGER DEFAULT nextval('gcdefault.mapnotecategory_mapnotecategoryid_seq'::regclass) NOT NULL,
  name VARCHAR(100) NOT NULL,
  sortorder INTEGER DEFAULT 0 NOT NULL,
  isactive BOOLEAN DEFAULT true NOT NULL,
  CONSTRAINT PK_mapnotecategory PRIMARY KEY (mapnotecategoryid)
);

CREATE TABLE IF NOT EXISTS gcdefault.mapnote
(
    mapnoteid integer NOT NULL DEFAULT nextval('gcdefault.mapnote_mapnoteid_seq'::regclass),
    name character varying(100) NOT NULL,
    mapnotecategoryid integer NOT NULL,
    remarks character varying(1000),
    createdby character varying(255) NOT NULL,
    createddate timestamp without time zone NOT NULL DEFAULT now(),
    lastupdateby character varying(255) NOT NULL,
    lastupdate timestamp without time zone NOT NULL DEFAULT now(),
    geom geometry(Point,4326),
    CONSTRAINT pk_mapnote PRIMARY KEY (mapnoteid),
    CONSTRAINT fk_mapnote_mapnotecategory FOREIGN KEY (mapnotecategoryid)
        REFERENCES gcdefault.mapnotecategory (mapnotecategoryid) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS gcdefault.version (
  key VARCHAR(10) NOT NULL,
  versionnumber BIGINT NOT NULL,
  seton TIMESTAMP(6) DEFAULT now() NOT NULL,
  CONSTRAINT PK_version PRIMARY KEY (key)
);

CREATE TABLE IF NOT EXISTS gcdefault.versionhistory (
  key VARCHAR(10) NOT NULL,
  versionnumber BIGINT NOT NULL,
  createdon TIMESTAMP(6) DEFAULT now() NOT NULL,
  removedon TIMESTAMP(6),
  isavailable BOOLEAN DEFAULT true NOT NULL,
  CONSTRAINT PK_versionhistory PRIMARY KEY (key, versionnumber)
);

CREATE TABLE IF NOT EXISTS gcverbase00001.parcel
(
    gid integer NOT NULL,
    parcel_id integer NOT NULL,
    countykey character varying(5),
    county character varying(30),
    statekey character varying(2),
    apn character varying(50),
    apn2 character varying(50),
    addr character varying(100),
    city character varying(50),
    state character varying(2),
    zip character varying(5),
    geom geometry(MultiPolygon,4326),
    CONSTRAINT parcel_pkey PRIMARY KEY (gid)
);

CREATE TABLE IF NOT EXISTS gcverbase00001.county
(
    gid integer NOT NULL DEFAULT nextval('gcverbase00001.county_gid_seq'::regclass),
    polygon_id bigint,
    countyname character varying(200),
    area_id bigint,
    geom geometry(MultiPolygon,4326),
    CONSTRAINT county_pkey PRIMARY KEY (gid)
);

CREATE TABLE IF NOT EXISTS gcverbase00001.places
(
    gid integer NOT NULL DEFAULT nextval('gcverbase00001.places_gid_seq'::regclass),
    id bigint,
    placename character varying(50),
    countyname character varying(50),
    polygon_id bigint,
    area_id bigint,
    iscity character varying(1),
    zip character varying(5),
    geom geometry(MultiPolygon,4326),
    CONSTRAINT places_pkey PRIMARY KEY (gid)
);

CREATE TABLE IF NOT EXISTS gcverbase00001.railroads
(
    gid integer NOT NULL DEFAULT nextval('gcverbase00001.railroads_gid_seq'::regclass),
    link_id bigint,
    name character varying(200),
    bridge character varying(1),
    tunnel character varying(1),
    geom geometry(MultiLineString,4326),
    CONSTRAINT railroad_pkey PRIMARY KEY (gid)
);

CREATE TABLE IF NOT EXISTS gcverbase00001.streets
(
    gid integer NOT NULL DEFAULT nextval('gcverbase00001.streets_gid_seq'::regclass),
    l_f_add character varying(30),
    l_t_add character varying(30),
    r_f_add character varying(30),
    r_t_add character varying(30),
    prefix character varying(10),
    name character varying(100),
    type character varying(16),
    suffix character varying(16),
    strplace character varying(100),
    streetname character varying(100),
    placename character varying(100),
    countyname character varying(100),
    geom geometry(MultiLineString,4326),
    fcc character varying(20),
    original_street character varying(255),
    CONSTRAINT streets_pkey PRIMARY KEY (gid)
);

CREATE TABLE IF NOT EXISTS gcverbase00001.surfacewater
(
    gid integer NOT NULL DEFAULT nextval('gcverbase00001.surfacewater_gid_seq'::regclass),
    polygon_id bigint,
    disp_class character varying(1),
    name character varying(200),
    feat_type character varying(40),
    feat_cod bigint,
    geom geometry(MultiPolygon,4326),
    CONSTRAINT waterpoly_pkey PRIMARY KEY (gid)
);

CREATE TABLE IF NOT EXISTS gcverbase00001.water
(
    gid integer NOT NULL DEFAULT nextval('gcverbase00001.water_gid_seq'::regclass),
    link_id bigint,
    disp_class character varying(1),
    name character varying(200),
    geom geometry(MultiLineString,4326),
    CONSTRAINT water_pkey PRIMARY KEY (gid)
);

CREATE TABLE IF NOT EXISTS gcversa00001.servicearea
(
    gid integer NOT NULL DEFAULT nextval('gcversa00001.servicearea_gid_seq'::regclass),
    code character varying(20),
    geom geometry(MultiPolygon,4326),
    CONSTRAINT servicearea_pkey PRIMARY KEY (gid)
);

CREATE TABLE IF NOT EXISTS gcversa00001.serviceareatype
(
    gid integer NOT NULL DEFAULT nextval('gcversa00001.serviceareatype_gid_seq'::regclass),
    code character varying(20) NOT NULL,
    typename character varying(20) NOT NULL,
    CONSTRAINT pk_serviceareatype PRIMARY KEY (gid)
);