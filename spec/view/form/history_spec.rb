require 'rails_helper'

describe 'forms/history.html.erb', :type => :view do

  include UiHelpers
  include UserAccountHelpers
  include DataHelpers

  def sub_dir
    return "views/forms"
  end

  before :all do
    clear_triple_store
    load_schema_file_into_triple_store("ISO11179Types.ttl")
    load_schema_file_into_triple_store("ISO11179Basic.ttl")
    load_schema_file_into_triple_store("ISO11179Identification.ttl")
    load_schema_file_into_triple_store("ISO11179Registration.ttl")
    load_schema_file_into_triple_store("ISO11179Data.ttl")
    load_schema_file_into_triple_store("ISO11179Concepts.ttl")
    load_schema_file_into_triple_store("ISO25964.ttl")
    load_schema_file_into_triple_store("CDISCBiomedicalConcept.ttl")
    load_schema_file_into_triple_store("BusinessOperational.ttl")
    load_schema_file_into_triple_store("BusinessDomain.ttl")
    load_test_file_into_triple_store("iso_namespace_real.ttl")
    load_test_file_into_triple_store("form_example_dm1.ttl")
    load_test_file_into_triple_store("form_example_vs_baseline_new.ttl")
    load_test_file_into_triple_store("form_example_general.ttl")
    load_test_file_into_triple_store("CT_V42.ttl")
    load_test_file_into_triple_store("CT_V43.ttl")
    load_test_file_into_triple_store("CT_ACME_V1.ttl")
    load_test_file_into_triple_store("BCT.ttl")
    load_test_file_into_triple_store("BC.ttl")
    clear_iso_concept_object
    clear_iso_namespace_object
    clear_iso_registration_authority_object
    clear_iso_registration_state_object
    clear_cdisc_term_object
  end

  it 'displays the form history' do 

    def view.policy(name)
      # Do nothing
    end

    allow(view).to receive(:policy).and_return double(edit?: true, destroy?: true)

    params = {:identifier => "DM1 01", :scope_id => IsoRegistrationAuthority.owner.namespace.id}
    forms = Form.history(params)
    assign(:forms, forms)
    assign(:identifier, "DM1 01")

    render

  	#puts response.body

    expect(rendered).to have_content("History: DM1 01")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(1)", text: '0.0.0')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 'Demographics')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(3)", text: 'DM1 01')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(4)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(5)", text: 'ACME')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(11)", text: 'Candidate')
  
    expect(rendered).to have_link "Changes"
    
  end

end