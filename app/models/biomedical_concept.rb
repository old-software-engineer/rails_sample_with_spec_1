require "uri"

class BiomedicalConcept < BiomedicalConceptCore
  
  attr_accessor :template_ref
  
  # Constants
  C_CLASS_NAME = "BiomedicalConcept"
  C_INSTANCE_PREFIX = "mdrBcs"
  C_CID_PREFIX = "BC"
  C_RDF_TYPE = "BiomedicalConceptInstance"
  C_SCHEMA_NS = UriManagement.getNs(C_SCHEMA_PREFIX)
  C_INSTANCE_NS = UriManagement.getNs(C_INSTANCE_PREFIX)
  C_RDF_TYPE_URI = UriV2.new({:namespace => C_SCHEMA_NS, :id => C_RDF_TYPE})

  # Initialize
  #
  # @param triples [hash] The raw triples keyed by subject
  # @param id [string] The identifier for the concept being built from the triples
  # @return [object] The new object
  def initialize(triples=nil, id=nil)
    self.template_ref = OperationalReferenceV2.new
    if triples.nil?
      super
      self.rdf_type = "#{C_RDF_TYPE_URI}"
    else
      super(triples, id)
    end
  end

  # Find the object
  #
  # @param id [string] The id of the item to be found
  # @param ns [string] The namespace of the item to be found
  # @param children [boolean] Find children object, defaults to true.
  # @return [object] The new object
  def self.find(id, ns, children=true)
    object = super(id, ns, children)
    if children
      links = object.get_links_v2(C_SCHEMA_PREFIX, "basedOnTemplate")
      object.template_ref = OperationalReferenceV2.find_from_triples(object.triples, links[0].id) if links.length > 0
    end
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

  # Find history for a given identifier. Return the object as JSON
  #
  # @params [Hash] {:identifier, :scope_id}
  # @option param [String] :identifier the identifier for the item 
  # @option param [String] :scope_id the id of the scope in which identifier is valid
  # @return [array] An array of objects found
  def self.history(params)
    return super(C_RDF_TYPE, C_SCHEMA_NS, params)
  end

  # Create a new object based on a template
  #
  # @param params [Hash] the parameter options
  # @option param [String] :bct_id The BCT id
  # @option param [String] :bct_namespace The BCT namespace
  # @raise [CreateError] if an error is raised when the object is being created
  # @return [Object] the BC created that includes errors if the create fails
  def self.create_simple(params)
  	if !params[:bct_id].blank? && !params[:bct_namespace].blank?
	    object = BiomedicalConceptTemplate.find(params[:bct_id], params[:bct_namespace])
	    ref = OperationalReferenceV2.new
	    ref.subject_ref = object.uri
	    operational_hash = object.to_clone
	    managed_item = operational_hash[:managed_item]
	    managed_item[:scoped_identifier][:identifier] = params[:identifier]
	    managed_item[:label] = params[:label]
	    managed_item[:template_ref] = ref.to_json
	    managed_item[:type] = "#{C_RDF_TYPE_URI}"
	    new_object = BiomedicalConcept.create(operational_hash)
	    return new_object
  	else
  		new_object = BiomedicalConcept.new
  		new_object.errors.add(:base, "No Biomedical Concept Template has been defined.")
    	return new_object
    end
  end

  # Create a new object based on another
  #
  # @param params [Hash]
  # @raise [CreateError] If object not created.
  # @return [Object] The BC created. Includes errors if failed.
  def self.create_clone(params)
    base_bc = BiomedicalConcept.find(params[:bc_id], params[:bc_namespace])
    operational_hash = base_bc.to_clone
    managed_item = operational_hash[:managed_item]
    managed_item[:scoped_identifier][:identifier] = params[:identifier]
    managed_item[:label] = params[:label]
    new_object = BiomedicalConcept.create(operational_hash)
    return new_object
  end

  # Create an item from the standard operational hash
  #
  # @param params [Hash] The standard operational hash
  # @raise [CreateError] If object not created.
  # @return [Object] The BC created. Includes errors if failed.
  def self.create(params)
    operational_hash = params[:operation]
    managed_item = params[:managed_item]
    object = BiomedicalConcept.from_json(managed_item)
    object.from_operation(operational_hash, C_CID_PREFIX, C_INSTANCE_NS, IsoRegistrationAuthority.owner)
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

  # Update an item from the standard operational hash
  #
  # @param params [Hash] The standard operational hash
  # @raise [UpdateError] If object not created.
  # @return [Object] The BC created. Includes errors if failed.
  def self.update(params)
    operational_hash = params[:operation]
    managed_item = params[:managed_item]
    existing_bc = BiomedicalConcept.find(managed_item[:id], managed_item[:namespace])
    object = BiomedicalConcept.from_json(managed_item)
    object.from_operation(operational_hash, C_CID_PREFIX, C_INSTANCE_NS, IsoRegistrationAuthority.owner)
    if object.valid? then
      sparql = object.to_sparql_v2
      existing_bc.destroy # Destroys the old entry before the creation of the new item
      response = CRUD.update(sparql.to_s)
      if !response.success?
        ConsoleLogger.info(C_CLASS_NAME, "update", "Failed to update object.")
        raise Exceptions::UpdateError.new(message: "Failed to update " + C_CLASS_NAME + " object.")
      end
    end
    return object
  end

  # Upgrade an item
  #
  # @raise [UpdateError or CreateError] if object not updated/created.
  # @return [Object] The BC created. Includes errors if failed.
  def upgrade
    term_map = Hash.new
    thesauri = Thesaurus.unique
    thesauri.each do |item|
      params = {:identifier => item[:identifier], :scope_id => item[:owner_id]}
      history = Thesaurus.history(params)
      update_uri = nil?
      history.each do |item|
        update_uri = item.uri if item.current?
      end
      if update_uri.nil?
        history.each do |item|
          term_map[item.uri.to_s] = {:update => !item.current?, :namespace => update_uri.namespace}
        end
      end
    end
    ConsoleLogger::log(C_CLASS_NAME,"upgrade","term_map=" + term_map.to_json.to_s)
    
    proceed = true
    operational_hash = self.to_operation
    ConsoleLogger::log(C_CLASS_NAME,"upgrade","JSON=#{operational_hash}")
    mi = operational_hash[:managed_item]
    mi[:children].each do |child|
      child[:tc_refs].each do |term_ref|
        if term_map[term_ref[:namespace]][:update]
          id = term_ref[:subject_ref][:id]
          ns_old = term_ref[:subject_ref][:namespace]
          ns_new = term_map[term_ref[:subject_ref][:namespace]][:namespace]
          old_cli = ThesaurusConcept.find(id, ns_old)
          new_cli = ThesaurusConcept.find(id, ns_new)
          ConsoleLogger::log(C_CLASS_NAME,"upgrade","Old CLI=" + old_cli.to_json.to_s)
          ConsoleLogger::log(C_CLASS_NAME,"upgrade","New CLI=" + new_cli.to_json.to_s)
          if ThesaurusConcept.diff?(old_cli, new_cli)
            proceed = false
          end
        end
      end
    end
    
    ConsoleLogger::log(C_CLASS_NAME,"upgrade","JSON=#{operational_hash}")
    if proceed
      mi[:children].each do |child|
        child[:tc_refs].each do |term_ref|
          if term_map[term_ref[:namespace]][:update]
            term_ref[:subject_ref][:uri_ns] = term_map[term_ref[:subject_ref][:namespace]][:namespace]
          end
        end
      end
      ConsoleLogger::log(C_CLASS_NAME,"upgrade","JSON=#{operational_hash}")
      if operational_hash[:operation][:action] == "CREATE"
        BiomedicalConcept.create(operational_hash)
      else
        BiomedicalConcept.update(operational_hash)
      end
    end
  end

  # From JSON
  #
  # @param json [hash] The hash of values for the object 
  # @return [object] The object
  def self.from_json(json)
    object = super(json)
    object.template_ref = OperationalReferenceV2.from_json(json[:template_ref])
    #if !json[:children].blank?
    #  json[:children].each do |child|
    #    object.items << BiomedicalConceptCore::Item.from_json(child)
    #  end
    #end
    return object
  end
  
  # Get Properties
  #
  # @param references [Boolean] True to fill in terminology references, ignore otherwise.
  # @return [Hash] Full managed item has including array of child properties.
  def get_properties(references=false)
    managed_item = super()
    if references
      managed_item[:children].each do |child|
        child[:children].each do |ref|
          tc = ThesaurusConcept.find(ref[:subject_ref][:id], ref[:subject_ref][:namespace])
          ref[:subject_data] = tc.to_json if !tc.nil?
        end
      end
    end
    return managed_item
  end

  # Get Unique References
  #
  # @param managed_item [Hash] The full propeties hash with references
  # @return [Array] Array of unique terminology references (each is a hash)
  def self.get_unique_references(managed_item)
    map = {}
    results = []
    managed_item[:children].each do |child|
      child[:children].each do |ref|
        uri = UriV2.new({id: ref[:subject_ref][:id], namespace: ref[:subject_ref][:namespace]})
        if !map.has_key?(uri.to_s)
          if !ref[:subject_data].blank?
            parent = IsoManaged.find_managed(ref[:subject_ref][:id], ref[:subject_ref][:namespace])
            if !parent[:uri].blank?
              th = IsoManaged.find(parent[:uri].id, parent[:uri].namespace, false)
            end
            ref[:subject_data][:parent] = th.to_json
            results << ref[:subject_data] 
          end
          map[uri.to_s] = true
        end
      end
    end
    return results
  end

  # Domains: Find all domains the BC is linked with
  #
  # @return [Array] array of URis of the linked domains
  def domains
    results = []
    query = UriManagement.buildNs(namespace, ["isoI", "isoC", "bd", "bo"]) +
      "SELECT ?a WHERE \n" +
      "{ \n" +
      "  ?a rdf:type #{SdtmUserDomain::C_RDF_TYPE_URI.to_ref} . \n" +
      "  ?a bd:hasBiomedicalConcept ?or . \n" +
      "  ?or bo:hasBiomedicalConcept #{self.uri.to_ref} . \n" +
      "}"
    response = CRUD.query(query)
    xmlDoc = Nokogiri::XML(response.body)
    xmlDoc.remove_namespaces!
    xmlDoc.xpath("//result").each {|node| results << UriV3.new(uri: ModelUtility.getValue('a', true, node))}
    return results
  end

  # To JSON
  #
  # @return [hash] The object hash 
  def to_json
    json = super
    json[:template_ref] = template_ref.to_json
    return json
  end
  
  # To SPARQL
  #
  # @param sparql [object] The SPARQL object
  # @return [object] The URI
  def to_sparql_v2
    sparql = SparqlUpdateV2.new
    uri = super(sparql)
    ref_uri = self.template_ref.to_sparql_v2(uri, "basedOnTemplate", "TPR", 1, sparql)
    sparql.triple({:uri => uri}, {:prefix => C_SCHEMA_PREFIX, :id => "basedOnTemplate"}, { :uri => ref_uri })
    return sparql
  end

end
