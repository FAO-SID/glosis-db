#!/bin/env python
#coding:utf-8


import psycopg2
import re
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



def bake_xml(dataset_id, version, template, output):
    
    
    # vars
    replace = {}
    today = datetime.now()
    revision_date = today.strftime("%Y-%m-%dT%H:%M:%S")
    
    
    # iterate variables
    sql = f''' SELECT version 
              FROM metadata.version
              WHERE dataset_id='{dataset_id}' 
                AND version='{version}'
              ORDER BY version
          '''
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        version = row[0]
    
        
        # read metadata from table metadata.dataset
        sql = f'''SELECT dataset_id, dataset_name
                 FROM metadata.dataset 
                 WHERE dataset_id='{dataset_id}' '''
        cur.execute(sql)
        row = cur.fetchone()
        dataset_id = 'UNKNOWN' if row[0] == None else str(row[0])
        dataset_name = 'UNKNOWN' if row[1] == None else str(row[1])
        
        
        # read metadata from table metadata.version
        sql = f'''SELECT folder,
                        file_identifier, 
                        parent_identifier,
                        language_code, 
                        metadata_standard_name, 
                        metadata_standard_version, 
                        reference_system_identifier_code, 
                        reference_system_identifier_code_space, 
                        title, 
                        creation_date, 
                        publication_date, 
                        revision_date, 
                        edition, 
                        citation_rs_identifier_code, 
                        citation_rs_identifier_code_space,
                        citation_md_identifier_code, 
                        abstract, 
                        status, 
                        md_browse_graphic, 
                        keyword_theme, 
                        keyword_place, 
                        keyword_stratum, 
                        access_constraints, 
                        use_constraints, 
                        other_constraints, 
                        spatial_representation_type_code, 
                        distance_uom, 
                        distance, 
                        topic_category, 
                        time_period_begin, 
                        time_period_end, 
                        west_bound_longitude, 
                        east_bound_longitude, 
                        south_bound_latitude, 
                        north_bound_latitude, 
                        distribution_format, 
                        scope_code, 
                        lineage_statement, 
                        lineage_source_uuidref, 
                        lineage_source_title
                 FROM metadata.version 
                 WHERE dataset_id='{dataset_id}' 
                   AND version='{version}' '''
        cur.execute(sql)
        row = cur.fetchone()
        folder = 'UNKNOWN' if row[0] == None else str(row[0])
        file_identifier = 'UNKNOWN' if row[1] == None else str(row[1])
        language_code = 'UNKNOWN' if row[2] == None else str(row[2])
        parent_identifier = 'UNKNOWN' if row[3] == None else str(row[3])
        metadata_standard_name = 'UNKNOWN' if row[4] == None else str(row[4])
        metadata_standard_version = 'UNKNOWN' if row[5] == None else str(row[5])
        reference_system_identifier_code = '-1' if row[6] == None else str(row[6])
        reference_system_identifier_code_space = 'EPSG' if row[7] == None else str(row[7])
        title = 'UNKNOWN' if row[8] == None else str(row[8])
        creation_date = '1900-01-01' if row[9] == None else str(row[9])
        publication_date = '1900-01-01' if row[10] == None else str(row[10])
        revision_date = '1900-01-01' if row[11] == None else str(row[11])
        edition = 'UNKNOWN' if row[12] == None else str(row[12])
        citation_rs_identifier_code = 'UNKNOWN' if row[13] == None else str(row[13])
        citation_rs_identifier_code_space = 'UNKNOWN' if row[14] == None else str(row[14])
        citation_md_identifier_code = 'UNKNOWN' if row[15] == None else str(row[15])
        abstract = 'UNKNOWN' if row[16] == None else str(row[16])
        status = 'UNKNOWN' if row[17] == None else str(row[17])
        md_browse_graphic = 'UNKNOWN' if row[18] == None else str(row[18])
        keyword_theme = 'UNKNOWN' if row[19] == None else str(row[19])
        keyword_place = 'UNKNOWN' if row[20] == None else str(row[20])
        keyword_stratum = 'UNKNOWN' if row[21] == None else str(row[21])
        access_constraints = 'UNKNOWN' if row[22] == None else str(row[22])
        use_constraints = 'UNKNOWN' if row[23] == None else str(row[23])
        other_constraints = 'UNKNOWN' if row[24] == None else str(row[24])
        spatial_representation_type_code = 'UNKNOWN' if row[25] == None else str(row[25])
        distance_uom = 'UNKNOWN' if row[26] == None else str(row[26])
        distance = '0' if row[27] == None else str(row[27])
        topic_category = 'UNKNOWN' if row[28] == None else str(row[28])
        time_period_begin = '1900-01-01' if row[29] == None else str(row[29])
        time_period_end = '1900-01-01' if row[30] == None else str(row[30])
        west_bound_longitude = '0' if row[31] == None else str(row[31])
        east_bound_longitude = '0' if row[32] == None else str(row[32])
        south_bound_latitude = '0' if row[33] == None else str(row[33])
        north_bound_latitude = '0' if row[34] == None else str(row[34])
        distribution_format = 'UNKNOWN' if row[35] == None else str(row[35])
        scope_code = 'UNKNOWN' if row[36] == None else str(row[36])
        lineage_statement = 'UNKNOWN' if row[37] == None else str(row[37])
        lineage_source_uuidref = 'UNKNOWN' if row[38] == None else str(row[38])
        lineage_source_title = 'UNKNOWN' if row[39] == None else str(row[39])


        # editon
        edition_xml = ''
        if edition != 'UNKNOWN':
            edition_xml = f'''
          <gmd:edition>
            <gco:CharacterString>{edition}</gco:CharacterString>
          </gmd:edition>'''


        # citation_rs_identifier
        citation_rs_identifier_xml = ''
        if citation_rs_identifier_code != 'UNKNOWN':
            citation_rs_identifier_xml = f'''
          <gmd:identifier>
           <gmd:RS_Identifier>
            <gmd:code>
             <gco:CharacterString>{citation_rs_identifier_code}</gco:CharacterString>
            </gmd:code>
            <gmd:codeSpace>
             <gco:CharacterString>{citation_rs_identifier_code_space}</gco:CharacterString>
            </gmd:codeSpace>
           </gmd:RS_Identifier>
          </gmd:identifier>'''


        # keyword_theme, must be seperated by coma
        keyword_theme_xml = ''
        # if keyword_theme != 'UNKNOWN':
        for k in keyword_theme.split(','):
            k = k.strip("[]'")
            keyword_theme_part = f'''
          <gmd:keyword>
            <gco:CharacterString>{k}</gco:CharacterString>
          </gmd:keyword>'''
            keyword_theme_xml = keyword_theme_xml + keyword_theme_part
        
        
        # keyword_stratum, must be seperated by coma
        keyword_stratum_xml = ''
        # if keyword_stratum != 'UNKNOWN':
        for k in keyword_stratum.split(','):
            k = k.strip("[]'")
            keyword_stratum_part = f'''
          <gmd:keyword>
            <gco:CharacterString>{k}</gco:CharacterString>
          </gmd:keyword>'''
            keyword_stratum_xml = keyword_stratum_xml + keyword_stratum_part
        
        
        # keyword_place, must be seperated by coma
        keyword_place_xml = ''
        # if keyword_place != 'UNKNOWN':
        for k in keyword_place.split(','):
            k = k.strip("[]'")
            keyword_place_part = f'''
          <gmd:keyword>
            <gco:CharacterString>{k}</gco:CharacterString>
          </gmd:keyword>'''
            keyword_place_xml = keyword_place_xml + keyword_place_part


        # deal with vector/grid resolution
        if spatial_representation_type_code == 'grid':
            resolution = f'''
          <gmd:distance>
            <gco:Distance uom="{distance_uom}">{distance}</gco:Distance>
          </gmd:distance>'''
        if spatial_representation_type_code == 'vector':
            resolution = f'''
          <gmd:equivalentScale>
            <gmd:MD_RepresentativeFraction>
              <gmd:denominator>
              <gco:Integer>{distance_uom}</gco:Integer>
              </gmd:denominator>
            </gmd:MD_RepresentativeFraction>
          </gmd:equivalentScale>'''
        else:
            resolution = ''

        
        # topic_category, must be seperated by coma
        topic_category_xml = ''
        # if topic_category != 'UNKNOWN':
        for k in topic_category.split(','):
            k = k.strip("[]'")
            topic_category_part = f'''
      <gmd:topicCategory>
        <gmd:MD_TopicCategoryCode>{k}</gmd:MD_TopicCategoryCode>
      </gmd:topicCategory>'''
            topic_category_xml = topic_category_xml + topic_category_part


        # contact_ci_responsible_party
        contact_ci_responsible_party_xml = ''
        sql = f'''SELECT o.organisation_id, 
                        o.url,
                        o.email,
                        o.country, 
                        o.city, 
                        o.postal_code, 
                        o.delivery_point,
                        o.phone,
                        o.facsimile,
                        i.individual_id, 
                        i.email, 
                        v.tag, 
                        v.role, 
                        v.position
                 FROM metadata.ver_x_org_x_ind v
                 LEFT JOIN metadata.organisation o ON o.organisation_id = v.organisation_id
                 LEFT JOIN metadata.individual i ON i.individual_id = v.individual_id
                 WHERE v.dataset_id = '{dataset_id}'
                   AND v.version ='{version}'
                   AND v.tag = 'contact'
                 ORDER BY i.individual_id'''
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            organisation_id = row[0]
            url = '' if row[1] == None else row[1]
            o_email = row[2]
            country = row[3]
            city = row[4]
            postal_code = row[5]
            delivery_point = '' if row[6] == None else row[6]
            phone = '' if row[7] == None else row[7]
            facsimile = '' if row[8] == None else row[8]
            individual_id = row[9]
            i_email = row[10]
            tag = row[11]
            role = row[12]
            position = row[13]
            contact_ci_responsible_party_part = f'''
  <gmd:contact>
    <gmd:CI_ResponsibleParty>
      <gmd:individualName>
        <gco:CharacterString>{individual_id}</gco:CharacterString>
      </gmd:individualName>
      <gmd:organisationName>
        <gco:CharacterString>{organisation_id}</gco:CharacterString>
      </gmd:organisationName>
      <gmd:positionName>
        <gco:CharacterString>{position}</gco:CharacterString>
      </gmd:positionName>
      <gmd:contactInfo>
        <gmd:CI_Contact>
          <gmd:phone>
            <gmd:CI_Telephone>
              <gmd:voice gco:nilReason="missing">
                <gco:CharacterString />
              </gmd:voice>
              <gmd:facsimile gco:nilReason="missing">
                <gco:CharacterString />
              </gmd:facsimile>
            </gmd:CI_Telephone>
          </gmd:phone>
          <gmd:address>
            <gmd:CI_Address>
              <gmd:deliveryPoint>
                <gco:CharacterString>{delivery_point}</gco:CharacterString>
              </gmd:deliveryPoint>
              <gmd:city>
                <gco:CharacterString>{city}</gco:CharacterString>
              </gmd:city>
              <gmd:administrativeArea gco:nilReason="missing">
                <gco:CharacterString />
              </gmd:administrativeArea>
              <gmd:postalCode>
                <gco:CharacterString>{postal_code}</gco:CharacterString>
              </gmd:postalCode>
              <gmd:country>
                <gco:CharacterString>{country}</gco:CharacterString>
              </gmd:country>
              <gmd:electronicMailAddress>
                <gco:CharacterString>{i_email}</gco:CharacterString>
              </gmd:electronicMailAddress>
            </gmd:CI_Address>
          </gmd:address>
        </gmd:CI_Contact>
      </gmd:contactInfo>
      <gmd:role>
        <gmd:CI_RoleCode codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/codelist/ML_gmxCodelists.xml#CI_RoleCode" codeListValue="{role}" />
      </gmd:role>
    </gmd:CI_ResponsibleParty>
  </gmd:contact>'''
            contact_ci_responsible_party_xml = contact_ci_responsible_party_xml + contact_ci_responsible_party_part
        
        
        # point_of_contact_ci_responsible_party
        point_of_contact_ci_responsible_party_xml = ''
        sql = f'''SELECT o.organisation_id, 
                        o.url,
                        o.email,
                        o.country, 
                        o.city, 
                        o.postal_code, 
                        o.delivery_point,
                        o.phone,
                        o.facsimile,
                        i.individual_id, 
                        i.email, 
                        v.tag, 
                        v.role, 
                        v.position
                 FROM metadata.ver_x_org_x_ind v
                 LEFT JOIN metadata.organisation o ON o.organisation_id = v.organisation_id
                 LEFT JOIN metadata.individual i ON i.individual_id = v.individual_id
                 WHERE v.dataset_id = '{dataset_id}'
                   AND v.version ='{version}'
                   AND v.tag = 'pointOfContact'
                 ORDER BY i.individual_id'''
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            organisation_id = row[0]
            url = '' if row[1] == None else row[1]
            o_email = row[2]
            country = row[3]
            city = row[4]
            postal_code = row[5]
            delivery_point = '' if row[6] == None else row[6]
            phone = '' if row[7] == None else row[7]
            facsimile = '' if row[8] == None else row[8]
            individual_id = row[9]
            i_email = row[10]
            tag = row[11]
            role = row[12]
            position = row[13]
            point_of_contact_ci_responsible_party_part = f'''
          <gmd:pointOfContact>
            <gmd:CI_ResponsibleParty>
              <gmd:individualName>
                <gco:CharacterString>{individual_id}</gco:CharacterString>
              </gmd:individualName>
              <gmd:organisationName>
                <gco:CharacterString>{organisation_id}</gco:CharacterString>
              </gmd:organisationName>
              <gmd:positionName>
                <gco:CharacterString>{position}</gco:CharacterString>
              </gmd:positionName>
              <gmd:contactInfo>
                <gmd:CI_Contact>
                  <gmd:phone>
                    <gmd:CI_Telephone>
                      <gmd:voice gco:nilReason="missing">
                        <gco:CharacterString />
                      </gmd:voice>
                      <gmd:facsimile gco:nilReason="missing">
                        <gco:CharacterString />
                      </gmd:facsimile>
                    </gmd:CI_Telephone>
                  </gmd:phone>
                  <gmd:address>
                    <gmd:CI_Address>
                      <gmd:deliveryPoint>
                        <gco:CharacterString>{delivery_point}</gco:CharacterString>
                      </gmd:deliveryPoint>
                      <gmd:city>
                        <gco:CharacterString>{city}</gco:CharacterString>
                      </gmd:city>
                      <gmd:administrativeArea gco:nilReason="missing">
                        <gco:CharacterString />
                      </gmd:administrativeArea>
                      <gmd:postalCode>
                        <gco:CharacterString>{postal_code}</gco:CharacterString>
                      </gmd:postalCode>
                      <gmd:country>
                        <gco:CharacterString>{country}</gco:CharacterString>
                      </gmd:country>
                      <gmd:electronicMailAddress>
                        <gco:CharacterString>{i_email}</gco:CharacterString>
                      </gmd:electronicMailAddress>
                    </gmd:CI_Address>
                  </gmd:address>
                </gmd:CI_Contact>
              </gmd:contactInfo>
              <gmd:role>
                <gmd:CI_RoleCode codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/codelist/ML_gmxCodelists.xml#CI_RoleCode" codeListValue="{role}" />
              </gmd:role>
            </gmd:CI_ResponsibleParty>
          </gmd:pointOfContact>'''
            point_of_contact_ci_responsible_party_xml = point_of_contact_ci_responsible_party_xml + point_of_contact_ci_responsible_party_part
        
        
        # online_resource
        online_resource = ''
        sql = f'''SELECT url, protocol, url_name
                 FROM metadata.url
                 WHERE dataset_id='{dataset_id}' 
                   AND version='{version}'
                   AND protocol IN ('OGC:WMS','OGC:WMTS','WWW:LINK-1.0-http--link', 'WWW:LINK-1.0-http--related')
                 ORDER BY protocol, url'''
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            url        = row[0]
            protocol   = row[1]
            url_name   = row[2]
            if protocol in ('OGC:WMS','OGC:WMTS'):
                function = 'information'
            if protocol in ('WWW:LINK-1.0-http--link', 'WWW:LINK-1.0-http--related'):
                function = 'download'
            else:
                function = 'UNKNOWN'
            online_resource_part = f'''
          <gmd:onLine>
            <gmd:CI_OnlineResource>
              <gmd:linkage>
                <gmd:URL>{url}</gmd:URL>
              </gmd:linkage>
              <gmd:protocol>
                <gco:CharacterString>{protocol}</gco:CharacterString>
              </gmd:protocol>
              <gmd:name>
                <gco:CharacterString>{url_name}</gco:CharacterString>
              </gmd:name>
              <gmd:description gco:nilReason="missing">
                <gco:CharacterString />
              </gmd:description>
              <gmd:function>
                <gmd:CI_OnLineFunctionCode codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/codelist/ML_gmxCodelists.xml#CI_OnLineFunctionCode" codeListValue="{function}" />
              </gmd:function>
            </gmd:CI_OnlineResource>
          </gmd:onLine>'''
            online_resource = online_resource + online_resource_part
        
        
        # fill dicionary
        replace['***file_identifier***'] = file_identifier
        replace['***language_code***'] = language_code
        replace['***contact_ci_responsible_party_xml***'] = contact_ci_responsible_party_xml
        replace['***revision_date***'] = revision_date
        replace['***metadata_standard_name***'] = metadata_standard_name
        replace['***metadata_standard_version***'] = metadata_standard_version
        replace['***reference_system_identifier_code***'] = reference_system_identifier_code
        replace['***reference_system_identifier_code_space***'] = reference_system_identifier_code_space
        replace['***title***'] = title
        replace['***creation_date***'] = creation_date
        replace['***publication_date***'] = publication_date
        replace['***edition_xml***'] = edition_xml
        replace['***citation_rs_identifier_xml***'] = citation_rs_identifier_xml
        replace['***citation_md_identifier_code***'] = citation_md_identifier_code
        replace['***abstract***'] = abstract
        replace['***status***'] = status
        replace['***point_of_contact_ci_responsible_party_xml***'] = point_of_contact_ci_responsible_party_xml
        replace['***md_browse_graphic***'] = '%s' % md_browse_graphic
        replace['***keyword_theme_xml***'] = keyword_theme_xml
        replace['***keyword_stratum_xml***'] = keyword_stratum_xml
        replace['***keyword_place_xml***'] = keyword_place_xml
        replace['***access_constraints***'] = access_constraints
        replace['***use_constraints***'] = use_constraints
        replace['***other_constraints***'] = other_constraints
        replace['***spatial_representation_type_code***'] = spatial_representation_type_code
        replace['***resolution***'] = resolution
        replace['***topic_category_xml***'] = topic_category_xml
        replace['***time_period_begin***'] = time_period_begin
        replace['***time_period_end***'] = time_period_end
        replace['***west_bound_longitude***'] = west_bound_longitude
        replace['***east_bound_longitude***'] = east_bound_longitude
        replace['***south_bound_latitude***'] = south_bound_latitude
        replace['***north_bound_latitude***'] = north_bound_latitude
        replace['***distribution_format***'] = distribution_format
        replace['***online_resource***'] = online_resource
        replace['***scope_code***'] = scope_code
        replace['***lineage_statement***'] = lineage_statement
        

        # replace string
        open_file = open(template, 'r')
        read_file = open_file.read()
        write_file = open(output+'/%s.xml' % file_identifier,'w')
        write_file.write(multireplace(read_file, replace))

        
        # close files
        open_file.close
        write_file.close


    # close database connection
    conn.commit()
    return


