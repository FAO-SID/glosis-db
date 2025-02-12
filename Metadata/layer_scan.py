#coding: utf-8

import os
import sys
import psycopg2
from osgeo import gdal, osr
import math

gdal.UseExceptions()  # Explicitly enable exceptions

def transform_to_wgs84(x, y, source_srs):
    """Transform coordinates from source projection to EPSG:4326 (lat/lon)."""
    target_srs = osr.SpatialReference()
    target_srs.ImportFromEPSG(4326)  # WGS 84

    transform = osr.CoordinateTransformation(source_srs, target_srs)
    lon, lat, _ = transform.TransformPoint(x, y)
    return lon, lat

def convert_size(size_bytes):
   if size_bytes == 0:
       return "0B"
   size_name = ("B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB")
   i = int(math.floor(math.log(size_bytes, 1024)))
   p = math.pow(1024, i)
   s = round(size_bytes / p, 2)
   return "%s %s" % (s, size_name[i])

def spatial_data_scan(rootdir):

    # iterate files
    for subdir, dirs, files in os.walk(rootdir):
        for file in files:

            # diccionary to store variables
            dic_gdal_num={}
            dic_gdal_text={}

            # get path
            file_name = str(file)
            layer_id = file_name[:-4]
            project_id = layer_id.split('-')[1]
            mapset_id = '-'.join(layer_id.split('-')[:4])
            file_path = str(subdir)
            path = os.path.join(subdir, file)

            # file metadata
            file_stat        = os.stat(path)
            file_size        = file_stat[6]
            file_size_pretty = convert_size(file_stat[6])
            file_extension   = os.path.splitext(file)[-1].lstrip('.').lower()

            if os.path.splitext(file)[-1].lstrip('.').lower() in ['asc', 'ecw', 'grb', 'rb2', 'hdf', 'jpg', 'nc', 'tif']:

                # insert project
                sql = f"INSERT INTO metadata.project(project_id) VALUES('{project_id}') ON CONFLICT (project_id) DO NOTHING"
                cur.execute(sql)

                # insert mapset and layer
                print (file_name)
                sql = f"INSERT INTO metadata.mapset(mapset_id, project_id) VALUES('{mapset_id}', '{project_id}') ON CONFLICT (mapset_id) DO NOTHING"
                cur.execute(sql)
                dimension_des = layer_id.split('-')[4] + ' to ' + layer_id.split('-')[5] + ' cm'
                sql = f"INSERT INTO metadata.layer(mapset_id, dimension_des, file_path, layer_id, file_extension, file_size, file_size_pretty) VALUES('{mapset_id}', '{dimension_des}','{file_path}','{layer_id}','{file_extension}','{file_size}','{file_size_pretty}')"
                cur.execute(sql)

                # open file with GDAL
                src_ds = gdal.Open(path)
                if src_ds is None:
                    print ('Unable to open %s' % path)
                    sys.exit(1)

                # GDAL info
                image_struture = src_ds.GetMetadata('IMAGE_STRUCTURE')
                dic_gdal_text['compression'] = image_struture.get('COMPRESSION', None) if image_struture else None
                dic_gdal_text['distribution_format'] = src_ds.GetDriver().LongName
                dic_gdal_num['raster_size_x'] = src_ds.RasterXSize
                dic_gdal_num['raster_size_y'] = src_ds.RasterYSize
                geo_transform = src_ds.GetGeoTransform()
                dic_gdal_num['distance'] = abs(geo_transform[1])
                dic_gdal_num['pixel_size_x'] = abs(geo_transform[1])
                dic_gdal_num['pixel_size_y'] = abs(geo_transform[5])
                dic_gdal_num['origin_x'] = geo_transform[0]
                dic_gdal_num['origin_y'] = geo_transform[3]

                projection = src_ds.GetProjection()
                spatial_reference = osr.SpatialReference()
                spatial_reference.ImportFromWkt(projection)
                dic_gdal_text['reference_system_identifier_code'] = spatial_reference.GetAttrValue('AUTHORITY',1)
                dic_gdal_text['spatial_reference'] = str(spatial_reference)
                dic_gdal_num['n_bands'] = src_ds.RasterCount
                dic_gdal_text['metadata'] = str(src_ds.GetMetadata()).replace("'","")
                
                # Bounding Box
                west_x = geo_transform[0]  # Upper-left X
                north_y = geo_transform[3]  # Upper-left Y
                east_x = west_x + (src_ds.RasterXSize * geo_transform[1])  # Lower-right X
                south_y = north_y + (src_ds.RasterYSize * geo_transform[5])  # Lower-right Y
                dic_gdal_text['extent'] = f'{west_x} {south_y} {east_x} {north_y}'
                west_lon, north_lat = transform_to_wgs84(west_x, north_y, spatial_reference) # in EPSG:4326
                east_lon, south_lat = transform_to_wgs84(east_x, south_y, spatial_reference) # in EPSG:4326
                dic_gdal_num['west_bound_longitude'] = west_lon
                dic_gdal_num['east_bound_longitude'] = east_lon
                dic_gdal_num['north_bound_latitude'] = north_lat
                dic_gdal_num['south_bound_latitude'] = south_lat

                # iterate bands
                for band_number in range(src_ds.RasterCount):
                    band_number += 1
                    src_band = src_ds.GetRasterBand(band_number)
                    if src_band is None:
                        continue
                    stats = src_band.GetStatistics(True, True)
                    if stats is None:
                        continue

                    # band info
                    dic_gdal_text['data_type']    = gdal.GetDataTypeName(src_band.DataType)
                    dic_gdal_num['no_data_value'] = -123456789 if src_band.GetNoDataValue() is None or str(src_band.GetNoDataValue()).lower() == 'nan' else src_band.GetNoDataValue()
                    dic_gdal_num['stats_minimum'] = stats[0]
                    dic_gdal_num['stats_maximum'] = stats[1]
                    dic_gdal_num['stats_mean']    = stats[2] if str(stats[2]) != 'nan' else -123456789
                    dic_gdal_num['stats_std_dev'] = stats[3] if str(stats[3]) != 'nan' else -123456789
                    dic_gdal_text['scale']        = src_band.GetScale()

                    # insert text data
                    for key, value in dic_gdal_text.items():
                        sql = f"UPDATE metadata.layer SET {key} = '{value}' WHERE layer_id = '{layer_id}' AND file_path = '{file_path}'"
                        cur.execute(sql)

                    # insert num data
                    for key, value in dic_gdal_num.items():
                        sql = f"UPDATE metadata.layer SET {key} = {value} WHERE layer_id = '{layer_id}' AND file_path = '{file_path}'"
                        cur.execute(sql)

            # commit changes in the DB per file
            conn.commit()

