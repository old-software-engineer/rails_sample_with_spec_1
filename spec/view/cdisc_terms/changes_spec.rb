require 'rails_helper'

describe 'cdisc_terms/changes.html.erb', :type => :view do

  include UiHelpers
  include UserAccountHelpers
  include DataHelpers
  include PublicFileHelpers

  def sub_dir
    return "views/cdisc_terms"
  end

  before :all do
  
  end

  it 'displays the form, next and previous links' do 

    results = read_yaml_file(sub_dir, "changes.yaml")
    cls = read_yaml_file(sub_dir, "changes_cls.yaml")

    assign(:identifier, "CDISC Terminology")
    assign(:trimmed_results, results)
    assign(:cls, cls)
		assign(:previous_version, 40)
    assign(:next_version, 49)

    render

  	#puts response.body

    expect(rendered).to have_content("Changes: CDISC Terminology")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(1)", text: 'C100129')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 'CDISC Questionnaire Category Terminology')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(3)", text: "QSCAT")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(4)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(5)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(6)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(7)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(8)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(9)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(10)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(11)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(12)", text: 'Changes')

    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes?cdisc_term%5Bversion%5D=40' and @class='btn btn-primary']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes?cdisc_term%5Bversion%5D=49' and @class='btn btn-primary']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/history']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes_report.pdf']")
    
  end

  it 'displays the form, next link only' do 

    results = read_yaml_file(sub_dir, "changes.yaml")
    cls = read_yaml_file(sub_dir, "changes_cls.yaml")

    assign(:identifier, "CDISC Terminology")
		assign(:trimmed_results, results)
    assign(:cls, cls)
		assign(:previous_version, nil)
    assign(:next_version, 49)

    render

  	#puts response.body

    expect(rendered).to have_content("Changes: CDISC Terminology")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(1)", text: 'C100129')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 'CDISC Questionnaire Category Terminology')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(3)", text: "QSCAT")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(4)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(5)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(6)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(7)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(8)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(9)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(10)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(11)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(12)", text: 'Changes')

    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes?cdisc_term%5Bversion%5D=' and @class='btn btn-primary disabled']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes?cdisc_term%5Bversion%5D=49' and @class='btn btn-primary']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/history']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes_report.pdf']")
    
  end

    it 'displays the form, previous link only' do 

    results = read_yaml_file(sub_dir, "changes.yaml")
    cls = read_yaml_file(sub_dir, "changes_cls.yaml")

    assign(:identifier, "CDISC Terminology")
    assign(:trimmed_results, results)
    assign(:cls, cls)
		assign(:previous_version, 40)
    assign(:next_version, nil)

    render

  	#puts response.body

    expect(rendered).to have_content("Changes: CDISC Terminology")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(1)", text: 'C100129')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(2)", text: 'CDISC Questionnaire Category Terminology')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(3)", text: "QSCAT")
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(4)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(5)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(6)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(7)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(8)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(9)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(10)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(11)", text: '')
    expect(rendered).to have_selector("table#main tbody tr:nth-of-type(1) td:nth-of-type(12)", text: 'Changes')

    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes?cdisc_term%5Bversion%5D=40' and @class='btn btn-primary']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes?cdisc_term%5Bversion%5D=' and @class='btn btn-primary disabled']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/history']")
    expect(rendered).to have_xpath("//a[@href = '/cdisc_terms/changes_report.pdf']")
    
  end

end