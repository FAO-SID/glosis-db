#coding: utf-8

import psycopg2

def export_style(output, project_id):
    
    print(f'Exporting XML, SLD, MAP for project {project_id} ...')

    # symbology
    sql = f"""  SELECT DISTINCT pr.property_id, pr.sld
                FROM metadata.project p 
                LEFT JOIN metadata.mapset m ON m.project_id = p.project_id
                LEFT JOIN metadata.property pr ON pr.property_id = m.property_id
                WHERE pr.sld IS NOT NULL 
                  AND p.project_id = '{project_id}'
                ORDER BY pr.property_id"""
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        property = row[0]
        content = row[1]
        write_file = open(f'{output}/SOIL-{property}.sld','w')
        write_file.write(content)
        write_file.close

    # metadata
    sql = f"""  SELECT m.mapset_id, m.xml
                FROM metadata.project p 
                LEFT JOIN metadata.mapset m ON m.project_id = p.project_id
                WHERE m.xml IS NOT NULL 
                  AND p.project_id = '{project_id}'
                ORDER BY m.mapset_id"""
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        mapset = row[0]
        content = row[1]
        write_file = open(f'{output}/{mapset}.xml','w')
        write_file.write(content)
        write_file.close
    
    # mapfile
    sql = f"""  SELECT l.layer_id, l.map
                FROM metadata.project p 
                LEFT JOIN metadata.mapset m ON m.project_id = p.project_id
                LEFT JOIN metadata.layer l ON l.mapset_id = m.mapset_id  
                WHERE l.map IS NOT NULL 
                  AND p.project_id = '{project_id}'
                ORDER BY l.layer_id"""
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        layer = row[0]
        content = row[1]
        write_file = open(f'{output}/{layer}.map','w')
        write_file.write(content)
        write_file.close
    return

# open db connection
conn = psycopg2.connect("host='localhost' port='5432' dbname='iso19139' user='glosis'")
cur = conn.cursor()

# run function
output='/home/carva014/Downloads/FAO/SIS/PH/Processed'
export_style(output, 'GSOC')
export_style(output, 'GSNM')
export_style(output, 'GSAS')

# close db connection
conn.commit()
cur.close()
conn.close()