def dataset_version():
    what = input('''\nAll datasets (1)
Specific dataset (2)
Specific dataset & version (3):
''')
    
    print('\n')
    count = 0
    if what == '1':
        # All datasets
        sql = ''' SELECT dataset_id, version 
                  FROM metadata.version
                  ORDER BY dataset_id, version
                  --LIMIT 500
              '''
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            dataset_id = row[0]
            version   = row[1]
            count = count + 1
            print(count,'\t',dataset_id)
            
            # create xml
            bake_xml(dataset_id, version, template, output)
    
    
    if what == '2':
        # Specific dataset
        sql = ''' SELECT dataset_id
                  FROM metadata.version
                  ORDER BY dataset_id
              '''
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            dataset_id = row[0]
            print(dataset_id)
        dataset_id = input('\nDataset: ')
        sql = f''' SELECT dataset_id, version 
                  FROM metadata.version
                  WHERE dataset_id='{dataset_id}' 
                  ORDER BY dataset_id, version
              '''
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            dataset_id = row[0]
            version   = row[1]
            print(dataset_id, version)
            
            # create xml
            bake_xml(dataset_id, version, template, output)
        
    
    if what == '3':
        # Specific dataset & version
        sql = ''' SELECT dataset_id 
                  FROM metadata.dataset
                  ORDER BY dataset_id
              '''
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            dataset_id = row[0]
            print(dataset_id)
        dataset_id = input('\nDataset: ')
    
    
        # choose version
        sql = f''' SELECT version 
                  FROM metadata.version
                  WHERE dataset_id='{dataset_id}' 
                  ORDER BY version
              '''
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            version = row[0]
            print(version)
        version = input('\nVersion: ')
        
        # create xml
        bake_xml(dataset_id, version, template, output)


# variables
template='/home/carva014/Work/Code/FAO/glosis-db/Metadata/template.xml'
output='/home/carva014/Work/Code/FAO/glosis-db/Metadata/output'

# open db connection
conn = psycopg2.connect("host='localhost' port='5432' dbname='iso19139' user='glosis'")
cur = conn.cursor()

# run function
dataset_version()

# close db connection
conn.commit()
cur.close()
conn.close()