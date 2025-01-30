#coding: utf-8


import os
import time
import psycopg2
import datetime
import struct
import subprocess
from osgeo import gdal, ogr, osr
import math
import getpass


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
            
            
            # dics to store variables
            dic_file={}
            dic_gdal={}
            
            
            # get path
            file_name = str(file)
            folder = str(subdir)
            path = str(os.path.join(subdir, file))
            print (path)
            
            
            # insert folder and file_name only
            sql = '''INSERT INTO metadata.file(folder,file_name) VALUES('%s','%s');''' %(folder,file_name)
            cur.execute(sql)
            
            
            # file data
            file_stat                     = os.stat(path)
            dic_file['file_mode']         = file_stat[0]
            dic_file['file_ino']          = file_stat[1]
            dic_file['file_dev']          = file_stat[2]
            dic_file['file_nlink']        = file_stat[3]
            dic_file['file_uid']          = file_stat[4]
            dic_file['file_gid']          = file_stat[5]
            dic_file['file_size']         = file_stat[6]
            dic_file['file_size_pretty']  = convert_size(file_stat[6])
            dic_file['file_atime']        = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(file_stat[7])) # time stamp of last access
            dic_file['file_mtime']        = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(file_stat[8])) # time stamp of last modified
            dic_file['file_ctime']        = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(file_stat[9])) # time stamp of last changed
            dic_file['variable']          = file_name.split('.')[0]
            dic_file['driver']            = file[-3:].lower()
            
            
            if file[-3:].lower() in ['asc', 'ecw', 'grb', 'rb2', 'hdf', 'jpg', '.nc', 'tif']:
                
                
                # gdalinfo in json format
                dic_gdal['json'] = subprocess.check_output("gdalinfo -json %s" % path , shell=True) if subprocess.check_output("gdalinfo -json %s" % path , shell=True) != None else 'None'
                
                
                # open file with GDAL
                src_ds = gdal.Open(path)
                if src_ds is None:
                    print ('Unable to open %s' % path)
                    sys.exit(1)
                
                
                # GDAL info
                dic_gdal['driver']            = src_ds.GetDriver().ShortName
                dic_gdal['driver_long']       = src_ds.GetDriver().LongName
                dic_gdal['raster_size_row']   = src_ds.RasterYSize
                dic_gdal['raster_size_col']   = src_ds.RasterXSize
                image_struture                = src_ds.GetMetadata('IMAGE_STRUCTURE')
                dic_gdal['compression']       = image_struture.get('COMPRESSION', None)
                dic_gdal['metadata']          = str(src_ds.GetMetadata()).replace("'","")
                dic_gdal['n_bands']           = src_ds.RasterCount
                dic_gdal['projection']        = src_ds.GetProjection()
                projection                    = src_ds.GetProjection()
                spatial_reference             = osr.SpatialReference()
                spatial_reference.ImportFromWkt(projection)
                spatial_reference_proj        = spatial_reference.ExportToProj4()
                dic_gdal['coordinate_system'] = spatial_reference.GetAttrValue('AUTHORITY',1)
                dic_gdal['spatial_reference'] = str(spatial_reference)
                dic_gdal['spatial_reference_proj'] = str(spatial_reference_proj)    
                dic_gdal['geo_transform']     = str(src_ds.GetGeoTransform()).replace('(','').replace(')','')
                geo_transform                 = str(src_ds.GetGeoTransform()).replace('(','').replace(')','')
                dic_gdal['origin_x']          = str(geo_transform.split(',')[0]) + ',' + str(geo_transform.split(',')[3])
                dic_gdal['pixel_size']        = str(geo_transform.split(',')[1]) + ',' + str(geo_transform.split(',')[5])
#                geo_transform                 = src_ds.GetGeoTransform()     
#                img_x_min = geo_transform[0]
#                img_pixel_x_size = geo_transform[1]
#                img_geo_transform2 = geo_transform[2]
#                img_y_max = geo_transform[3]
#                img_geo_transform4 = geo_transform[4]
#                img_pixel_y_size = geo_transform[5]
#                dic_gdal['img_x_max'] = img_x_min + (img_raster_x_size * img_pixel_x_size)
#                dic_gdal['img_y_min'] = img_y_max + (img_raster_y_size * img_pixel_y_size)
#                dic_gdal['img_gcp_count'] = src_ds.GetGCPCount()
#                dic_gdal['img_gcp_projection'] = src_ds.GetGCPProjection()
#                dic_gdal['img_gcps'] = src_ds.GetGCPs()
#                dic_gdal['GetFileList'] = str(src_ds.GetFileList()).replace("'","")
                
                
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
                    dic_gdal['stats_minimum'] = stats[0]
                    dic_gdal['stats_maximum'] = stats[1]
                    dic_gdal['stats_mean']    = stats[2] if str(stats[2]) != 'nan' else -9999
                    dic_gdal['stats_std_dev'] = stats[3] if str(stats[3]) != 'nan' else -9999
                    dic_gdal['no_data_value'] = src_band.GetNoDataValue()
                    dic_gdal['data_type_id']     = gdal.GetDataTypeName(src_band.DataType)
                    dic_gdal['band_size_row'] = src_band.YSize
                    dic_gdal['band_size_col'] = src_band.XSize
                    dic_gdal['scale']         = src_band.GetScale()
