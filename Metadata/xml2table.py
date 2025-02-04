# importing
import psycopg2
import xml.etree.ElementTree as ET
from lxml import etree as ET


# very helpful: https://www.datacamp.com/tutorial/python-xml-elementtree
#               https://www.edureka.co/blog/python-xml-parser-tutorial/


def extract_data(limit):
  count = 0
  ns = {'gmd':'http://www.isotc211.org/2005/gmd',
        'gco':'http://www.isotc211.org/2005/gco',
        'gml':'http://www.opengis.net/gml/3.2',
        'myprefix':'http://www.isotc211.org/2005/myprefix'}

  # iterate records
  sql = f'SELECT data FROM geonetwork.metadata ORDER BY uuid LIMIT {limit}'
  cur.execute(sql)
  rows = cur.fetchall()
  for row in rows:
    xml = row[0]

    # parse xml
    root = ET.fromstring(xml)
    ET.register_namespace('gmd','http://www.isotc211.org/2005/gmd')
    ET.register_namespace('gml','http://www.opengis.net/gml/3.2')
    ET.register_namespace('gco','http://www.isotc211.org/2005/gco')
    ET.register_namespace('gmx','http://www.isotc211.org/2005/gmx')

    # file_identifier
    file_identifier = root.find('.//gmd:fileIdentifier/gco:CharacterString', ns).text
    if file_identifier is not None:
      sql = f"""INSERT INTO xml2table.dataset (dataset_id) VALUES ('{file_identifier}');
                INSERT INTO xml2table.version (dataset_id, version, file_identifier) VALUES ('{file_identifier}', '1', '{file_identifier}') """
      cur.execute(sql)

    # verbose
    count = count + 1
    print(count,'\t',file_identifier)

    # language_code
    for elem in root.findall('.//gmd:language/gmd:LanguageCode', ns):
      language_code = elem.attrib['codeListValue']
      if language_code is not None:
        sql = f"UPDATE xml2table.version SET language_code = '{language_code}' WHERE dataset_id = '{file_identifier}'"
        cur.execute(sql)
    
    for elem in root.findall('.//gmd:language/gco:CharacterString', ns):
      language_code = elem.text
      if language_code is not None:
        sql = f"UPDATE xml2table.version SET language_code = '{language_code}' WHERE dataset_id = '{file_identifier}' AND language_code IS NULL"
        cur.execute(sql)

    # ResponsibleParty
    contact_tag_list = ['.//gmd:contact/gmd:CI_ResponsibleParty',
                        './/gmd:contact/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty',
                        './/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty',
                        './/gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:source/gmd:LI_Source/gmd:sourceStep/gmd:LI_ProcessStep/gmd:processor/gmd:CI_ResponsibleParty']
    for t in contact_tag_list:
      tag = str({t}).split('/')[-2].split(':')[1]

      # ver_x_org_x_ind
      for elem in root.findall(t, ns):
        role             = elem.find('.//gmd:role/gmd:CI_RoleCode', ns).attrib['codeListValue'] if elem.find('.//gmd:role/gmd:CI_RoleCode', ns) is not None else 'UNKNOWN'
        position         = elem.find('.//gmd:positionName/gco:CharacterString', ns).text if elem.find('.//gmd:positionName/gco:CharacterString', ns) is not None else 'UNKNOWN'
        organisation_id  = elem.find('.//gmd:organisationName/gco:CharacterString', ns).text if elem.find('.//gmd:organisationName/gco:CharacterString', ns) is not None else 'UNKNOWN'
        individual_id    = elem.find('.//gmd:individualName/gco:CharacterString', ns).text if elem.find('.//gmd:individualName/gco:CharacterString', ns) is not None else 'UNKNOWN'
        
        sql = f"""INSERT INTO xml2table.organisation (organisation_id) 
                  SELECT '{organisation_id}'
                  WHERE  '{organisation_id}' NOT IN (SELECT organisation_id FROM xml2table.organisation)"""
        cur.execute(sql)
        sql = f"""INSERT INTO xml2table.individual (individual_id) 
                  SELECT '{individual_id}' 
                  WHERE  '{individual_id}' NOT IN (SELECT individual_id FROM xml2table.individual)"""
        cur.execute(sql)
        sql = f"""INSERT INTO xml2table.ver_x_org_x_ind (dataset_id, version, tag, role, position, organisation_id, individual_id)
                  SELECT  '{file_identifier}', '1', '{tag}', '{role}', '{position}', '{organisation_id}', '{individual_id}'
                  WHERE  ('{file_identifier}', '1', '{tag}', '{role}', '{position}', '{organisation_id}', '{individual_id}') NOT IN (SELECT dataset_id, version, tag, role, position, organisation_id, individual_id FROM xml2table.ver_x_org_x_ind)"""
        cur.execute(sql)

      # contactInfo
      for elem in root.findall(f'{t}/gmd:contactInfo/gmd:CI_Contact', ns):
        country        = elem.find('.//gmd:address/gmd:CI_Address/gmd:country/gco:CharacterString', ns).text               if elem.find('.//gmd:address/gmd:CI_Address/gmd:country/gco:CharacterString', ns)               is not None else 'UNKNOWN'
        city           = elem.find('.//gmd:address/gmd:CI_Address/gmd:city/gco:CharacterString', ns).text                  if elem.find('.//gmd:address/gmd:CI_Address/gmd:city/gco:CharacterString', ns)                  is not None else 'UNKNOWN'
        postal_code    = elem.find('.//gmd:address/gmd:CI_Address/gmd:postalCode/gco:CharacterString', ns).text            if elem.find('.//gmd:address/gmd:CI_Address/gmd:postalCode/gco:CharacterString', ns)            is not None else 'UNKNOWN'
        delivery_point = elem.find('.//gmd:address/gmd:CI_Address/gmd:deliveryPoint/gco:CharacterString', ns).text         if elem.find('.//gmd:address/gmd:CI_Address/gmd:deliveryPoint/gco:CharacterString', ns)         is not None else 'UNKNOWN'
        email          = elem.find('.//gmd:address/gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString', ns).text if elem.find('.//gmd:address/gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString', ns) is not None else 'UNKNOWN'
        phone          = elem.find('.//gmd:phone/gmd:CI_Telephone/gmd:voice/gco:CharacterString', ns).text                 if elem.find('.//gmd:phone/gmd:CI_Telephone/gmd:voice/gco:CharacterString', ns)                 is not None else 'UNKNOWN'
        facsimile      = elem.find('.//gmd:phone/gmd:CI_Telephone/gmd:facsimile/gco:CharacterString', ns).text             if elem.find('.//gmd:phone/gmd:CI_Telephone/gmd:facsimile/gco:CharacterString', ns)             is not None else 'UNKNOWN'
        url            = elem.find('.//gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL', ns).text             if elem.find('.//gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL', ns)             is not None else 'UNKNOWN'
     
        sql = f"""UPDATE xml2table.organisation SET country = '{country}' WHERE organisation_id = '{organisation_id}' AND country IS NULL"""
        cur.execute(sql)
        sql = f"""UPDATE xml2table.organisation SET city = $${city}$$ WHERE organisation_id = '{organisation_id}' AND city IS NULL"""
        cur.execute(sql)
        sql = f"""UPDATE xml2table.organisation SET postal_code = '{postal_code}' WHERE organisation_id = '{organisation_id}' AND postal_code IS NULL"""
        cur.execute(sql)
        sql = f"""UPDATE xml2table.organisation SET delivery_point = '{delivery_point}' WHERE organisation_id = '{organisation_id}' AND delivery_point IS NULL"""
        cur.execute(sql)
        sql = f"""UPDATE xml2table.organisation SET email = '{email}' WHERE organisation_id = '{organisation_id}' AND email IS NULL"""
        cur.execute(sql)
        sql = f"UPDATE xml2table.individual SET email = '{email}' WHERE individual_id = '{individual_id}' AND email IS NULL"
        cur.execute(sql)
        sql = f"""UPDATE xml2table.organisation SET phone = '{phone}' WHERE organisation_id = '{organisation_id}' AND phone IS NULL"""
        cur.execute(sql)
        sql = f"""UPDATE xml2table.organisation SET facsimile = '{facsimile}' WHERE organisation_id = '{organisation_id}' AND facsimile IS NULL"""
        cur.execute(sql)
        sql = f"""UPDATE xml2table.organisation SET url = '{url}' WHERE organisation_id = '{organisation_id}' AND url IS NULL"""
        cur.execute(sql)

    # url
    for elem in root.findall('.//gmd:onLine/gmd:CI_OnlineResource', ns):
      url = elem.find('.//gmd:linkage/gmd:URL', ns).text if elem.find('.//gmd:linkage/gmd:URL', ns) is not None else 'ERROR: no URL!'
      if elem.find('.//gmd:protocol/gco:CharacterString', ns) is not None:
        protocol = elem.find('.//gmd:protocol/gco:CharacterString', ns).text
      elif elem.find('.//gmd:protocol/gmd:CharacterString', ns) is not None: # ERROR in metadata! it should be gco:CharacterString
        protocol = elem.find('.//gmd:protocol/gmd:CharacterString', ns).text # ERROR in metadata! it should be gco:CharacterString
      else:
        protocol = 'ERROR: no protocol!'
      if elem.find('.//gmd:name/gco:CharacterString', ns) is not None:
        url_name = elem.find('.//gmd:name/gco:CharacterString', ns).text
      elif elem.find('.//gmd:name/gmd:CharacterString', ns) is not None: # ERROR in metadata! it should be gco:CharacterString
        url_name = elem.find('.//gmd:name/gmd:CharacterString', ns).text # ERROR in metadata! it should be gco:CharacterString
      else:
        url_name = 'ERROR: no name!'
      sql = f"INSERT INTO xml2table.url (dataset_id, version, url, protocol, url_name) VALUES ('{file_identifier}', '1', '{url}', '{protocol}', '{url_name}')"
      cur.execute(sql)

    # metadata_standard_name
    for elem in root.findall('.//gmd:metadataStandardName/gco:CharacterString', ns):
      metadata_standard_name = elem.text
      if metadata_standard_name is not None:
        sql = f"UPDATE xml2table.version SET metadata_standard_name = '{metadata_standard_name}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # metadata_standard_version
    for elem in root.findall('.//gmd:metadataStandardVersion/gco:CharacterString', ns):
      metadata_standard_version = elem.text
      if metadata_standard_version is not None:
        sql = f"UPDATE xml2table.version SET metadata_standard_version = '{metadata_standard_version}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # reference_system_identifier_code
    for elem in root.findall('.//gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:code/gco:CharacterString', ns):
      reference_system_identifier_code = elem.text
      if reference_system_identifier_code is not None:
        sql = f"UPDATE xml2table.version SET reference_system_identifier_code = '{reference_system_identifier_code}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # reference_system_identifier_code_space
    for elem in root.findall('.//gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:codeSpace/gco:CharacterString', ns):
      reference_system_identifier_code_space = elem.text
      if reference_system_identifier_code_space is not None:
        sql = f"UPDATE xml2table.version SET reference_system_identifier_code_space = '{reference_system_identifier_code_space}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # title
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString', ns):
      title = elem.text
      if title is not None:
        sql = f"""UPDATE xml2table.dataset SET dataset_name = $${title}$$ WHERE dataset_id = '{file_identifier}';
                  UPDATE xml2table.version SET title = $${title}$$ WHERE file_identifier = '{file_identifier}' """
        cur.execute(sql)

    # creation_date, publication_date, revision_date
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date', ns):
      the_date  = elem.find('.//gmd:date/gco:Date', ns).text
      what_date = elem.find('.//gmd:dateType/gmd:CI_DateTypeCode', ns).attrib['codeListValue']
      # if the_date is not None and the_date not in ['None', 'Invalid Date', 'NaN', '2015']:
      if the_date is not None:
        if what_date == 'creation':
          sql = f"UPDATE xml2table.version SET creation_date = '{the_date}' WHERE file_identifier = '{file_identifier}'"
          cur.execute(sql)
        if what_date == 'publication':
          sql = f"UPDATE xml2table.version SET publication_date = '{the_date}' WHERE file_identifier = '{file_identifier}'"
          cur.execute(sql)
        if what_date == 'revision':
          sql = f"UPDATE xml2table.version SET revision_date = '{the_date}' WHERE file_identifier = '{file_identifier}'"
          cur.execute(sql)

    # edition
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:edition/gco:CharacterString', ns):
      edition = elem.text
      if edition is not None:
        sql = f"UPDATE xml2table.version SET edition = '{edition}' WHERE dataset_id = '{file_identifier}' "
        cur.execute(sql)

    # citation_rs_identifier_code
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:identifier/gmd:RS_Identifier/gmd:code/gco:CharacterString', ns):
      citation_rs_identifier_code = elem.text
      if citation_rs_identifier_code is not None:
        sql = f"UPDATE xml2table.version SET citation_rs_identifier_code = '{citation_rs_identifier_code}' WHERE dataset_id = '{file_identifier}'"
        cur.execute(sql)

    # citation_rs_identifier_code_space
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:identifier/gmd:RS_Identifier/gmd:codeSpace/gco:CharacterString', ns):
      citation_rs_identifier_code_space = elem.text
      if citation_rs_identifier_code_space is not None:
        sql = f"UPDATE xml2table.version SET citation_rs_identifier_code_space = '{citation_rs_identifier_code_space}' WHERE dataset_id = '{file_identifier}'"
        cur.execute(sql)

    # citation_md_identifier_code
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:identifier/gmd:MD_Identifier/gmd:code/gco:CharacterString', ns):
      citation_md_identifier_code = elem.text
      if citation_md_identifier_code is not None:
        sql = f"UPDATE xml2table.version SET citation_md_identifier_code = '{citation_md_identifier_code}' WHERE dataset_id = '{file_identifier}'"
        cur.execute(sql)

    # abstract
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract/gco:CharacterString', ns):
      abstract = elem.text
      if abstract is not None:
        sql = f"UPDATE xml2table.version SET abstract = $${abstract}$$ WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # status
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:status/gmd:MD_ProgressCode', ns):
      status = elem.attrib['codeListValue']
      if status is not None:
        sql = f"UPDATE xml2table.version SET status = '{status}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # md_browse_graphic
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:graphicOverview/gmd:MD_BrowseGraphic/gmd:fileName/gco:CharacterString', ns):
      md_browse_graphic = elem.text
      if md_browse_graphic is not None:
        sql = f"UPDATE xml2table.version SET md_browse_graphic = '{md_browse_graphic}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # keywords
    keyword_theme = []
    keyword_stratum = []
    keyword_place = []
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords', ns):
      try:
        keyword = elem.find('.//gmd:keyword/gco:CharacterString', ns).text
      except:
        continue
      try:
        Keyword_type = elem.find('.//gmd:type/gmd:MD_KeywordTypeCode', ns).attrib['codeListValue']
      except:
        Keyword_type = 'theme'
      if keyword is not None:
        keyword = keyword.replace("'","")
        keyword = keyword.replace(",","")
        if Keyword_type == 'theme':
          keyword_theme.append(keyword)
        if Keyword_type == 'stratum':
          keyword_stratum.append(keyword)
        if Keyword_type == 'place':
          keyword_place.append(keyword)

      if len(keyword_theme) > 0:
        keywords_string = ', '.join(map(str, keyword_theme))
        keywords_string = '{'+keywords_string+'}'
        sql = f"UPDATE xml2table.version SET keyword_theme = '{keywords_string}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)
      if len(keyword_stratum) > 0:
        keywords_string = ', '.join(map(str, keyword_stratum))
        keywords_string = '{'+keywords_string+'}'
        sql = f"UPDATE xml2table.version SET keyword_stratum = '{keywords_string}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)
      if len(keyword_place) > 0:
        keywords_string = ', '.join(map(str, keyword_place))
        keywords_string = '{'+keywords_string+'}'
        sql = f"UPDATE xml2table.version SET keyword_place = '{keywords_string}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # access_constraints
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:accessConstraints/gmd:MD_RestrictionCode', ns):
      access_constraints = elem.attrib['codeListValue']
      if access_constraints is not None:
        sql = f"UPDATE xml2table.version SET access_constraints = '{access_constraints}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # use_constraints
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:useConstraints/gmd:MD_RestrictionCode', ns):
      use_constraints = elem.attrib['codeListValue']
      if use_constraints is not None:
        sql = f"UPDATE xml2table.version SET use_constraints = '{use_constraints}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # other_constraints
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints/gco:CharacterString', ns):
      other_constraints = elem.text
      if other_constraints is not None:
        sql = f"UPDATE xml2table.version SET other_constraints = $${other_constraints}$$ WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # spatial_representation_type_code
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode', ns):
      spatial_representation_type_code = elem.attrib['codeListValue']
      if spatial_representation_type_code is not None:
        sql = f"UPDATE xml2table.version SET spatial_representation_type_code = $${spatial_representation_type_code}$$ WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # distance_uom
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialResolution/gmd:MD_Resolution/gmd:distance/gco:Distance', ns):
      distance_uom = elem.attrib['uom']
      if distance_uom is not None:
        sql = f"UPDATE xml2table.version SET distance_uom = $${distance_uom}$$ WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # distance
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialResolution/gmd:MD_Resolution/gmd:distance/gco:Distance', ns):
      distance = elem.text
      if distance is not None:
        sql = f"UPDATE xml2table.version SET distance = $${distance}$$ WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # topic_category
    topic_category_list = []
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode', ns):
      topic_category = elem.text
      if topic_category is not None:
        topic_category_list.append(topic_category)

      if len(topic_category_list) > 0:
        topic_category_string = ', '.join(map(str, topic_category_list))
        topic_category_string = '{'+topic_category_string+'}'
        sql = f"UPDATE xml2table.version SET topic_category = '{topic_category_string}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # time_period_begin
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition', ns):
      time_period_begin = elem.text
      if time_period_begin is not None and time_period_begin not in ['None']:
        sql = f"UPDATE xml2table.version SET time_period_begin = '{time_period_begin}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # time_period_end
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition', ns):
      time_period_end = elem.text
      if time_period_end is not None and time_period_end not in ['None']:
        sql = f"UPDATE xml2table.version SET time_period_end = '{time_period_end}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # west_bound_longitude
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal', ns):
      west_bound_longitude = elem.text
      if west_bound_longitude is not None:
        sql = f"UPDATE xml2table.version SET west_bound_longitude = '{west_bound_longitude}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # east_bound_longitude
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal', ns):
      east_bound_longitude = elem.text
      if east_bound_longitude is not None:
        sql = f"UPDATE xml2table.version SET east_bound_longitude = '{east_bound_longitude}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # south_bound_latitude
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal', ns):
      south_bound_latitude = elem.text
      if south_bound_latitude is not None:
        sql = f"UPDATE xml2table.version SET south_bound_latitude = '{south_bound_latitude}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # north_bound_latitude
    for elem in root.findall('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal', ns):
      north_bound_latitude = elem.text
      if north_bound_latitude is not None:
        sql = f"UPDATE xml2table.version SET north_bound_latitude = '{north_bound_latitude}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # distribution_format
    for elem in root.findall('.//gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name/gco:CharacterString', ns):
      distribution_format = elem.text
      if distribution_format is not None:
        sql = f"UPDATE xml2table.version SET distribution_format = '{distribution_format}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # scope_code
    for elem in root.findall('.//gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:scope/gmd:DQ_Scope/gmd:level/gmd:MD_ScopeCode', ns):
      scope_code = elem.attrib['codeListValue']
      if scope_code is not None:
        sql = f"UPDATE xml2table.version SET scope_code = '{scope_code}' WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # not parsed in data quality due to be unused
    # xxxx = root.find('.//gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:report/gmd:DQ_DomainConsistency/gmd:result/gmd:DQ_ConformanceResult/gmd:specification/gmd:CI_Citation/gmd:title/gco:CharacterString', ns).text
    # xxxx = root.find('.//gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:report/gmd:DQ_DomainConsistency/gmd:result/gmd:DQ_ConformanceResult/gmd:specification/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date', ns).text
    # xxxx = root.find('.//gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:report/gmd:DQ_DomainConsistency/gmd:result/gmd:DQ_ConformanceResult/gmd:specification/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode', ns).attrib['codeListValue']
    # xxxx = root.find('.//gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:report/gmd:DQ_DomainConsistency/gmd:result/gmd:DQ_ConformanceResult/gmd:explanation/gco:CharacterString', ns).text

    # lineage_statement
    for elem in root.findall('.//gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:statement/gco:CharacterString', ns):
      lineage_statement = elem.text
      if lineage_statement is not None:
        sql = f"UPDATE xml2table.version SET lineage_statement = $${lineage_statement}$$ WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # lineage_source_uuidref
    for elem in root.findall('.//gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:source/gco:CharacterString', ns):
      lineage_source_uuidref = elem.attrib['uuidref']
      if lineage_source_uuidref is not None:
        sql = f"UPDATE xml2table.version SET lineage_source_uuidref = $${lineage_source_uuidref}$$ WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

    # lineage_source_title
    for elem in root.findall('.//gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:source/gco:CharacterString', ns):
      lineage_source_title = elem.attrib['title']
      if lineage_source_title is not None:
        sql = f"UPDATE xml2table.version SET lineage_source_title = $${lineage_source_title}$$ WHERE file_identifier = '{file_identifier}'"
        cur.execute(sql)

  print('Finished')


# open db connection
conn = psycopg2.connect("host='localhost' port='5432' dbname='iso19139' user='glosis'")
cur = conn.cursor()

# reset db schema
sql_file = open('/home/carva014/Work/Code/FAO/glosis-db/Metadata/db_model.sql','r')
cur.execute(sql_file.read())

# empty tables
# sql_file = open('/home/carva014/Work/Code/FAO/glosis-db/Metadata/db_truncate.sql','r')
# cur.execute(sql_file.read())

# run function
extract_data(10000)

# close db connection
conn.commit()
cur.close()
conn.close()
