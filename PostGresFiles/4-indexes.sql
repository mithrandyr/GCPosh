CREATE UNIQUE INDEX IF NOT EXISTS uix_county_countyname ON gcverbase00001.county USING BTREE(countyname);

CREATE INDEX IF NOT EXISTS ix_mapnote_name ON gcdefault.mapnote USING BTREE(name);
CREATE INDEX IF NOT EXISTS ix_servicearea_code ON gcversa00001.servicearea USING BTREE(code);

CREATE INDEX IF NOT EXISTS ix_railroads_name ON gcverbase00001.railroads USING BTREE(name);
CREATE INDEX IF NOT EXISTS ix_water_name ON gcverbase00001.water USING BTREE(name);
CREATE INDEX IF NOT EXISTS ix_surfacewater_name ON gcverbase00001.surfacewater USING BTREE(name);
CREATE INDEX IF NOT EXISTS ix_parcel_countykey ON gcverbase00001.parcel USING BTREE(countykey);
CREATE INDEX IF NOT EXISTS ix_parcel_city ON gcverbase00001.parcel USING BTREE(city);
CREATE INDEX IF NOT EXISTS ix_places_placename_countyname ON gcverbase00001.places USING BTREE(countyname, placename);
CREATE INDEX IF NOT EXISTS ix_streets_countyname_streetname ON gcverbase00001.streets USING BTREE(countyname,streetname);
CREATE INDEX IF NOT EXISTS ix_streets_countyname_placename ON gcverbase00001.streets USING BTREE(countyname,placename);
CREATE INDEX IF NOT EXISTS ix_streets_strplace ON gcverbase00001.streets USING BTREE(strplace);
CREATE INDEX IF NOT EXISTS ix_streets_fcc ON gcverbase00001.streets USING BTREE(fcc);
CREATE INDEX IF NOT EXISTS ix_serviceareatype_typename_code ON gcversa00001.serviceareatype USING BTREE(typename, code);


CREATE INDEX IF NOT EXISTS six_mapnote ON gcdefault.mapnote USING GIST(geom);
CREATE INDEX IF NOT EXISTS six_servicearea ON gcversa00001.servicearea USING GIST(geom);

CREATE INDEX IF NOT EXISTS six_county ON gcverbase00001.county USING GIST(geom);
CREATE INDEX IF NOT EXISTS six_places ON gcverbase00001.places USING GIST(geom);
CREATE INDEX IF NOT EXISTS six_streets ON gcverbase00001.streets USING GIST(geom);
CREATE INDEX IF NOT EXISTS six_railroads ON gcverbase00001.railroads USING GIST(geom);
CREATE INDEX IF NOT EXISTS six_water ON gcverbase00001.water USING GIST(geom);
CREATE INDEX IF NOT EXISTS six_surfacewater ON gcverbase00001.surfacewater USING GIST(geom);
CREATE INDEX IF NOT EXISTS six_parcel ON gcverbase00001.parcel USING GIST(geom);