#                    dic_gdal['color_table'] = src_band.GetColorTable()
#                    (band_min, band_max) = src_band.ComputeRasterMinMax(band_num)
#                    dic_gdal['unit_type']     = src_band.GetUnitType()
#                    dic_gdal['band_description'] = src_band.GetDescription()
#                    (band_x_size, band_y_size) = src_band.GetBlockSize()
#                    dic_gdal['band_color_interpretation'] = src_band.GetRasterColorInterpretation()
#                    dic_gdal['band_color_interpretation_name'] = gdal.GetColorInterpretationName(band_color_interpretation)
#                    dic_gdal['band_overview_count'] = src_band.GetOverviewCount()
#                    dic_gdal['band_mask_flags'] = src_band.GetMaskFlags()
#                    dic_gdal['band_category_names'] = src_band.GetRasterCategoryNames()
#                    dic_gdal['band_default_rat'] = src_band.GetDefaultRAT()
#                    dic_gdal['band_metadata'] = str(src_band.GetMetadata_List()).replace("'","")
                    
                    
                    # merge the two dictionaries
                    dic = dic_file.copy()
                    dic.update(dic_gdal)
                    
                    
                    # insert data
                    for key in dic:
                        value=dic[key]
                        sql = ''' UPDATE metadata.file 
                                  SET %s=%%s
                                  WHERE folder=%%s
                                    AND file_name=%%s; ''' % key
                        data = (value,folder,file_name,)
                        cur.execute(sql,data)
            
            
            # not a raster file
            else:
                for key in dic_file:
                    value=dic_file[key]
                    sql = ''' UPDATE metadata.file 
                              SET %s=%%s
                              WHERE folder=%%s
                                AND file_name=%%s; ''' % key
                    data = (value,folder,file_name,)
                    cur.execute(sql,data)
            
            
            # commit changes in the DB per file
            conn.commit()
    
    
    # stats
    sql = '''SELECT folder, count(*) 
             FROM metadata.file
             GROUP BY folder
             ORDER BY folder;'''
    cur.execute(sql)
    rows = cur.fetchall()
    print('\n')
    for row in rows:
        folder = row[0]
        n = row[1]
        print('%s/:\t%s records' %(folder,n))
    print('\n')
    return


