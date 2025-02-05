#coding: utf-8

import os
import sys
import psycopg2
from osgeo import gdal, osr
import math

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

def spatial_data_scan(project_id, rootdir):

    # insert project
    sql = f"INSERT INTO metadata.project(project_id) VALUES('{project_id}') ON CONFLICT (project_id) DO NOTHING"
    cur.execute(sql)

    # iterate files
    for subdir, dirs, files in os.walk(rootdir):
        for file in files:

            # diccionary to store variables
            dic_gdal_num={}
            dic_gdal_text={}

            # get path
            file_name = str(file)
            file_path = str(subdir)
            path = os.path.join(subdir, file)

            # file metadata
            file_stat        = os.stat(path)
            file_size        = file_stat[6]
            file_size_pretty = convert_size(file_stat[6])
            file_extension   = os.path.splitext(file)[-1].lstrip('.').lower()

            if os.path.splitext(file)[-1].lstrip('.').lower() in ['asc', 'ecw', 'grb', 'rb2', 'hdf', 'jpg', 'nc', 'tif']:

                # insert mapset and layer
                print (file_name)
                sql = f"DELETE FROM metadata.mapset WHERE project_id='{project_id}' AND mapset_id='{file_name}'"
                cur.execute(sql)
                sql = f"INSERT INTO metadata.mapset(mapset_id, project_id, agg_by) VALUES('{file_name[:-4]}', '{project_id}', 'depth')"
                cur.execute(sql)
                sql = f"INSERT INTO metadata.layer(mapset_id, layer_id, file_path, file_name, file_size, file_size_pretty, file_extension) VALUES('{file_name[:-4]}','{file_name[:-4]}','{file_path}','{file_name}','{file_size}','{file_size_pretty}','{file_extension}')"
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
                dic_gdal_num['pixel_size_x'] = geo_transform[1]
                dic_gdal_num['pixel_size_y'] = geo_transform[5]
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
                    dic_gdal_num['no_data_value'] = src_band.GetNoDataValue()
                    dic_gdal_num['stats_minimum'] = stats[0]
                    dic_gdal_num['stats_maximum'] = stats[1]
                    dic_gdal_num['stats_mean']    = stats[2] if str(stats[2]) != 'nan' else -123456789
                    dic_gdal_num['stats_std_dev'] = stats[3] if str(stats[3]) != 'nan' else -123456789
                    dic_gdal_text['scale']        = src_band.GetScale()

                    # insert text data
                    for key, value in dic_gdal_text.items():
                        sql = f"UPDATE metadata.layer SET {key} = '{value}' WHERE file_name = '{file_name}' AND file_path = '{file_path}'"
                        cur.execute(sql)

                    # insert num data
                    for key, value in dic_gdal_num.items():
                        sql = f"UPDATE metadata.layer SET {key} = {value} WHERE file_name = '{file_name}' AND file_path = '{file_path}'"
                        cur.execute(sql)

            # commit changes in the DB per file
            conn.commit()

# variables
project_id = 'GSOC'
rootdir = '/home/carva014/Downloads/FAO/SIS/PH/Original/GSOCseq/'

# open db connection
conn = psycopg2.connect("host='localhost' port='5432' dbname='iso19139' user='glosis'")
cur = conn.cursor()

# run function
spatial_data_scan(project_id, rootdir)
sql = """UPDATE metadata.layer SET compression = NULL WHERE compression='None';
         UPDATE metadata.layer SET stats_mean = NULL WHERE stats_mean=-123456789;
         UPDATE metadata.layer SET stats_std_dev = NULL WHERE stats_std_dev=-123456789;"""
cur.execute(sql)

# close db connection
conn.commit()
cur.close()
conn.close()