# open db connection
conn = psycopg2.connect("host='localhost' port='5432' dbname='iso19139' user='glosis'")
cur = conn.cursor()

# run function
rootdir = '/home/carva014/Downloads/FAO/SIS/PH/Processed'
layer_manual_metadata = '/home/carva014/Downloads/FAO/SIS/PH/metadata.xlsx - metadata.tsv'

spatial_data_scan(rootdir)

sql = """UPDATE metadata.layer SET compression = NULL WHERE compression='None';
         UPDATE metadata.layer SET stats_mean = NULL WHERE stats_mean=-123456789;
         UPDATE metadata.layer SET stats_std_dev = NULL WHERE stats_std_dev=-123456789;
         UPDATE metadata.layer SET no_data_value = NULL WHERE no_data_value=-123456789;"""
cur.execute(sql)
if len(layer_manual_metadata) > 1:
    sql = "TRUNCATE metadata.layer_manual_metadata"
    cur.execute(sql)
    with open(layer_manual_metadata, "r") as file:
        cur.copy_expert("COPY metadata.layer_manual_metadata FROM STDIN WITH DELIMITER E'\t' CSV HEADER", file)

    sql = """UPDATE metadata.mapset m
            SET min_stats_minimum = t.min,
                max_stats_maximum = t.max
            FROM (SELECT mapset_id, min(stats_minimum) min, max(stats_maximum) max FROM metadata.layer GROUP BY mapset_id) t
            WHERE m.mapset_id = t.mapset_id"""
    cur.execute(sql)

    # update table mapset with manual metadata
    sql = """UPDATE metadata.mapset mp
            SET title = m.title,
                creation_date = m.creation_date::date,
                revision_date = m.revision_date::date,
                publication_date = m.publication_date::date,
                abstract = m.abstract,
                keyword_theme = m.keyword_theme,
                keyword_place = m.keyword_place,
                update_frequency = m.update_frequency,
                access_constraints = m.access_constraints,
                use_constraints = m.use_constraints,
                other_constraints = m.other_constraints,
                distance_uom = m.distance_uom,
                time_period_begin = m.time_period_begin::date,
                time_period_end = m.time_period_end::date,
                citation_md_identifier_code = m.citation_md_identifier_code,
                lineage_statement = m.lineage_statement
            FROM metadata.layer_manual_metadata m
            WHERE mp.mapset_id = m.mapset_id"""
    cur.execute(sql)


    # insert organisation
    sql = """INSERT INTO metadata.organisation (organisation_id, url, email, country, city, postal_code, delivery_point)
            SELECT DISTINCT organisation_id, url, organisation_email, country, city, postal_code, delivery_point
            FROM metadata.layer_manual_metadata
            ON CONFLICT (organisation_id) DO NOTHING"""
    cur.execute(sql)

    # insert individual
    sql = """INSERT INTO metadata.individual (individual_id, email)
            SELECT DISTINCT individual_id, email
            FROM metadata.layer_manual_metadata
            ON CONFLICT (individual_id) DO NOTHING"""
    cur.execute(sql)

    # insert ver_x_org_x_ind
    sql = """INSERT INTO metadata.ver_x_org_x_ind (mapset_id, tag, "role", "position", organisation_id, individual_id)
            SELECT DISTINCT l.mapset_id, 'contact', 'resourceProvider', m.position, m.organisation_id, m.individual_id
            FROM metadata.layer l
            LEFT JOIN metadata.layer_manual_metadata m ON  m.mapset_id = l.mapset_id
                UNION
            SELECT DISTINCT l.mapset_id, 'pointOfContact', 'author', m.position, m.organisation_id, m.individual_id
            FROM metadata.layer l
            LEFT JOIN metadata.layer_manual_metadata m ON  m.mapset_id = l.mapset_id
            ON CONFLICT (mapset_id, tag, role, "position", organisation_id, individual_id) DO NOTHING"""
    cur.execute(sql)

    # insert url
    sql = """INSERT INTO metadata.url (mapset_id, protocol, url, url_name)
            SELECT DISTINCT mapset_id, 'WWW:LINK-1.0-http--link', url_paper, 'Scientific paper' FROM metadata.layer_manual_metadata WHERE url_paper IS NOT NULL
                UNION
            SELECT DISTINCT mapset_id, 'WWW:LINK-1.0-http--link', url_project, 'Project webpage' FROM metadata.layer_manual_metadata WHERE url_project IS NOT NULL
                UNION
            SELECT m.mapset_id, 'WWW:LINK-1.0-http--link', 'https://storage.googleapis.com/fao-gismgr-glosis-data/DATA/GLOSIS/MAP/'||l.layer_id||'.'||l.file_extension , 'Download '||l.dimension_des 
            FROM metadata.layer_manual_metadata m
            LEFT JOIN metadata.layer l ON l.mapset_id = m.mapset_id
                UNION
            SELECT mapset_id, 'OGC:WMTS', 'https://data.apps.fao.org/map/wmts/wmts?layer=fao-gismgr/GLOSIS/maps/'||mapset_id||'&tilematrixset=EPSG:900913&Service=WMTS&request=GetCapabilities', 'Web Map Tile Service'
            FROM metadata.layer_manual_metadata
            ON CONFLICT (mapset_id, protocol, url) DO NOTHING"""
    cur.execute(sql)

    # # insert categories
    # sql = """SELECT metadata.create_category('PH-GSAS-EC-2020', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSAS-ESP-2020', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSAS-PH-2020', 10, '#000249', '#DD1717');
    #         SELECT metadata.create_category('PH-GSAS-SALT-2020', 10, '#000249', '#DD1717');
    #         SELECT metadata.create_category('PH-GSOC-ADBAU-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-ADSSM1-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-ADSSM2-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-ADSSM3-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-ASRBAU-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-ASRSSM1-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-ASRSSM2-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-ASRSSM3-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RDSSM1-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RDSSM2-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RDSSM3-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RSRSSM1-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RSRSSM1U-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RSRSSM2-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RSRSSM2U-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RSRSSM3-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-RSRSSM3U-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-SOCBAU-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-SOCSSM1-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-SOCSSM2-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-SOCSSM3-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-SSMU-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSOC-T0-2021', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSNM-BD-2023', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSNM-CEC-2023', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSNM-CLAY-2023', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSNM-K-2023', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSNM-OC-2023', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSNM-P-2023', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSNM-PH-2023', 10, '#000249', '#DD1717');
    #         SELECT metadata.create_category('PH-GSNM-SAND-2023', 10, '#F4E7D3', '#5C4033');
    #         SELECT metadata.create_category('PH-GSNM-SILT-2023', 10, '#F4E7D3', '#5C4033');"""
    # cur.execute(sql)

# close db connection
conn.commit()
cur.close()
conn.close()