def spatial_data_report():
    report = ''
    
    # Number of files per folder
    title = '\n\t***\tNumber of files per folder\t***'
    header = 'folder | n_files'
    report = report + title + '\n' + header + '\n'
    print(title)
    print(header)
    sql = '''SELECT folder, count(*) AS n_files
             FROM metadata.file
             GROUP BY folder
             ORDER BY folder'''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        folder = row[0]
        n      = row[1]
        print('%s | %s' %(folder,n))
        report = report + '%s | %s\n' %(folder,n)
        
    
    # Number of files per folder, version and dataset
    title = '\n\t***\tNumber of variables and files per dataset and version\t***'
    header = 'dataset | version | n_variables | n_files'
    report = report + title + '\n' + header + '\n'
    print(title)
    print(header)
    sql = '''SELECT dataset_id, version, count(DISTINCT variable) AS n_variables, count(*) AS n_files
             FROM metadata.file
             GROUP BY dataset_id, version
             ORDER BY dataset_id, version;'''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        dataset_id   = row[0]
        version      = row[1]
        n_properties = row[2]
        n_files      = row[3]
        print('%s | %s | %s | %s' %(dataset_id, version, n_properties, n_files))
        report = report + '%s | %s | %s | %s\n' %(dataset_id, version, n_properties, n_files)
    
    
    # Number of files per variable, version and dataset
    title = '\n\t***\tNumber of files per dataset, version and variable\t***'
    header = 'dataset, version, variable, n_files'
    report = report + title + '\n' + header + '\n'
    print(title)
    print(header)
    sql = '''SELECT dataset_id, version, variable, count(*) AS n_files
             FROM metadata.file
             GROUP BY dataset_id, version, variable
             ORDER BY dataset_id, version, variable;'''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        dataset_id  = row[0]
        version     = row[1]
        variable    = row[2]
        n_files     = row[3]
        print('%s | %s | %s | %s' %(dataset_id, version, variable, n_files))
        report = report + '%s | %s | %s | %s\n' %(dataset_id, version, variable, n_files)
    
    
    # WARNING: min observed value equal to max observed value
    title = '\n\t***\tWARNING: min observed value equal to max observed value (PROBABLY CORRUPTED FILES!)\t***'
    header = 'folder | file_name | stats_minimum | stats_maximum | stats_mean | stats_std_dev'
    report = report + title + '\n' + header + '\n'
    print(title)
    print(header)
    sql = '''SELECT folder, file_name, stats_minimum, stats_maximum, stats_mean, stats_std_dev
             FROM metadata.file
             WHERE stats_minimum = stats_maximum
             ORDER BY folder, file_name;'''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        folder         = row[0]
        file_name      = row[1]
        stats_minimum  = row[2]
        stats_maximum  = row[3]
        stats_mean     = row[4]
        stats_std_dev  = row[5]
        print('%s | %s | %s | %s | %s | %s' %(folder, file_name, stats_minimum, stats_maximum, stats_mean, stats_std_dev))
        report = report + '%s | %s | %s | %s | %s | %s\n' %(folder, file_name, stats_minimum, stats_maximum, stats_mean, stats_std_dev)
        
    
    # WARNING: null value for mean and std_dev
    title = '\n\t***\tWARNING: null value for mean and std_dev (PROBABLY CORRUPTED FILES!)\t***'
    header = 'folder, file_name | stats_minimum | stats_maximum | stats_mean | stats_std_dev'
    report = report + title + '\n' + header + '\n'
    print(title)
    print(header)
    sql = '''SELECT folder, file_name, stats_minimum, stats_maximum, stats_mean, stats_std_dev
             FROM metadata.file
             WHERE stats_mean = -9999
               AND stats_std_dev = -9999
               AND stats_minimum != stats_maximum
             ORDER BY folder, file_name;'''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        folder         = row[0]
        file_name      = row[1]
        stats_minimum  = row[2]
        stats_maximum  = row[3]
        stats_mean     = row[4]
        stats_std_dev  = row[5]
        print('%s | %s | %s | %s | %s | %s' %(folder, file_name, stats_minimum, stats_maximum, stats_mean, stats_std_dev))
        report = report + '%s | %s | %s | %s | %s | %s\n' %(folder, file_name, stats_minimum, stats_maximum, stats_mean, stats_std_dev)
        
    
    # WARNING: Wrong data type asignation, these layers should be in "Byte" data type
    title = '\n\t***\tWARNING: Wrong data type asignation, these layers should be in "Byte" data type\t***'
    header = 'folder | file_name | file_size_pretty | data_type | stats_minimum | stats_maximum'
    report = report + title + '\n' + header + '\n'
    print(title)
    print(header)
    sql = '''SELECT folder, file_name, file_size_pretty, data_type_id, stats_minimum, stats_maximum
             FROM metadata.file
             WHERE data_type_id != 'Byte'
               AND stats_minimum >= 0
               AND stats_maximum <= 255
             ORDER BY folder, file_name;'''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        folder           = row[0]
        file_name        = row[1]
        file_size_pretty = row[2]
        data_type_id     = row[3]
        stats_minimum    = row[4]
        stats_maximum    = row[5]
        print('%s | %s | %s | %s | %s | %s' %(folder, file_name, file_size_pretty, data_type_id, stats_minimum, stats_maximum))
        report = report + '%s | %s | %s | %s | %s | %s\n' %(folder, file_name, file_size_pretty, data_type_id, stats_minimum, stats_maximum)
        
    
    # WARNING: Wrong data type asignation, these layers should be in "Int16 or UInt16" data type
    title = '\n\t***\tWARNING: Wrong data type asignation, these layers should be in "Int16 or UInt16" data type\t***'
    header = 'folder | file_name | file_size_pretty | data_type | stats_minimum | stats_maximum'
    report = report + title + '\n' + header + '\n'
    print(title)
    print(header)
    sql = '''SELECT folder, file_name, file_size_pretty, data_type_id, stats_minimum, stats_maximum
             FROM metadata.file
             WHERE data_type_id NOT ILIKE '%16'
               AND stats_minimum BETWEEN -32768 AND -1
               AND stats_maximum BETWEEN 256 AND 32768
             ORDER BY folder, file_name;'''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        folder           = row[0]
        file_name        = row[1]
        file_size_pretty = row[2]
        data_type_id     = row[3]
        stats_minimum    = row[4]
        stats_maximum    = row[5]
        print('%s | %s | %s | %s | %s | %s' %(folder, file_name, file_size_pretty, data_type_id, stats_minimum, stats_maximum))
        report = report + '%s | %s | %s | %s | %s | %s\n' %(folder, file_name, file_size_pretty, data_type_id, stats_minimum, stats_maximum)
    
    
    # insert report
    sql = '''INSERT INTO metadata.report(report) VALUES('%s');''' %report
    cur.execute(sql)
    conn.commit()
    
    print('\n')
    return



# variables
rootdir = '/home/carva014/Downloads/Database_repository_upload'


# database connection
server = input("Server: local (l) or remote (r): ")
if server.lower() in ['l','local']:
    host = 'localhost'
    port = '5432'
if server.lower() in ['r','remote']:
    host = 'scomp1270.wurnet.nl'
    port = '5479'
user = input("User: ")
pswd = getpass.getpass('Password: ')
conn = psycopg2.connect("host='%s' port='%s' dbname='org' user='%s' password='%s'" %(host,port,user,pswd));
cur = conn.cursor()


# tasks
spatial_data_scan(rootdir)
#spatial_data_report()


# close connection
conn.commit()
conn.close()


