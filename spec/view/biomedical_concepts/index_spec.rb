require 'rails_helper'

describe 'biomedical_concepts/index.html.erb', :type => :view do

  include UiHelpers
  include UserAccountHelpers

  it 'displays product details correctly, edit and new enabled' do
    
    def view.policy(name)
      # Do nothing
    end

    allow(view).to receive(:policy).and_return double(edit?: true, new?: true)

    bcs = []
    bcs << { :owner => "ABC", :identifier => "ID1", :label => "Number 1", :owner_id => "ABC_ID" }
    bcs << { :owner => "ABC", :identifier => "ID2", :label => "Number 2", :owner_id => "ABC_ID" } 
    bcs << { :owner => "XYZ", :identifier => "ID3", :label => "Number 3", :owner_id => "XYZ_ID" } 
    assign(:bcs, bcs)

    render
    expect(rendered).to have_content("Index: Biomedical Concepts")
    expect(rendered).to have_content("New Biomedical Concept")
    expect(rendered).to have_content("Edit Multiple Biomedical Concepts")
    #ui_check_breadcrumb("Background", "", "", "")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(1)", text: 'ABC')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 'ID1')  
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(3)", text: 'Number 1')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(2) td:nth-of-type(1)", text: 'ABC')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(2) td:nth-of-type(2)", text: 'ID2')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(2) td:nth-of-type(3)", text: 'Number 2')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(3) td:nth-of-type(1)", text: 'XYZ')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(3) td:nth-of-type(2)", text: 'ID3')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(3) td:nth-of-type(3)", text: 'Number 3')
    
  end

  it 'displays product details correctly, edit not enabled, new enabled' do
    
    def view.policy(name)
      # Do nothing
    end

    allow(view).to receive(:policy).and_return double(edit?: false, new?: true)

    bcs = []
    bcs << { :owner => "ABC", :identifier => "ID1", :label => "Number 1", :owner_id => "ABC_ID" }
    assign(:bcs, bcs)

    render
    expect(rendered).to have_content("Index: Biomedical Concepts")
    expect(rendered).to have_content("New Biomedical Concept")
    expect(rendered).to_not have_content("Edit Multiple Biomedical Concepts")
    #ui_check_breadcrumb("Background", "", "", "")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(1)", text: 'ABC')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 'ID1')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(3)", text: 'Number 1')
    
  end

  it 'displays product details correctly, edit enabled, new not enabled' do
    
    def view.policy(name)
      # Do nothing
    end

    allow(view).to receive(:policy).and_return double(edit?: true, new?: false)

    bcs = []
    bcs << { :owner => "ABC", :identifier => "ID1", :label => "Number 1", :owner_id => "ABC_ID" }
    assign(:bcs, bcs)

    render
    expect(rendered).to have_content("Index: Biomedical Concepts")
    expect(rendered).to_not have_content("New Biomedical Concept")
    expect(rendered).to have_content("Edit Multiple Biomedical Concepts")
    #ui_check_breadcrumb("Background", "", "", "")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(1)", text: 'ABC')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 'ID1')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(3)", text: 'Number 1')
    
  end

  it 'displays product details correctly, no edit or new enabled' do
    
    def view.policy(name)
      # Do nothing
    end

    allow(view).to receive(:policy).and_return double(edit?: false, new?: false)

    bcs = []
    bcs << { :owner => "ABC", :identifier => "ID1", :label => "Number 1", :owner_id => "ABC_ID" }
    assign(:bcs, bcs)

    render
    expect(rendered).to have_content("Index: Biomedical Concepts")
    expect(rendered).to_not have_content("New Biomedical Concept")
    expect(rendered).to_not have_content("Edit Multiple Biomedical Concepts")
    #ui_check_breadcrumb("Background", "", "", "")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(1)", text: 'ABC')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 'ID1')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(3)", text: 'Number 1')
    
  end

end