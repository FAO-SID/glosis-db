#!/bin/env python
#coding:utf-8


import psycopg2
import re
import ast
import json
from datetime import datetime


def multireplace(string, replacements):
    """
    Given a string and a replacement map, it returns the replaced string.
    :param str string: string to execute replacements on
    :param dict replacements: replacement dictionary {value to find: value to replace}
    :rtype: str
    """
    # Place longer ones first to keep shorter substrings from matching where the longer ones should take place
    # For instance given the replacements {'ab': 'AB', 'abc': 'ABC'} against the string 'hey abc', it should produce
    # 'hey ABC' and not 'hey ABc'
    substrs = sorted(replacements, key=len, reverse=True)

    # Create a big OR regex that matches any of the substrings to replace
    regexp = re.compile('|'.join(map(re.escape, substrs)))

    # For each match, look up the new string in the replacements
    return regexp.sub(lambda match: replacements[match.group(0)], string)



def bake_json(project_id, template, output):
    
    print(f'Creating metadata for project {project_id} ...')

    # vars
    replace = {}
    today = datetime.now()
    revision_date = today.strftime("%Y-%m-%dT%H:%M:%S")
    
    
    # iterate variables
    sql = f'''SELECT l.mapset_id
              FROM metadata.project p
              LEFT JOIN metadata.mapset m ON m.project_id = p.project_id 
              LEFT JOIN metadata.mapset l ON l.mapset_id = m.mapset_id 
              WHERE p.project_id = '{project_id}'
              ORDER BY l.mapset_id
          '''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        mapset_id = row[0]
    
        # read metadata from table metadata.mapset
        sql = f'''SELECT parent_identifier,
                        file_identifier,
                        language_code, 
                        metadata_standard_name, 
                        metadata_standard_version,
                        reference_system_identifier_code_space, 
                        title, 
                        creation_date, 
                        publication_date, 
                        revision_date, 
                        edition, 
                        citation_md_identifier_code, 
                        citation_md_identifier_code_space,
                        abstract, 
                        status,
                        update_frequency,
                        md_browse_graphic, 
                        keyword_theme, 
                        keyword_place, 
                        keyword_discipline, 
                        access_constraints, 
                        use_constraints, 
                        other_constraints, 
                        spatial_representation_type_code,
                        presentation_form,
                        topic_category, 
                        time_period_begin, 
                        time_period_end,
                        scope_code, 
                        lineage_statement, 
                        lineage_source_uuidref, 
                        lineage_source_title
                 FROM metadata.mapset 
                 WHERE mapset_id='{mapset_id}' '''
        cur.execute(sql)
        row = cur.fetchone()

        parent_identifier = 'UNKNOWN' if row[0] == None else str(row[0])
        file_identifier = 'UNKNOWN' if row[1] == None else str(row[1])
        language_code = 'UNKNOWN' if row[2] == None else str(row[2])
        metadata_standard_name = 'UNKNOWN' if row[3] == None else str(row[3])
        metadata_standard_version = 'UNKNOWN' if row[4] == None else str(row[4])
        reference_system_identifier_code_space = 'EPSG' if row[5] == None else str(row[5])
        title = 'UNKNOWN' if row[6] == None else str(row[6])
        creation_date = '1900-01-01' if row[7] == None else str(row[7])
        publication_date = '1900-01-01' if row[8] == None else str(row[8])
        revision_date = '1900-01-01' if row[9] == None else str(row[9])
        edition = 'UNKNOWN' if row[10] == None else str(row[10])
        citation_md_identifier_code = 'UNKNOWN' if row[11] == None else str(row[11])
        citation_md_identifier_code_space = 'UNKNOWN' if row[12] == None else str(row[12])
        abstract = 'UNKNOWN' if row[13] == None else str(row[13])
        status = 'UNKNOWN' if row[14] == None else str(row[14])
        update_frequency = 'UNKNOWN' if row[15] == None else str(row[15])
        md_browse_graphic = 'UNKNOWN' if row[16] == None else str(row[16])
        keyword_theme = 'UNKNOWN' if row[17] == None else str(row[17])
        keyword_place = 'UNKNOWN' if row[18] == None else str(row[18])
        keyword_discipline = 'UNKNOWN' if row[19] == None else str(row[19])
        access_constraints = 'UNKNOWN' if row[20] == None else str(row[20])
        use_constraints = 'UNKNOWN' if row[21] == None else str(row[21])
        other_constraints = 'UNKNOWN' if row[22] == None else str(row[22])
        spatial_representation_type_code = 'UNKNOWN' if row[23] == None else str(row[23])
        presentation_form = 'UNKNOWN' if row[24] == None else str(row[24])
        topic_category = 'UNKNOWN' if row[25] == None else str(row[25])
        time_period_begin = '1900-01-01' if row[26] == None else str(row[26])
        time_period_end = '1900-01-01' if row[27] == None else str(row[27])
        scope_code = 'UNKNOWN' if row[28] == None else str(row[28])
        lineage_statement = 'UNKNOWN' if row[29] == None else str(row[29])


        # read metadata from table metadata.layer
        sql = f'''SELECT DISTINCT
                        reference_system_identifier_code,
                        distance,
                        distance_uom,
                        west_bound_longitude, 
                        east_bound_longitude, 
                        south_bound_latitude, 
                        north_bound_latitude, 
                        distribution_format,
                        data_type,
                        raster_size_x,
                        raster_size_y,
                        pixel_size_x,
                        pixel_size_y
                 FROM metadata.layer 
                 WHERE mapset_id='{mapset_id}' '''
        cur.execute(sql)
        row = cur.fetchone()

        reference_system_identifier_code = '-1' if row[0] == None else str(row[0])
        distance = '0' if row[1] == None else str(row[1])
        distance_uom = 'UNKNOWN' if row[2] == None else str(row[2])
        west_bound_longitude = '0' if row[3] == None else str(row[3])
        east_bound_longitude = '0' if row[4] == None else str(row[4])
        south_bound_latitude = '0' if row[4] == None else str(row[4])
        north_bound_latitude = '0' if row[6] == None else str(row[6])
        distribution_format = 'UNKNOWN' if row[7] == None else str(row[7])
        data_type = 'UNKNOWN' if row[8] == None else str(row[8])
        raster_size_x = 'UNKNOWN' if row[9] == None else str(row[9])
        raster_size_y = 'UNKNOWN' if row[10] == None else str(row[10])
        pixel_size_x = 'UNKNOWN' if row[11] == None else str(row[11])
        pixel_size_y = 'UNKNOWN' if row[12] == None else str(row[12])

        # # editon
        # edition_json = ''
        # if edition != 'UNKNOWN':
        #     edition_json = f'''
        #   <gmd:edition>
        #     <gco:CharacterString>{edition}</gco:CharacterString>
        #   </gmd:edition>'''


        # # citation_md_identifier uuid
        # citation_md_identifier_uuid_json = ''
        # if file_identifier != 'UNKNOWN':
        #     citation_md_identifier_uuid_json = f'''
        #   <gmd:identifier>
        #    <gmd:MD_Identifier>
        #     <gmd:code>
        #      <gco:CharacterString>{file_identifier}</gco:CharacterString>
        #     </gmd:code>
        #     <gmd:codeSpace>
        #      <gco:CharacterString>uuid</gco:CharacterString>
        #     </gmd:codeSpace>
        #    </gmd:MD_Identifier>
        #   </gmd:identifier>'''


        # # citation_md_identifier doi
        # citation_md_identifier_doi_json = ''
        # if citation_md_identifier_code != 'UNKNOWN':
        #     citation_md_identifier_doi_json = f'''
        #   <gmd:identifier>
        #    <gmd:MD_Identifier>
        #     <gmd:code>
        #      <gco:CharacterString>{citation_md_identifier_code}</gco:CharacterString>
        #     </gmd:code>
        #     <gmd:codeSpace>
        #      <gco:CharacterString>{citation_md_identifier_code_space}</gco:CharacterString>
        #     </gmd:codeSpace>
        #    </gmd:MD_Identifier>
        #   </gmd:identifier>'''


        # keyword_theme, must be seperated by coma
        keyword_theme_json = ''
        n = len(ast.literal_eval(keyword_theme))
        c = 0
        for k in keyword_theme.split(','):
            c = c + 1
            k = k.strip(" ")
            k = k.strip("[]")
            k = k.strip("'")
            k = k.replace(" ", "-")
            k = k.lower()
            if c < n:
              keyword_theme_part = f'''
            "{k}",'''
            else:
              keyword_theme_part = f'''
            "{k}"'''
            keyword_theme_json = keyword_theme_json + keyword_theme_part
        
        
        # keyword_discipline, must be seperated by coma
        keyword_discipline_json = ''
        n = len(ast.literal_eval(keyword_discipline))
        c = 0
        for k in keyword_discipline.split(','):
            c = c + 1
            k = k.strip(" ")
            k = k.strip("[]")
            k = k.strip("'")
            k = k.replace(" ", "-")
            k = k.lower()
            if c < n:
              keyword_discipline_part = f'''
            "{k}",'''
            else:
              keyword_discipline_part = f'''
            "{k}"'''
            keyword_discipline_json = keyword_discipline_json + keyword_discipline_part


        # keyword_place, must be seperated by coma
        keyword_place_json = ''
        n = len(ast.literal_eval(keyword_place))
        c = 0
        for k in keyword_place.split(','):
            c = c + 1
            k = k.strip(" ")
            k = k.strip("[]")
            k = k.strip("'")
            k = k.replace(" ", "-")
            k = k.lower()
            if c < n:
              keyword_place_part = f'''
            "{k}",'''
            else:
              keyword_place_part = f'''
            "{k}"'''
            keyword_place_json = keyword_place_json + keyword_place_part


        # deal with vector/grid resolution
        if spatial_representation_type_code == 'grid':
            # Build the dictionary
          spatial_representation_info = {
      "gridSpatialRepresentation": [
    {
        "numberOfDimensions": "2",
        "dimension": [
            {
                "dimensionName": "row",
                "dimensionSize": str(raster_size_y),
                "resolution": {
                    "value": str(pixel_size_y),
                    "uom": str(distance_uom)
                }
            },
            {
                "dimensionName": "column",
                "dimensionSize": str(raster_size_x),
                "resolution": {
                    "value": str(pixel_size_x),
                    "uom": str(distance_uom)
                }
            }
        ],
        "transformationParameterAvailability": False
    }
  ]
}
          # Convert the dictionary to a JSON string
          spatial_representation_info_json = json.dumps(spatial_representation_info, indent=2)

        # elif spatial_representation_type_code == 'vector':
        #     resolution = f'''
        #   <gmd:equivalentScale>
        #     <gmd:MD_RepresentativeFraction>
        #       <gmd:denominator>
        #       <gco:Integer>{distance_uom}</gco:Integer>
        #       </gmd:denominator>
        #     </gmd:MD_RepresentativeFraction>
        #   </gmd:equivalentScale>'''


        # topic_category, must be seperated by coma
        topic_category_json = ''
        n = len(ast.literal_eval(topic_category))
        c = 0
        for k in topic_category.split(','):
            c = c + 1
            k = k.strip(" ")
            k = k.strip("[]")
            k = k.strip("'")
            k = k.replace(" ", "-")
            if c < n:
              topic_category_part = f'''
            "{k}",'''
            else:
              topic_category_part = f'''
            "{k}"'''
            topic_category_json = topic_category_json + topic_category_part


  #       # contact_ci_responsible_party
  #       contact_ci_responsible_party_json = ''
  #       sql = f'''SELECT o.organisation_id, 
  #                       o.url,
  #                       o.email,
  #                       o.country, 
  #                       o.city, 
  #                       o.postal_code, 
  #                       o.delivery_point,
  #                       o.phone,
  #                       o.facsimile,
  #                       i.individual_id, 
  #                       i.email, 
  #                       v.tag, 
  #                       v.role, 
  #                       v.position
  #                FROM metadata.ver_x_org_x_ind v
  #                LEFT JOIN metadata.organisation o ON o.organisation_id = v.organisation_id
  #                LEFT JOIN metadata.individual i ON i.individual_id = v.individual_id
  #                WHERE v.mapset_id ='{mapset_id}'
  #                  AND v.tag = 'contact'
  #                ORDER BY i.individual_id'''
  #       cur.execute(sql)
  #       rows = cur.fetchall()
  #       for row in rows:
  #           organisation_id = row[0]
  #           url = '' if row[1] == None else row[1]
  #           o_email = row[2]
  #           country = row[3]
  #           city = row[4]
  #           postal_code = row[5]
  #           delivery_point = '' if row[6] == None else row[6]
  #           phone = '' if row[7] == None else row[7]
  #           facsimile = '' if row[8] == None else row[8]
  #           individual_id = row[9]
  #           i_email = row[10]
  #           tag = row[11]
  #           role = row[12]
  #           position = row[13]

  #           contact_ci_responsible_party_part = f'''
  # <gmd:contact>
  #   <gmd:CI_ResponsibleParty>
  #     <gmd:individualName>
  #       <gco:CharacterString>{individual_id}</gco:CharacterString>
  #     </gmd:individualName>
  #     <gmd:organisationName>
  #       <gco:CharacterString>{organisation_id}</gco:CharacterString>
  #     </gmd:organisationName>
  #     <gmd:positionName>
  #       <gco:CharacterString>{position}</gco:CharacterString>
  #     </gmd:positionName>
  #     <gmd:contactInfo>
  #       <gmd:CI_Contact>
  #         <gmd:phone>
  #           <gmd:CI_Telephone>
  #             <gmd:voice gco:nilReason="missing">
  #               <gco:CharacterString />
  #             </gmd:voice>
  #             <gmd:facsimile gco:nilReason="missing">
  #               <gco:CharacterString />
  #             </gmd:facsimile>
  #           </gmd:CI_Telephone>
  #         </gmd:phone>
  #         <gmd:address>
  #           <gmd:CI_Address>
  #             <gmd:deliveryPoint>
  #               <gco:CharacterString>{delivery_point}</gco:CharacterString>
  #             </gmd:deliveryPoint>
  #             <gmd:city>
  #               <gco:CharacterString>{city}</gco:CharacterString>
  #             </gmd:city>
  #             <gmd:administrativeArea gco:nilReason="missing">
  #               <gco:CharacterString />
  #             </gmd:administrativeArea>
  #             <gmd:postalCode>
  #               <gco:CharacterString>{postal_code}</gco:CharacterString>
  #             </gmd:postalCode>
  #             <gmd:country>
  #               <gco:CharacterString>{country}</gco:CharacterString>
  #             </gmd:country>
  #             <gmd:electronicMailAddress>
  #               <gco:CharacterString>{i_email}</gco:CharacterString>
  #             </gmd:electronicMailAddress>
  #           </gmd:CI_Address>
  #         </gmd:address>
  #       </gmd:CI_Contact>
  #     </gmd:contactInfo>
  #     <gmd:role>
  #       <gmd:CI_RoleCode codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/codelist/ML_gmxCodelists.json#CI_RoleCode" codeListValue="metadataProvider" />
  #     </gmd:role>
  #   </gmd:CI_ResponsibleParty>
  # </gmd:contact>'''
  #           contact_ci_responsible_party_json = contact_ci_responsible_party_json + contact_ci_responsible_party_part
        
        
  #       # point_of_contact_ci_responsible_party
  #       point_of_contact_ci_responsible_party_json = ''
  #       sql = f'''SELECT o.organisation_id, 
  #                       o.url,
  #                       o.email,
  #                       o.country, 
  #                       o.city, 
  #                       o.postal_code, 
  #                       o.delivery_point,
  #                       o.phone,
  #                       o.facsimile,
  #                       i.individual_id, 
  #                       i.email, 
  #                       v.tag, 
  #                       v.role, 
  #                       v.position
  #                FROM metadata.ver_x_org_x_ind v
  #                LEFT JOIN metadata.organisation o ON o.organisation_id = v.organisation_id
  #                LEFT JOIN metadata.individual i ON i.individual_id = v.individual_id
  #                WHERE v.mapset_id ='{mapset_id}'
  #                  AND v.tag = 'pointOfContact'
  #                ORDER BY i.individual_id'''
  #       cur.execute(sql)
  #       rows = cur.fetchall()
  #       for row in rows:
  #           organisation_id = row[0]
  #           url = '' if row[1] == None else row[1]
  #           o_email = row[2]
  #           country = row[3]
  #           city = row[4]
  #           postal_code = row[5]
  #           delivery_point = '' if row[6] == None else row[6]
  #           phone = '' if row[7] == None else row[7]
  #           facsimile = '' if row[8] == None else row[8]
  #           individual_id = row[9]
  #           i_email = row[10]
  #           tag = row[11]
  #           role = row[12]
  #           position = row[13]

  #           point_of_contact_ci_responsible_party_part = f'''
  #         <gmd:pointOfContact>
  #           <gmd:CI_ResponsibleParty>
  #             <gmd:individualName>
  #               <gco:CharacterString>{individual_id}</gco:CharacterString>
  #             </gmd:individualName>
  #             <gmd:organisationName>
  #               <gco:CharacterString>{organisation_id}</gco:CharacterString>
  #             </gmd:organisationName>
  #             <gmd:positionName>
  #               <gco:CharacterString>{position}</gco:CharacterString>
  #             </gmd:positionName>
  #             <gmd:contactInfo>
  #               <gmd:CI_Contact>
  #                 <gmd:phone>
  #                   <gmd:CI_Telephone>
  #                     <gmd:voice gco:nilReason="missing">
  #                       <gco:CharacterString />
  #                     </gmd:voice>
  #                     <gmd:facsimile gco:nilReason="missing">
  #                       <gco:CharacterString />
  #                     </gmd:facsimile>
  #                   </gmd:CI_Telephone>
  #                 </gmd:phone>
  #                 <gmd:address>
  #                   <gmd:CI_Address>
  #                     <gmd:deliveryPoint>
  #                       <gco:CharacterString>{delivery_point}</gco:CharacterString>
  #                     </gmd:deliveryPoint>
  #                     <gmd:city>
  #                       <gco:CharacterString>{city}</gco:CharacterString>
  #                     </gmd:city>
  #                     <gmd:administrativeArea gco:nilReason="missing">
  #                       <gco:CharacterString />
  #                     </gmd:administrativeArea>
  #                     <gmd:postalCode>
  #                       <gco:CharacterString>{postal_code}</gco:CharacterString>
  #                     </gmd:postalCode>
  #                     <gmd:country>
  #                       <gco:CharacterString>{country}</gco:CharacterString>
  #                     </gmd:country>
  #                     <gmd:electronicMailAddress>
  #                       <gco:CharacterString>{i_email}</gco:CharacterString>
  #                     </gmd:electronicMailAddress>
  #                   </gmd:CI_Address>
  #                 </gmd:address>
  #               </gmd:CI_Contact>
  #             </gmd:contactInfo>
  #             <gmd:role>
  #               <gmd:CI_RoleCode codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/codelist/ML_gmxCodelists.json#CI_RoleCode" codeListValue="{role}" />
  #             </gmd:role>
  #           </gmd:CI_ResponsibleParty>
  #         </gmd:pointOfContact>'''
  #           point_of_contact_ci_responsible_party_json = point_of_contact_ci_responsible_party_json + point_of_contact_ci_responsible_party_part
        
        
  #       # online_resource
  #       online_resource = ''
  #       sql = f'''SELECT url, protocol, url_name
  #                FROM metadata.url
  #                WHERE mapset_id='{mapset_id}'
  #                  AND protocol IN ('OGC:WMS','OGC:WMTS','WWW:LINK-1.0-http--link', 'WWW:LINK-1.0-http--related')
  #                ORDER BY protocol, url'''
  #       cur.execute(sql)
  #       rows = cur.fetchall()
  #       for row in rows:
  #           url        = row[0]
  #           protocol   = row[1]
  #           url_name   = row[2]
  #           if protocol in ('OGC:WMS','OGC:WMTS'):
  #               function = 'information'
  #           elif protocol in ('WWW:LINK-1.0-http--link', 'WWW:LINK-1.0-http--related'):
  #               function = 'download'
  #           else:
  #               function = 'UNKNOWN'
            
  #           online_resource_part = f'''
  #         <gmd:onLine>
  #           <gmd:CI_OnlineResource>
  #             <gmd:linkage>
  #               <gmd:URL>{url}</gmd:URL>
  #             </gmd:linkage>
  #             <gmd:protocol>
  #               <gco:CharacterString>{protocol}</gco:CharacterString>
  #             </gmd:protocol>
  #             <gmd:name>
  #               <gco:CharacterString>{url_name}</gco:CharacterString>
  #             </gmd:name>
  #             <gmd:description gco:nilReason="missing">
  #               <gco:CharacterString />
  #             </gmd:description>
  #             <gmd:function>
  #               <gmd:CI_OnLineFunctionCode codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/codelist/ML_gmxCodelists.json#CI_OnLineFunctionCode" codeListValue="{function}" />
  #             </gmd:function>
  #           </gmd:CI_OnlineResource>
  #         </gmd:onLine>'''
  #           online_resource = online_resource + online_resource_part
        
        
        # fill dicionary
        replace['***file_identifier***'] = file_identifier
        replace['***language_code***'] = language_code
        # replace['***contact_ci_responsible_party_json***'] = contact_ci_responsible_party_json
        replace['***revision_date***'] = revision_date
        replace['***metadata_standard_name***'] = metadata_standard_name
        replace['***metadata_standard_version***'] = metadata_standard_version
        replace['***reference_system_identifier_code***'] = reference_system_identifier_code
        replace['***reference_system_identifier_code_space***'] = reference_system_identifier_code_space
        replace['***title***'] = title
        replace['***creation_date***'] = creation_date
        replace['***publication_date***'] = publication_date
        # replace['***edition_json***'] = edition_json
        # replace['***citation_md_identifier_uuid_json***'] = citation_md_identifier_uuid_json
        # replace['***citation_md_identifier_doi_json***'] = citation_md_identifier_doi_json
        replace['***abstract***'] = abstract
        replace['***status***'] = status
        replace['***update_frequency***'] = update_frequency
        # replace['***point_of_contact_ci_responsible_party_json***'] = point_of_contact_ci_responsible_party_json
        replace['***md_browse_graphic***'] = '%s' % md_browse_graphic
        replace['***keyword_theme_json***'] = keyword_theme_json
        replace['***keyword_discipline_json***'] = keyword_discipline_json
        replace['***keyword_place_json***'] = keyword_place_json
        replace['***access_constraints***'] = access_constraints
        replace['***use_constraints***'] = use_constraints
        replace['***other_constraints***'] = other_constraints
        replace['***spatial_representation_type_code***'] = spatial_representation_type_code
        replace['***presentation_form***'] = presentation_form
        replace['***spatial_representation_info_json***'] = spatial_representation_info_json
        replace['***topic_category***'] = topic_category_json
        replace['***time_period_begin***'] = time_period_begin
        replace['***time_period_end***'] = time_period_end
        replace['***west_bound_longitude***'] = west_bound_longitude
        replace['***east_bound_longitude***'] = east_bound_longitude
        replace['***south_bound_latitude***'] = south_bound_latitude
        replace['***north_bound_latitude***'] = north_bound_latitude
        replace['***distance***'] = distance
        replace['***distance_uom***'] = distance_uom
        replace['***distribution_format***'] = distribution_format
        # replace['***online_resource***'] = online_resource
        replace['***scope_code***'] = scope_code
        replace['***lineage_statement***'] = lineage_statement
        replace['***data_type***'] = data_type
        

        # write json to file
        open_file = open(template, 'r')
        read_file = open_file.read()
        write_file = open(output+'/%s.json' % mapset_id,'w')
        write_file.write(multireplace(read_file, replace))


        # write json in db
        # sql = f"UPDATE metadata.mapset SET json = '{multireplace(read_file, replace)}' WHERE mapset_id = '{mapset_id}'"
        # cur.execute(sql)

        
        # close files
        open_file.close
        write_file.close
        print(mapset_id)


    # close database connection
    conn.commit()
    return


# open db connection
conn = psycopg2.connect("host='localhost' port='5432' dbname='iso19139' user='glosis'")
cur = conn.cursor()


# run function
template='/home/carva014/Work/Code/FAO/glosis-db/Metadata/template.json'
output='/home/carva014/Downloads/FAO/SIS/PH/Processed'
bake_json('GSAS', template, output)
bake_json('GSOC', template, output)
bake_json('GSNM', template, output)


# close db connection
conn.commit()
cur.close()
conn.close()