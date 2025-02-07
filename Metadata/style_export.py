# importing
import psycopg2


def export_style(project_id):
    
    # variable
    output_folder = '/home/carva014/Downloads'

    # iterate formats and records
    for f in ['sld', 'qml', 'map']:
        # sql = f"SELECT layer_id, {f} FROM metadata.layer_category WHERE {f} IS NOT NULL AND project_id = '{project_id}'"
        sql = f"SELECT layer_id, {f} FROM metadata.layer_category WHERE layer_id IN ('')"
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            layer = row[0]
            content = row[1]
            write_file = open(f'{output_folder}/{layer}.{f}','w')
            write_file.write(content)
            write_file.close
            print(f'\t {layer}.{f}')
    return

# open db connection
conn = psycopg2.connect("host='localhost' port='5432' dbname='iso19139' user='glosis'")
cur = conn.cursor()

# export SLD, QML and MAP files
export_style('mapset_id')
# export_style('LBK')

# Close database connection
cur.close()
conn.close()
