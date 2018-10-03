require 'odm'

class Form < IsoManaged
  
  attr_accessor :children, :completion, :note
  
  # Constants
  C_SCHEMA_PREFIX = "bf"
  C_INSTANCE_PREFIX = "mdrForms"
  C_CLASS_NAME = "Form"
  C_CID_PREFIX = "F"
  C_SCHEMA_NS = UriManagement.getNs(C_SCHEMA_PREFIX)
  C_INSTANCE_NS = UriManagement.getNs(C_INSTANCE_PREFIX)
  C_RDF_TYPE = "Form"
  C_RDF_TYPE_URI = UriV2.new({:namespace => C_SCHEMA_NS, :id => C_RDF_TYPE})

  #TODO: This should be a query from the domains
  @@domain_map = {
    "AD" => "Analysis Dataset",
    "AE" => "Adverse Events",
    "AG" => "Procedure Agents",
    "AU" => "Autopsy",
    "AX" => "Non-Compliant ADaM Datasets",
    "BE" => "Biospecimen Events",
    "BM" => "Bone Measurements",
    "BR" => "Biopsy",
    "BS" => "Biospecimen",
    "CE" => "Clinical Events",
    "CM" => "Concomitant Meds",
    "CO" => "Comments",
    "CV" => "Cardiovascular System Findings",
    "DA" => "Drug Accountability",
    "DD" => "Death Diagnosis",
    "DE" => "Device Events",
    "DI" => "Device Identifiers",
    "DM" => "Demographics",
    "DO" => "Device Properties",
    "DP" => "Developmental Milestone",
    "DR" => "Device to Subject Relationship",
    "DS" => "Disposition",
    "DT" => "Device Tracking and Disposition",
    "DU" => "Device-In-Use",
    "DV" => "Protocol Deviations",
    "DX" => "Device Exposure",
    "ED" => "Endocrine System Findings",
    "EG" => "Electrocardiogram",
    "EX" => "Exposure",
    "FA" => "Findings About Events or Interventions",
    "FH" => "Family History",
    "FT" => "Functional Tests",
    "GI" => "Gastrointestinal System Findings",
    "HM" => "Hematopoietic System Findings",
    "HO" => "Healthcare Encounters",
    "HU" => "Healthcare Resource Utilization",
    "IE" => "Inclusion/Exclusion",
    "IG" => "Integumentary System Findings",
    "IM" => "Immune System Findings",
    "IS" => "Immunogenicity Specimen Assessments",
    "LB" => "Laboratory Data",
    "MB" => "Microbiology",
    "MH" => "Medical History",
    "MI" => "Microscopic Findings",
    "MK" => "Musculoskeletal Findings, Connective and Soft Tissue Findings",
    "ML" => "Meal Data",
    "MO" => "Morphology Findings",
    "MS" => "Microbiology Susceptibility",
    "NV" => "Nervous System Findings",
    "PB" => "Pharmacogenomics Biomarker",
    "PC" => "Pharmacokinetic Concentration",
    "PE" => "Physical Exam",
    "PF" => "Pharmacogenomics Findings",
    "PG" => "Pharmacogenomics/Genetics Methods and Supporting Information",
    "PP" => "Pharmacokinetic Parameters",
    "PR" => "Procedure",
    "PS" => "Protocol Summary for PGx",
    "PT" => "Pharmacogenomics Trial Characteristics",
    "QS" => "Questionnaires",
    "RE" => "Respiratory System Findings",
    "RP" => "Reproductive System Findings",
    "RS" => "Disease Response",
    "SB" => "Subject Biomarker",
    "SC" => "Subject Characteristics",
    "SE" => "Subject Element",
    "SG" => "Surgery",
    "SK" => "Skin Test",
    "SL" => "Sleep Polysomnography Data",
    "SR" => "Skin Response",
    "SU" => "Substance Use",
    "SV" => "Subject Visits",
    "TA" => "Trial Arms",
    "TE" => "Trial Elements",
    "TF" => "Tumor Findings",
    "TI" => "Trial Inclusion/Exclusion Criteria",
    "TP" => "Trial Paths",
    "TR" => "Tumor Results",
    "TS" => "Trial Summary",
    "TU" => "Tumor Identifier",
    "TV" => "Trial Visits",
    "TX" => "Trial Sets",
    "UR" => "Urinary System Findings",
    "VR" => "Viral Resistance Findings",
    "VS" => "Vital Signs" }

  # Initialize the object
  #
  # @param triples [hash] The raw triples keyed by id
  # @param id [string] The id of the form
  # @return [object] The form object
  def initialize(triples=nil, id=nil)
    self.children = Array.new
    self.label = "New Form"
    self.completion = ""
    self.note = ""
    if triples.nil?
      super
      self.rdf_type = "#{UriV2.new({:namespace => C_SCHEMA_NS, :id => C_RDF_TYPE})}"
    else
      super(triples, id)
    end
  end

  # Find a given form
  #
  # @param id [string] The id of the form.
  # @param namespace [hash] The raw triples keyed by id.
  # @param children [boolean] Find all child objects. Defaults to true.
  # @return [object] The form object.
  def self.find(id, namespace, children=true)
    object = super(id, namespace)
    if children
      object.children = Form::Group::Normal.find_for_parent(object.triples, object.get_links("bf", "hasGroup"))
    end
    object.triples = ""
    return object     
  end

  # Find all managed items based on their type.
  #
  # @return [array] Array of objects found.
  def self.all
    return IsoManaged.all_by_type(C_RDF_TYPE, C_SCHEMA_NS)
  end

  # Find list of managed items of a given type.
  #
  # @return [array] Array of objects found.
  def self.unique
    return super(C_RDF_TYPE, C_SCHEMA_NS)
  end

  # Find all released item for all identifiers of a given type.
  #
  # @return [array] An array of objects.
  def self.list
    return super(C_RDF_TYPE, C_SCHEMA_NS)
  end

  # Find history for a given identifier
  # Return the object as JSON
  #
  # @params [hash] {:identifier, :scope_id}
  # @return [array] An array of objects.
  def self.history(params)
    return super(C_RDF_TYPE, C_SCHEMA_NS, params)
  end

  # Create a placeholder form
  #
  # @param params [hash] {identifier:, :label, :freeText} The operational hash
  # @return [oject] The form object. Valid if no errors set.
  def self.create_placeholder(params)
    object = self.new 
    object.scopedIdentifier.identifier = params[:identifier]
    object.label = params[:label]
    group = Form::Group::Normal.new
    group.label = "Placeholder Group"
    group.ordinal = 1
    item = Form::Item::Placeholder.new
    item.label = "Placeholder"
    item.free_text = params[:freeText]
    item.ordinal = 1
    object.children << group
    group.children << item
    object = Form.create(object.to_operation)
    return object
  end
  
  # Create Simple
  #
  # @param params
  def self.create_simple(params)
    object = self.new 
    object.scopedIdentifier.identifier = params[:identifier]
    object.label = params[:label]
    object = Form.create(object.to_operation)
    return object
  end

  # Create a form
  #
  # @param params [hash] {data:} The operational hash
  # @return [oject] The form object. Valid if no errors set.
  def self.create(params)
    operation = params[:operation]
    managed_item = params[:managed_item]
    object = Form.from_json(managed_item)
    object.from_operation(operation, C_CID_PREFIX, C_INSTANCE_NS, IsoRegistrationAuthority.owner)
    if object.valid? then
      if object.create_permitted?
        sparql = object.to_sparql_v2
        response = CRUD.update(sparql.to_s)
        if !response.success?
          ConsoleLogger.info(C_CLASS_NAME, "create", "Failed to create object.")
          raise Exceptions::CreateError.new(message: "Failed to create " + C_CLASS_NAME + " object.")
        end
      end
    end
    return object
  end

  # Update a form
  #
  # @param params [Hash] The operational hash
  # @return [Object] The form object. Valid if no errors set.
  def self.update(params)
    operation = params[:operation]
    managed_item = params[:managed_item]
    existing_form = Form.find(managed_item[:id], managed_item[:namespace])
    object = Form.from_json(managed_item)
    object.from_operation(operation, C_CID_PREFIX, C_INSTANCE_NS, IsoRegistrationAuthority.owner)
    if object.valid? then
      #if object.create_permitted?
        sparql = object.to_sparql_v2
        existing_form.destroy # Destroys the old entry before the creation of the new item
        response = CRUD.update(sparql.to_s)
        if !response.success?
          ConsoleLogger.info(C_CLASS_NAME, "update", "Failed to update object.")
          raise Exceptions::UpdateError.new(message: "Failed to update " + C_CLASS_NAME + " object.")
        end
      #end
    end
    return object
  end

  # Destroy a form
  #
  # @raise [ExceptionClass] DestroyError if object not destroyed
  # @return [Null] No return
  def destroy
    super
  end

  # To JSON
  #
  # @return [hash] The object hash 
  def to_json
    json = super
    json[:completion] = self.completion
    json[:note] = self.note
    json[:children] = Array.new
    self.children.sort_by! {|u| u.ordinal}
    self.children.each do |child|
      json[:children] << child.to_json
    end
    return json
  end

  # To SPARQL
  #
  # @return [object] The SPARQL object created.
  def to_sparql_v2
    sparql = SparqlUpdateV2.new
    uri = super(sparql, C_SCHEMA_PREFIX)
    subject = {:uri => uri}
    sparql.triple(subject, {:prefix => C_SCHEMA_PREFIX, :id => "completion"}, {:literal => "#{self.completion}", :primitive_type => "string"})
    sparql.triple(subject, {:prefix => C_SCHEMA_PREFIX, :id => "note"}, {:literal => "#{self.note}", :primitive_type => "string"})
    self.children.sort_by! {|u| u.ordinal}
    self.children.each do |child|
      ref_uri = child.to_sparql_v2(uri, sparql)
      sparql.triple(subject, {:prefix => C_SCHEMA_PREFIX, :id => "hasGroup"}, {:uri => ref_uri})
    end
    return sparql
  end

  # To XML (ODM)
  #
  # @return [object] The ODM XML object created.
  def to_xml
    odm_document = Odm.new("ODM-#{self.id}", "Assero", "Glandon", Version::VERSION)
    odm = odm_document.root
    study = odm.add_study("S-#{self.id}")
    global_variables = study.add_global_variables()
    global_variables.add_study_name("Form Export #{self.label} (#{self.identifier})")
    global_variables.add_study_description("Not applicable. Single form export.")
    global_variables.add_protocol_name("Not applicable. Single form export.")
    metadata_version = study.add_metadata_version("MDV-#{self.id}", "Metadata for #{self.label}", "Not applicable. Single form export.")
    protocol = metadata_version.add_protocol()
    protocol.add_study_event_ref("SE-#{self.id}", "1", "Yes", "")
    study_event_def = metadata_version.add_study_event_def("SE-#{self.id}", "Not applicable. Single form export.", "No", "Scheduled", "")    
    study_event_def.add_form_ref("#{self.id}", "1", "Yes", "")
    form_def = metadata_version.add_form_def("#{self.id}", "#{self.label}", "No")
    self.children.sort_by! {|u| u.ordinal}
    self.children.each do |child|
      child.to_xml(metadata_version, form_def)
    end
    return odm_document.to_xml
  end

  # From JSON
  #
  # @param json [hash] The hash of values for the object 
  # @return [object] The object
  def self.from_json(json)
    object = super(json)
    object.completion = json[:completion]
    object.note = json[:note]
    if !json[:children].blank?
      json[:children].each do |child|
        object.children << Form::Group::Normal.from_json(child)
      end
    end
    return object
  end

  # Check Valid
  #
  # @return [boolean] Returns true if valid, false otherwise.
  def valid?
    self.errors.clear
    result = super
    self.children.each do |child|
      if !child.valid?
        self.copy_errors(child, "Group, ordinal=#{child.ordinal}, error:")
        result = false
      end
    end
    result = result &&
      FieldValidation::valid_markdown?(:completion, self.completion, self) &&
      FieldValidation::valid_markdown?(:note, self.note, self)
    return result
  end

  # Get annotations for the form
  #
  # @return [Hash] Hash containing te annotations
  def annotations
    form = self.to_json
    annotations = Array.new
    annotations += bc_annotations
    annotations += question_annotations
    return annotations
  end

