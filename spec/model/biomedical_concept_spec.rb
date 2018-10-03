require 'rails_helper'

describe BiomedicalConcept do
  
  include DataHelpers

  def sub_dir
    return "models"
  end

  before :all do
    clear_triple_store
    load_schema_file_into_triple_store("ISO11179Types.ttl")
    load_schema_file_into_triple_store("ISO11179Basic.ttl")
    load_schema_file_into_triple_store("ISO11179Identification.ttl")
    load_schema_file_into_triple_store("ISO11179Registration.ttl")
    load_schema_file_into_triple_store("ISO11179Data.ttl")
    load_schema_file_into_triple_store("ISO11179Concepts.ttl")
    load_schema_file_into_triple_store("BusinessOperational.ttl")
    load_schema_file_into_triple_store("CDISCBiomedicalConcept.ttl")
    load_test_file_into_triple_store("iso_namespace_real.ttl")
    load_test_file_into_triple_store("BCT.ttl")
    load_test_file_into_triple_store("BC.ttl")
    load_test_file_into_triple_store("CT_V41.ttl")
    load_test_file_into_triple_store("CT_V42.ttl")
    load_test_file_into_triple_store("CT_V43.ttl")
    clear_iso_concept_object
    clear_iso_namespace_object
    clear_iso_registration_authority_object
    clear_iso_registration_state_object
  end

  it "allows validity of the object to be checked - error" do
    result = BiomedicalConcept.new
    result.valid?
    expect(result.errors.count).to eq(3)
    expect(result.errors.full_messages[0]).to eq("Registration State error: Registration authority error: Namespace error: Short name contains invalid characters")
    expect(result.errors.full_messages[1]).to eq("Registration State error: Registration authority error: Number does not contains 9 digits")
    expect(result.errors.full_messages[2]).to eq("Scoped Identifier error: Identifier contains invalid characters")
    expect(result.valid?).to eq(false)
  end

  it "allows validity of the object to be checked" do
    result = BiomedicalConcept.new
    result.registrationState.registrationAuthority.namespace.shortName = "AAA"
    result.registrationState.registrationAuthority.namespace.name = "USER AAA"
    result.registrationState.registrationAuthority.number = "123456789"
    result.scopedIdentifier.identifier = "hello"
    valid = result.valid?
    expect(result.errors.count).to eq(0)
    expect(valid).to eq(true)
  end 

