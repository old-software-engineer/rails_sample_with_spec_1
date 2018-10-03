require 'rails_helper'

describe AdHocReportsController do

  include DataHelpers
  include PauseHelpers
  include PublicFileHelpers

  describe "ad hoc reports as content admin" do
  
    login_content_admin
  
    def sub_dir
      return "controllers"
    end

    before :all do
      clear_triple_store
      delete_all_public_test_files
      delete_all_public_report_files
      AdHocReport.delete_all
      @ahr1 = AdHocReport.create(label: "Report No. 1", sparql_file: "report_1_sparql.txt", results_file: "report_1_results.yaml", last_run: Time.now, active: false, background_id: 0)
      @ahr2 = AdHocReport.create(label: "Report No. 2", sparql_file: "report_2_sparql.txt", results_file: "report_2_results.yaml", last_run: Time.now, active: false, background_id: 0)
      @ahr3 = AdHocReport.create(label: "Report No. 3", sparql_file: "report_3_sparql.txt", results_file: "report_3_results.yaml", last_run: Time.now, active: false, background_id: 0)
    end
    
    it "lists all the reports" do
      get :index
      expect(assigns(:items).count).to eq(3) 
      expect(response).to render_template("index")
    end

    it "initiates creation of a new report" do
      get :new
      expect(response).to render_template("new")
    end

    it "allows a new report to be created, missing file" do
      count = AdHocReport.all.count
      filename = public_path("upload", "filname_root.yaml")
      post :create, { ad_hoc_report: { files: [filename] }}
      expect(flash[:error]).to be_present
      expect(AdHocReport.all.count).to eq(count)
      expect(response).to redirect_to("http://test.host/ad_hoc_reports/new")
    end

    it "allows a new report to be created" do
      delete_all_public_test_files
      delete_all_public_report_files
      audit_count = AuditTrail.count
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      count = AdHocReport.all.count
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      post :create, { ad_hoc_report: { files: [filename] }}
      expect(flash[:success]).to be_present
      expect(AdHocReport.all.count).to eq(count + 1)
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(response).to redirect_to("http://test.host/ad_hoc_reports")
    end

    it "allows a report to be run" do
      delete_all_public_test_files
      delete_all_public_report_files
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      post :create, { ad_hoc_report: { files: [filename] }}
      report = AdHocReport.where(:label => "Ad Hoc Report 1").first
      get :run_start, { id: report.id }
      expect(response).to render_template("results")
    end

    it "allows the progress of a report run to be seen" do
      delete_all_public_test_files
      delete_all_public_report_files
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      post :create, { ad_hoc_report: { files: [filename] }}
      report = AdHocReport.where(:label => "Ad Hoc Report 1").first
      get :run_start, { id: report.id }
      get :run_progress, { id: report.id }
      expect(response.code).to eq("200")
      expect(response.body).to eq("{\"running\":false}")
    end

    it "allows the results of a report to be presented" do
      delete_all_public_test_files
      delete_all_public_report_files
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      post :create, { ad_hoc_report: { files: [filename] }}
      report = AdHocReport.where(:label => "Ad Hoc Report 1").first
      get :run_start, { id: report.id }
      get :run_progress, { id: report.id }
      get :run_results, { id: report.id }
      expect(response.code).to eq("200")
      expect(response.body).to eq("{\"columns\":[[\"URI\"],[\"Identifier\"],[\"Label\"]],\"data\":[]}")
    end

    it "allows the existing results of a report to be presented" do
      delete_all_public_test_files
      delete_all_public_report_files
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      post :create, { ad_hoc_report: { files: [filename] }}
      report = AdHocReport.where(:label => "Ad Hoc Report 1").first
      get :results, { id: report.id }
      found_report = assigns(:report)
      columns = assigns(:columns)
      expect(found_report.id).to eq(report.id)
      expect(columns).to eq({"?a"=>{:label=>"URI", :type=>"uri"}, "?b" => {:label=>"Identifier", :type=>"literal"}, "?c" => {:label=>"Label", :type=>"literal"}})
      expect(response).to render_template("results")   
    end

    it "allows a report to be deleted" do
      @request.env['HTTP_REFERER'] = 'http://test.host/ad_hoc_reports'
      audit_count = AuditTrail.count
      count = AdHocReport.all.count
      post :destroy, { id: @ahr2.id }
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(AdHocReport.all.count).to eq(count - 1)
      expect(response).to redirect_to("http://test.host/ad_hoc_reports")
    end

  end
  
  describe "ad hoc reports as curator" do
  	
    login_curator
   
    before :all do
      clear_triple_store
      delete_all_public_files
      AdHocReport.delete_all
      @ahr1 = AdHocReport.create(label: "Report No. 1", sparql_file: "report_1_sparql.txt", results_file: "report_1_results.yaml", last_run: Time.now, active: false, background_id: 0)
      @ahr2 = AdHocReport.create(label: "Report No. 2", sparql_file: "report_2_sparql.txt", results_file: "report_2_results.yaml", last_run: Time.now, active: false, background_id: 0)
      @ahr3 = AdHocReport.create(label: "Report No. 3", sparql_file: "report_3_sparql.txt", results_file: "report_3_results.yaml", last_run: Time.now, active: false, background_id: 0)
    end
    
    it "lists all the reports" do
      get :index
      expect(assigns(:items).count).to eq(3) 
      expect(response).to render_template("index")
    end

    it "prevents a new report to be created" do
      get :new
      expect(response).to redirect_to("/")
    end

    it "allows a report to be run" do
      delete_all_public_test_files
      delete_all_public_report_files
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      files = []
      files << filename
      AdHocReport.create_report({files: files}) # Create directly as user cannot
      report = AdHocReport.where(:label => "Ad Hoc Report 1").first
      get :run_start, { id: report.id }
      expect(response).to render_template("results")
    end

    it "allows the progress of a report run to be seen" do
      delete_all_public_test_files
      delete_all_public_report_files
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      files = []
      files << filename
      AdHocReport.create_report({files: files}) # Create directly as user cannot
      report = AdHocReport.where(:label => "Ad Hoc Report 1").first
      get :run_start, { id: report.id }
      get :run_progress, { id: report.id  }
      expect(response.code).to eq("200")
    end

    it "allows the results of a report to be presented" do
      delete_all_public_test_files
      delete_all_public_report_files
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      files = []
      files << filename
      AdHocReport.create_report({files: files}) # Create directly as user cannot
      report = AdHocReport.where(:label => "Ad Hoc Report 1").first
      get :run_start, { id: report.id }
      get :run_results, { id: report.id }
      expect(response.code).to eq("200")
      expect(response.body).to eq("{\"columns\":[[\"URI\"],[\"Identifier\"],[\"Label\"]],\"data\":[]}")
    end

     it "allows the existing results of a report to be presented" do
      delete_all_public_test_files
      delete_all_public_report_files
      copy_file_to_public_files("controllers", "ad_hoc_report_test_1_sparql.yaml", "upload")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      filename = public_path("upload", "ad_hoc_report_test_1_sparql.yaml")
      files = []
      files << filename
      AdHocReport.create_report({files: files}) # Create directly as user cannot
      report = AdHocReport.where(:label => "Ad Hoc Report 1").first
      get :results, { id: report.id }
      found_report = assigns(:report)
      columns = assigns(:columns)
      expect(found_report.id).to eq(report.id)
      expect(columns).to eq({"?a"=>{:label=>"URI", :type=>"uri"}, "?b" => {:label=>"Identifier", :type=>"literal"}, "?c" => {:label=>"Label", :type=>"literal"}})
      expect(response).to render_template("results")    
    end

     it "prevents a report to be deleted" do
      post :destroy, { id: @ahr3.id }
      expect(response).to redirect_to("/")
    end

  end

  describe "Reader Role" do
    
    login_reader
   
    before :all do
      clear_triple_store
      delete_all_public_files
      AdHocReport.delete_all
      ahr = AdHocReport.create(label: "Report No. 1", sparql_file: "report_1_sparql.txt", results_file: "report_1_results.yaml", last_run: Time.now, active: false, background_id: 0)
      ahr = AdHocReport.create(label: "Report No. 2", sparql_file: "report_2_sparql.txt", results_file: "report_2_results.yaml", last_run: Time.now, active: false, background_id: 0)
      ahr = AdHocReport.create(label: "Report No. 3", sparql_file: "report_3_sparql.txt", results_file: "report_3_results.yaml", last_run: Time.now, active: false, background_id: 0)
    end
    
    it "prevents a reader listing all the reports" do
      get :index
      expect(response).to redirect_to("/")
    end

    it "prevents a reader creating a report" do
      get :new
      expect(response).to redirect_to("/")
    end

    it "prevents a reader running a report" do
      get :run_start, { id: 1 }
      expect(response).to redirect_to("/")
    end

    it "prevents a reader seeing a running report" do
      get :run_progress, { id: 1 }
      expect(response).to redirect_to("/")
    end

    it "prevents a reader to see report results" do
      get :run_results, { id: 1 }
      expect(response).to redirect_to("/")
    end

    it "prevents a reader seeing the results of a report" do
      get :results, { id: 1 }
      expect(response).to redirect_to("/")
    end

  end

  describe "Unauthorized User" do
    
    it "prevents unauthorized access to listing all the reports" do
      get :index
      expect(response).to redirect_to("/users/sign_in")
    end

    it "prevents unauthorized access to creating a report" do
      get :new
      expect(response).to redirect_to("/users/sign_in")
    end

    it "prevents unauthorized access to running a report" do
      get :run_start, { id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end

    it "prevents unauthorized access to seeing a running report" do
      get :run_progress, { id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end

    it "prevents unauthorized access to report results" do
      get :run_results, { id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end

    it "prevents unauthorized access to seeing the results of a report" do
      get :results, { id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end

  end

end