private

  def bc_annotations()
    results = Array.new
    #query = UriManagement.buildNs(self.namespace, ["bf", "bo", "cbc", "bd", "isoI", "iso25964"])  +
    #  "SELECT ?item ?domain ?sdtmVarName ?sdtmTopicName ?sdtmTopicSub WHERE \n" +
    #  "{ \n " +
    #  "  ?topic_var bd:hasProperty ?op_ref3 . \n " +
    #  "  ?op_ref3 bo:hasProperty ?bc_topic_property . \n " +     
    #  "  ?bcRoot (cbc:hasProperty|cbc:hasDatatype|cbc:hasItem|cbc:hasComplexDatatype)%2B ?bc_topic_property . \n " +
    #  "  ?bc_topic_property cbc:hasThesaurusConcept ?valueRef . \n " +
    #  "  ?valueRef bo:hasThesaurusConcept ?sdtmTopicValueObj . \n " +     
    #  "  ?sdtmTopicValueObj iso25964:notation ?sdtmTopicSub . \n " +     
    #  "  {\n " +
    #  "    SELECT ?form ?group ?item ?bcProperty ?bcRoot ?bcIdent ?sdtmVarName ?domain ?sdtmTopicName ?topic_var WHERE \n " +
    #  "    { \n " + 
    #  "      ?var bd:name ?sdtmVarName . \n " +              
    #  "      ?dataset bd:includesColumn ?var . \n " +              
    #  "      ?dataset bd:prefix ?domain . \n " +              
    #  "      ?dataset bd:includesColumn ?topic_var . \n " +              
    #  "      ?topic_var bd:classifiedAs ?classification . \n " +              
    #  "      ?classification rdfs:label \"Topic\"^^xsd:string . \n " +              
    #  "      ?topic_var bd:name ?sdtmTopicName . \n " +              
    #  "      { \n " +
    #  "        SELECT ?group ?item ?bcProperty ?bcRoot ?bcIdent ?sdtmVarName ?dataset ?var ?gord ?pord WHERE \n " + 
    #  "        { \n " +    
    #  "          :" + self.id + " (bf:hasGroup|bf:hasSubGroup|bf:hasCommon)%2B ?group . \n " +     
    #  "          ?group bf:ordinal ?gord . \n " +      
    #  "          ?group (bf:hasItem|bf:hasCommonItem)%2B ?item . \n " +        
    #  "          ?item bf:hasProperty ?op_ref1 . \n " +
    #  "          ?op_ref1 bo:hasProperty ?bcProperty  . \n " +             
    #  "          ?op_ref2 bo:hasProperty ?bcProperty . \n " +
    #  "          ?var bd:hasProperty ?op_ref2 . \n " +
    #  "          ?bcRoot (cbc:hasProperty|cbc:hasDatatype|cbc:hasItem|cbc:hasComplexDatatype)%2B ?bcProperty . \n" +
    #  "          ?bcRoot rdf:type cbc:BiomedicalConceptInstance . \n " +
    #  "          ?bcProperty cbc:ordinal ?pord . \n " +     
    #  "          ?bcRoot isoI:hasIdentifier ?si . \n " +     
    #  "          ?si isoI:identifier ?bcIdent . \n " +     
    #  "        }  \n " + 
    #  "      } \n " +
    #  "    } \n " +
    #  "  } \n " +
    #  "} ORDER BY ?gord ?pord \n " 

    # New faster query
    query = %Q(
    	#{query = UriManagement.buildNs(self.namespace, ["bf", "bo", "cbc", "bd", "isoI", "iso25964"])} 
    	SELECT ?item ?domain ?sdtmVarName ?sdtmTopicName ?sdtmTopicSub WHERE 
    	{ 
	      :#{self.id} (bf:hasGroup|bf:hasSubGroup|bf:hasCommon)%2B ?group .     
        ?group bf:ordinal ?gord .      
        ?group (bf:hasItem|bf:hasCommonItem)%2B ?item .        
        ?item bf:hasProperty ?op_ref1 .
        ?op_ref1 bo:hasProperty ?bcProperty  .             
        ?op_ref2 bo:hasProperty ?bcProperty .
        ?var bd:hasProperty ?op_ref2 .
        ?bcRoot (cbc:hasProperty|cbc:hasDatatype|cbc:hasItem|cbc:hasComplexDatatype)%2B ?bcProperty .
        ?bcRoot rdf:type cbc:BiomedicalConceptInstance .
        ?bcProperty cbc:ordinal ?pord .     
        ?bcRoot isoI:hasIdentifier ?si .     
        ?si isoI:identifier ?bcIdent .     
        ?var bd:name ?sdtmVarName .              
        ?dataset bd:includesColumn ?var .              
        ?dataset bd:prefix ?domain .              
        ?dataset bd:includesColumn ?topic_var .              
        ?topic_var bd:classifiedAs ?classification .              
        ?classification rdfs:label "Topic"^^xsd:string .              
        ?topic_var bd:name ?sdtmTopicName .              
      	?topic_var bd:hasProperty ?op_ref3 .
      	?op_ref3 bo:hasProperty ?bc_topic_property .     
      	?bcRoot (cbc:hasProperty|cbc:hasDatatype|cbc:hasItem|cbc:hasComplexDatatype)%2B ?bc_topic_property .
      	?bc_topic_property cbc:hasThesaurusConcept ?valueRef .
      	?valueRef bo:hasThesaurusConcept ?sdtmTopicValueObj .     
      	?sdtmTopicValueObj iso25964:notation ?sdtmTopicSub .     
    	} ORDER BY ?gord ?pord
    )
    response = CRUD.query(query)
    xmlDoc = Nokogiri::XML(response.body)
    xmlDoc.remove_namespaces!
    xmlDoc.xpath("//result").each do |node|
      item = ModelUtility.getValue('item', true, node)
      domain = ModelUtility.getValue('domain', false, node)
      sdtm_var = ModelUtility.getValue('sdtmVarName', false, node)
      sdtm_topic = ModelUtility.getValue('sdtmTopicName', false, node)
      sdtm_topic_value = ModelUtility.getValue('sdtmTopicSub', false, node)
      domain_long_name = ""
      if item != ""
        if @@domain_map.has_key?(domain)
          domain_long_name = @@domain_map[domain]
        end
        results << {
          :id => ModelUtility.extractCid(item), :namespace => ModelUtility.extractNs(item), 
          :domain_prefix => domain, :domain_long_name => domain_long_name, :sdtm_variable => sdtm_var, :sdtm_topic_variable => sdtm_topic, :sdtm_topic_value => sdtm_topic_value
        }
      end
    end
    return results
  end

  def question_annotations()
    results = Array.new
    query = UriManagement.buildNs(self.namespace, ["bf", "bo", "bd", "isoI", "iso25964"])  +
      "SELECT DISTINCT ?var ?domain ?item WHERE \n" +       
      "{ \n" +         
      "  ?col bd:name ?var .  \n" +        
      "  ?dataset bd:includesColumn ?col . \n" +         
      "  ?dataset bd:prefix ?domain . \n " +              
      #"  ?dataset rdfs:label ?domain . \n" +         
      "  { \n" +           
      "    SELECT ?group ?item ?var ?gord ?pord WHERE \n" +           
      "    { \n" +             
      "      :" + self.id + " (bf:hasGroup|bf:hasSubGroup)%2B ?group . \n" +
      "      ?group bf:ordinal ?gord . \n" +   
      "      ?group (bf:hasItem)+ ?item . \n" +             
      "      ?item bf:mapping ?var . \n" +  
      "      ?item bf:ordinal ?pord \n" + 
      "    } \n" +          
      "  } \n" +       
      "} ORDER BY ?gord ?pord \n"   
    # Send the request, wait the resonse
    response = CRUD.query(query)
    # Process the response
    xmlDoc = Nokogiri::XML(response.body)
    xmlDoc.remove_namespaces!
    xmlDoc.xpath("//result").each do |node|
      ConsoleLogger::log(C_CLASS_NAME,"question_annotations", "node=" + node.to_json.to_s)
      item = ModelUtility.getValue('item', true, node)
      variable = ModelUtility.getValue('var', false, node)
      domain = ModelUtility.getValue('domain', false, node)
      domain_long_name = ""
      if item != ""
        if @@domain_map.has_key?(domain)
          domain_long_name = @@domain_map[domain]
        end
        results << {
          :id => ModelUtility.extractCid(item), :namespace => ModelUtility.extractNs(item), 
          :domain_prefix => domain, :domain_long_name => domain_long_name, :sdtm_variable => variable, :sdtm_topic_variable => "", :sdtm_topic_value => ""
        }
      end
    end
    return results
  end

end