it "allows a BC to be found" do
    item = BiomedicalConcept.find("BC-ACME_BC_C25206", "http://www.assero.co.uk/MDRBCs/V1")
    expect(item.identifier).to eq("BC C25206")
  end

  it "handles a BC not being found" do
    expect{BiomedicalConcept.find("F-ACME_T2x", "http://www.assero.co.uk/MDRForms/ACME/V1")}.to raise_error(Exceptions::NotFoundError)
  end

  it "finds all entries" do
    expected = []
    expected[0] = "BC-ACME_BC_C25206"
    expected[1] = "BC-ACME_BC_C49677"
    expected[2] = "BC-ACME_BC_A00002"
    expected[3] = "BC-ACME_BC_C98793"
    expected[4] = "BC-ACME_BC_C49678"
    expected[5] = "BC-ACME_BC_C25298"
    expected[6] = "BC-ACME_BC_C25208"
    expected[7] = "BC-ACME_BC_A00003"
    expected[8] = "BC-ACME_BC_C25347"
    expected[9] = "BC-ACME_BC_C16358"
    expected[10] = "BC-ACME_BC_C81255"
    expected[11] = "BC-ACME_BC_C25299"
    expected[12] = "BC-ACME_BC_C98785"
    result = BiomedicalConcept.all
    expect(result.count).to eq(expected.count)
    result.each do |e| 
      expect(expected.include?(e.id)).to be(true) 
    end
  end

  it "finds the history of an item" do
    results = []
    results[0] = {:id => "BC-ACME_BC_C25347", :scoped_identifier_version => 1}
    params = {:identifier => "BC C25347", :scope_id => IsoRegistrationAuthority.owner.namespace.id}
    items = BiomedicalConcept.history(params)
    expect(items.count).to eq(1)
    items.each_with_index do |item, index|
      expect(results[index][:id]).to eq(items[index].id)
      expect(results[index][:scoped_identifier_version]).to eq(items[index].scopedIdentifier.version)
    end
  end

  it "finds list of all released entries" do
    results = []
    results[0] = {:id => "BC-ACME_BC_A00002", :scoped_identifier_version => 1}
    results[1] = {:id => "BC-ACME_BC_A00003", :scoped_identifier_version => 1}
    results[2] = {:id => "BC-ACME_BC_C16358", :scoped_identifier_version => 1}
    results[3] = {:id => "BC-ACME_BC_C25206", :scoped_identifier_version => 1}
    results[4] = {:id => "BC-ACME_BC_C25208", :scoped_identifier_version => 1}
    results[5] = {:id => "BC-ACME_BC_C25298", :scoped_identifier_version => 1}
    results[6] = {:id => "BC-ACME_BC_C25299", :scoped_identifier_version => 1}
    results[7] = {:id => "BC-ACME_BC_C25347", :scoped_identifier_version => 1}
    results[8] = {:id => "BC-ACME_BC_C49677", :scoped_identifier_version => 1}
    results[9] = {:id => "BC-ACME_BC_C49678", :scoped_identifier_version => 1}
    results[10] = {:id => "BC-ACME_BC_C81255", :scoped_identifier_version => 1}
    results[11] = {:id => "BC-ACME_BC_C98785", :scoped_identifier_version => 1}
    results[12] = {:id => "BC-ACME_BC_C98793", :scoped_identifier_version => 1}
    results[13] = {:id => "", :scoped_identifier_version => 1}
    results[14] = {:id => "", :scoped_identifier_version => 1}
    results[15] = {:id => "", :scoped_identifier_version => 1}
    results[16] = {:id => "", :scoped_identifier_version => 1}
    results[17] = {:id => "", :scoped_identifier_version => 1}
    results[18] = {:id => "", :scoped_identifier_version => 1}
    results[19] = {:id => "", :scoped_identifier_version => 1}
    items = BiomedicalConcept.list
    items.each_with_index do |item, index|
      expect(items[index].id).to eq(results[index][:id])
      expect(items[index].scopedIdentifier.version).to eq(results[index][:scoped_identifier_version])
    end
  end

  it "finds all unique entries" do
    results = []
    results[0] = {:id => "BC-ACME_BC_A00002", :scoped_identifier_version => 1}
    results[1] = {:id => "BC-ACME_BC_A00003", :scoped_identifier_version => 1}
    results[2] = {:id => "BC-ACME_BC_C16358", :scoped_identifier_version => 1}
    results[3] = {:id => "BC-ACME_BC_C25206", :scoped_identifier_version => 1}
    results[4] = {:id => "BC-ACME_BC_C25208", :scoped_identifier_version => 1}
    results[5] = {:id => "BC-ACME_BC_C25298", :scoped_identifier_version => 1}
    results[6] = {:id => "BC-ACME_BC_C25299", :scoped_identifier_version => 1}
    results[7] = {:id => "BC-ACME_BC_C25347", :scoped_identifier_version => 1}
    results[8] = {:id => "BC-ACME_BC_C49677", :scoped_identifier_version => 1}
    results[9] = {:id => "BC-ACME_BC_C49678", :scoped_identifier_version => 1}
    results[10] = {:id => "BC-ACME_BC_C81255", :scoped_identifier_version => 1}
    results[11] = {:id => "BC-ACME_BC_C98785", :scoped_identifier_version => 1}
    results[12] = {:id => "BC-ACME_BC_C98793", :scoped_identifier_version => 1}
    results[13] = {:id => "", :scoped_identifier_version => 1}
    results[14] = {:id => "", :scoped_identifier_version => 1}
    results[15] = {:id => "", :scoped_identifier_version => 1}
    results[16] = {:id => "", :scoped_identifier_version => 1}
    results[17] = {:id => "", :scoped_identifier_version => 1}
    results[18] = {:id => "", :scoped_identifier_version => 1}
    results[19] = {:id => "", :scoped_identifier_version => 1}
    items = BiomedicalConcept.list
    items.each_with_index do |item, index|
      expect(items[index].id).to eq(results[index][:id])
      expect(items[index].scopedIdentifier.version).to eq(results[index][:scoped_identifier_version])
    end
  end

  it "allows the object to be exported as JSON" do
    item = BiomedicalConcept.find("BC-ACME_BC_C25206", "http://www.assero.co.uk/MDRBCs/V1")
  #write_yaml_file(item.to_json, sub_dir, "bc_to_json.yaml")
    expected = read_yaml_file(sub_dir, "bc_to_json.yaml")
    expect(item.to_json).to eq(expected)
  end

  it "creates an object based on a template" do
    bct = BiomedicalConceptTemplate.find("BCT-Obs_PQR", "http://www.assero.co.uk/MDRBCTs/V1")
    item = BiomedicalConcept.create_simple({:bct_id => bct.id, :bct_namespace => bct.namespace, :identifier => "NEW BC", :label => "New BC"})
    expect(item.errors.full_messages.to_sentence).to eq("")
    expect(item.errors.count).to eq(0)
  #write_yaml_file(item.to_json, sub_dir, "bc_simple.yaml")
    expected = read_yaml_file(sub_dir, "bc_simple.yaml")
    expected[:creation_date] = date_check_now(item.creationDate).iso8601
    expected[:last_changed_date] = date_check_now(item.lastChangeDate).iso8601
    expect(item.to_json).to eq(expected)
  end

  it "creates an object based on a template, template missing, I" do
    bct = BiomedicalConceptTemplate.find("BCT-Obs_PQR", "http://www.assero.co.uk/MDRBCTs/V1")
    item = BiomedicalConcept.create_simple({:bct_id => "", :bct_namespace => bct.namespace, :identifier => "NEW BC", :label => "New BC"})
    expect(item.errors.full_messages.to_sentence).to eq("No Biomedical Concept Template has been defined.")
    expect(item.errors.count).to eq(1)
  end

  it "creates an object based on a template, template missing, II" do
    bct = BiomedicalConceptTemplate.find("BCT-Obs_PQR", "http://www.assero.co.uk/MDRBCTs/V1")
    item = BiomedicalConcept.create_simple({:bct_id => bct.id, :bct_namespace => nil, :identifier => "NEW BC", :label => "New BC"})
    expect(item.errors.full_messages.to_sentence).to eq("No Biomedical Concept Template has been defined.")
    expect(item.errors.count).to eq(1)
  end

  it "creates an object based on another object" do
    bc = BiomedicalConcept.find("BC-ACME_BC_C98793", "http://www.assero.co.uk/MDRBCs/V1")
    item = BiomedicalConcept.create_clone({:bc_id => bc.id, :bc_namespace => bc.namespace, :identifier => "NEW BC TWO", :label => "New BC Two"})
    expect(item.errors.full_messages.to_sentence).to eq("")
    expect(item.errors.count).to eq(0)
  #write_yaml_file(item.to_json, sub_dir, "bc_clone.yaml")
    expected = read_yaml_file(sub_dir, "bc_clone.yaml")
    expected[:creation_date] = date_check_now(item.creationDate).iso8601
    expected[:last_changed_date] = date_check_now(item.lastChangeDate).iso8601
    expect(item.to_json).to eq(expected)
  end

  it "creates an object based on the standard operation JSON" do
    json = read_yaml_file(sub_dir, "bc_operation.yaml")
    item = BiomedicalConcept.create(json)
  #write_yaml_file(item.to_json, sub_dir, "bc_create.yaml")
    expected = read_yaml_file(sub_dir, "bc_create.yaml")
    expected[:last_changed_date] = date_check_now(item.lastChangeDate).iso8601
    expect(item.to_json).to eq(expected)
  end
    
  it "allows the object to be created, create error" do
    json = read_yaml_file(sub_dir, "bc_operation.yaml")
    allow_any_instance_of(BiomedicalConcept).to receive(:valid?).and_return(true) 
    allow_any_instance_of(BiomedicalConcept).to receive(:create_permitted?).and_return(true) 
    response = Typhoeus::Response.new(code: 200, body: "")
    expect(Rest).to receive(:sendRequest).and_return(response)
    expect(response).to receive(:success?).and_return(false)
    expect(ConsoleLogger).to receive(:info)
    expect{BiomedicalConcept.create(json)}.to raise_error(Exceptions::CreateError)
  end

  it "allows a BC to be updated, validation error" do
    bc = BiomedicalConcept.find("BC-ACME_BC_C98793", "http://www.assero.co.uk/MDRBCs/V1")
    op = read_yaml_file(sub_dir, "bc_update_change_errors.yaml")
    updated_bc = BiomedicalConcept.update(op)
    expect(updated_bc.errors.full_messages.to_sentence).to eq("Item error: Item error: Property, ordinal=2, error: Complex datatype, error: Property, ordinal=1, error: Question text contains invalid characters")
    expect(updated_bc.errors.count).to eq(1)
  end

  it "allows a BC to be updated" do
    bc = BiomedicalConcept.find("BC-ACME_BC_C98793", "http://www.assero.co.uk/MDRBCs/V1")
    op = read_yaml_file(sub_dir, "bc_update_change.yaml")
    updated_bc = BiomedicalConcept.update(op)
    expect(updated_bc.errors.full_messages.to_sentence).to eq("")
    expect(updated_bc.errors.count).to eq(0)
    #write_yaml_file(updated_bc.to_json, sub_dir, "bc_update_result.yaml")
    expected = read_yaml_file(sub_dir, "bc_update_result.yaml")
    expected[:last_changed_date] = date_check_now(updated_bc.lastChangeDate).iso8601
    expect(updated_bc.to_json).to eq(expected)
    new_bc = BiomedicalConcept.find("BC-ACME_BCC98793", "http://www.assero.co.uk/MDRBCs/ACME/V2")
  end

  it "allows the terminology references to be upgraded" #do
  #  bc = BiomedicalConcept.find("BC-ACME_BC_C25206", "http://www.assero.co.uk/MDRBCs/V1")
  #  bc.upgrade
  #write_yaml_file(bc.to_json, sub_dir, "bc_upgrade_result.yaml")
  #  expected = read_yaml_file(sub_dir, "bc_update_upgrade.yaml")
  #  expected[:last_changed_date] = date_check_now(updated_bc.lastChangeDate).iso8601
  #  expect(updated_bc.to_json).to eq(expected)
  #end

  it "allows the object to be created from JSON" do
    json = read_yaml_file(sub_dir, "bc_to_json.yaml")
    item = BiomedicalConcept.from_json(json)
  #write_yaml_file(item.to_json, sub_dir, "bc_from_json.yaml")
    expected = read_yaml_file(sub_dir, "bc_from_json.yaml")
    expect(item.to_json).to eq(expected)
  end

  it "allows an object to be exported as SPARQL" do
    item = BiomedicalConcept.find("BC-ACME_BC_C25206", "http://www.assero.co.uk/MDRBCs/V1")
    result = item.to_sparql_v2
  #write_text_file_2(result.to_s, sub_dir, "bc_sparql.txt")
    expected = read_text_file_2(sub_dir, "bc_sparql.txt")
    expect(result.to_s).to eq(expected)
  end

  it "get the properties, no references" do
    item = BiomedicalConcept.find("BC-ACME_BC_C25206", "http://www.assero.co.uk/MDRBCs/V1")
    result = item.get_properties(false)
  #write_yaml_file(result, sub_dir, "bc_properties_no_ref.yaml")
    expected = read_yaml_file(sub_dir, "bc_properties_no_ref.yaml")
    expect(result).to eq(expected)
  end
    
  it "get the properties with references" do
    item = BiomedicalConcept.find("BC-ACME_BC_C25206", "http://www.assero.co.uk/MDRBCs/V1")
    result = item.get_properties(true)
  #write_yaml_file(result, sub_dir, "bc_properties_with_refs.yaml")
    expected = read_yaml_file(sub_dir, "bc_properties_with_refs.yaml")
    expect(result).to eq(expected)
  end
    
  it "get unique references" do
    item = BiomedicalConcept.find("BC-ACME_BC_C25206", "http://www.assero.co.uk/MDRBCs/V1")
    items = item.get_properties(true)
    result = BiomedicalConcept.get_unique_references(items)
  #write_yaml_file(result, sub_dir, "bc_unique_refs.yaml")
    expected = read_yaml_file(sub_dir, "bc_unique_refs.yaml")
    expect(result).to eq(expected)
  end

  it "returns domains linked, single" do
    load_test_file_into_triple_store("sdtm_user_domain_vs.ttl")
    load_test_file_into_triple_store("sdtm_model_and_ig.ttl")
    vs_uri = UriV3.new(fragment: "D-ACME_VSDomain", namespace: "http://www.assero.co.uk/MDRSdtmUD/ACME/V1")
    vs = SdtmUserDomain.find(vs_uri.fragment, vs_uri.namespace)
    params = { :bcs => ["http://www.assero.co.uk/MDRBCs/V1#BC-ACME_BC_C49677"] }
    vs.add(params)
    bc = BiomedicalConcept.find("BC-ACME_BC_C49677", "http://www.assero.co.uk/MDRBCs/V1")
    results = bc.domains
    expect(results[0].to_s).to eq(vs_uri.to_s)
  end

  it "returns domains linked, multiple"

end
  