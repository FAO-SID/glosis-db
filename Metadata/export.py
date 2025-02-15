#coding: utf-8

import psycopg2

def export_style(output, project_id):
    
    print(f'Exporting XML, SLD, MAP for project {project_id} ...')

    # iterate formats and records
    for f in ['sld', 'xml']:
        sql = f"""  SELECT m.mapset_id, {f}
                    FROM metadata.project p 
                    LEFT JOIN metadata.mapset m ON m.project_id = p.project_id
                    WHERE m.{f} IS NOT NULL 
                      AND p.project_id = '{project_id}'
                    ORDER BY m.mapset_id"""
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            mapset = row[0]
            content = row[1]
            write_file = open(f'{output}/{mapset}.{f}','w')
            write_file.write(content)
            write_file.close
            # print(f'\t {mapset}.{f}')
    
    for f in ['map']:
        sql = f"""  SELECT l.layer_id, {f}
                    FROM metadata.project p 
                    LEFT JOIN metadata.mapset m ON m.project_id = p.project_id
                    LEFT JOIN metadata.layer l ON l.mapset_id = m.mapset_id  
                    WHERE l.{f} IS NOT NULL 
                      AND p.project_id = '{project_id}'
                    ORDER BY l.layer_id"""
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            layer = row[0]
            content = row[1]
            write_file = open(f'{output}/{layer}.{f}','w')
            write_file.write(content)
            write_file.close
            # print(f'\t {layer}.{f}')
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
