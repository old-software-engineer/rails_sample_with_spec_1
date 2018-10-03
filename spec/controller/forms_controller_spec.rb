require 'rails_helper'

describe FormsController do

  include DataHelpers
  include PauseHelpers
  
  describe "Curator User" do
  	
    login_curator

    def sub_dir
      return "controllers"
    end

    before :all do
      clear_triple_store
      Token.delete_all
      @lock_user = User.create :email => "lock@example.com", :password => "changeme" 
      load_schema_file_into_triple_store("ISO11179Types.ttl")
      load_schema_file_into_triple_store("ISO11179Basic.ttl")
      load_schema_file_into_triple_store("ISO11179Identification.ttl")
      load_schema_file_into_triple_store("ISO11179Registration.ttl")
      load_schema_file_into_triple_store("ISO11179Data.ttl")
      load_schema_file_into_triple_store("ISO11179Concepts.ttl")
      load_schema_file_into_triple_store("BusinessOperational.ttl")
      load_schema_file_into_triple_store("BusinessForm.ttl")
      load_test_file_into_triple_store("iso_namespace_real.ttl")
      load_test_file_into_triple_store("form_example_dm1.ttl")
      load_test_file_into_triple_store("form_example_dm1_branch.ttl")
      load_test_file_into_triple_store("form_example_vs_baseline_new.ttl")
      load_test_file_into_triple_store("form_example_general.ttl")
      load_test_file_into_triple_store("CT_V43.ttl")
      load_test_file_into_triple_store("CT_ACME_V1.ttl")
      clear_iso_concept_object
      clear_iso_namespace_object
      clear_iso_registration_authority_object
      clear_iso_registration_state_object
      clear_cdisc_term_object
    end

    after :all do
      user = User.where(:email => "lock@example.com").first
      user.destroy
    end

    it "provides a new object" do
      get :new
      result = assigns[:form]
      expected = Form.new
      expected.creationDate = result.creationDate
      expected.lastChangeDate = result.lastChangeDate
      expect(result.to_json).to eq(expected.to_json)
      expect(response).to render_template("new")
    end

    it "lists all unique forms, HTML" do
      get :index
      expect(assigns[:forms].count).to eq(4)
      expect(response).to render_template("index")
    end
    
    it "lists all unique forms, JSON" do  
      request.env['HTTP_ACCEPT'] = "application/json"
      get :index
      expect(response.content_type).to eq("application/json")
      expect(response.code).to eq("200")
      #write_text_file_2(response.body, sub_dir, "forms_controller_index.txt")
      expected = read_text_file_2(sub_dir, "forms_controller_index.txt")
      expect(response.body).to eq(expected)

    end

    it "shows the history" do
      get :history, { :identifier => "DM1 01", :scope_id => IsoRegistrationAuthority.owner.namespace.id }
      expect(response).to render_template("history")
    end

    it "shows the history, redirects when empty" do
      get :history, { :identifier => "DM1 01X", :scope_id => IsoRegistrationAuthority.owner.namespace.id }
      expect(response).to redirect_to("/forms")
    end

    it "initiates the creation of a new placeholder form" do
      get :placeholder_new
      expect(assigns[:form].to_json).to eq(Form.new.to_json)
      expect(response).to render_template("placeholder_new")
    end

    it "creates the placeholder form" do
      audit_count = AuditTrail.count
      form_count = Form.all.count
      post :placeholder_create, form: { :identifier => "NEW TH", :label => "New TH Form", :freeText => "* List Item 1\n* List Item 2\n\nThis form is required to do the following:\n\n* Collect the date" }
      form = assigns(:form)
      expect(form.errors.count).to eq(0)
      expect(Form.unique.count).to eq(form_count + 1) 
      expect(flash[:success]).to be_present
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(response).to redirect_to("/forms")
    end

    it "edit, no next version" do
      get :edit, { :id => "F-ACME_NEWTH", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      result = assigns(:form)
      token = assigns(:token)
      expect(token.user_id).to eq(@user.id)
      expect(token.item_uri).to eq("http://www.assero.co.uk/MDRForms/ACME/V1#F-ACME_NEWTH") # Note no new version, no copy.
      expect(result.identifier).to eq("NEW TH")
      expect(response).to render_template("edit")
    end
    
    it "edit form, next version" do
      get :edit, { :id => "F-ACME_VSBASELINE1", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      result = assigns(:form)
      token = assigns(:token)
      expect(token.user_id).to eq(@user.id)
      expect(token.item_uri).to eq("http://www.assero.co.uk/MDRForms/ACME/V2#F-ACME_VSBASELINE") # Note new version, copy.
      expect(result.identifier).to eq("VS BASELINE")
      expect(response).to render_template("edit")
    end
    
    it "edits form, already locked" do
      @request.env['HTTP_REFERER'] = 'http://test.host/forms'
      form = Form.find("F-ACME_NEWTH", "http://www.assero.co.uk/MDRForms/ACME/V1") 
      token = Token.obtain(form, @lock_user)
      get :edit, { :id => "F-ACME_NEWTH", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to("/forms")
    end

    it "edits form, copy, already locked" do
      @request.env['HTTP_REFERER'] = 'http://test.host/forms'
      # Lock the new form
      new_form = Form.new
      new_form.id = "F-ACME_VSBASELINE"
      new_form.namespace = "http://www.assero.co.uk/MDRForms/ACME/V2" # Note the V2, the expected new version.
      new_token = Token.obtain(new_form, @lock_user)
      # Attempt to edit
      get :edit, { :id => "F-ACME_VSBASELINE1", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to("/forms")
    end

    it "initiates the cloning of a form" do
      get :clone, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      form = assigns(:form)
      expect(form.id).to eq("F-ACME_DM101")
      expect(response).to render_template("clone")
    end

    it "clones a form" do
      audit_count = AuditTrail.count
      form_count = Form.unique.count
      post :clone_create,  { form: { :identifier => "CLONE", :label => "New Clone" }, :form_id => "F-ACME_DM101", :form_namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      form = assigns(:form)
      expect(form.errors.count).to eq(0)
      expect(Form.unique.count).to eq(form_count + 1) 
      expect(flash[:success]).to be_present
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(response).to redirect_to("/forms")
    end

    it "clones a form, error duplicate" do
      audit_count = AuditTrail.count
      form_count = Form.all.count
      post :clone_create,  { form: { :identifier => "CLONE", :label => "New Clone" }, :form_id => "F-ACME_DM101", :form_namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      form = assigns(:form)
      expect(form.errors.count).to eq(1)
      expect(flash[:error]).to be_present
      expect(response).to redirect_to("/forms/clone?id=F-ACME_DM101&namespace=http%3A%2F%2Fwww.assero.co.uk%2FMDRForms%2FACME%2FV1")
    end

    it "initiates the branching of a form" do
      get :branch, { :id => "F-ACME_DM1BRANCH", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      form = assigns(:form)
      expect(form.id).to eq("F-ACME_DM1BRANCH")
      expect(response).to render_template("branch")
    end

    it "branches a form" do
      audit_count = AuditTrail.count
      form_count = Form.unique.count
      post :branch_create,  { form: { :identifier => "BRANCH", :label => "New Branch" }, :form_id => "F-ACME_DM1BRANCH", :form_namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      form = assigns(:form)
      expect(form.errors.count).to eq(0)
      expect(Form.unique.count).to eq(form_count + 1) 
      expect(flash[:success]).to be_present
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(response).to redirect_to("/forms")
      item = Form.find("F-ACME_BRANCH", "http://www.assero.co.uk/MDRForms/ACME/V1")
      expect(item.is_a_branch?).to eq(true)
    end

    it "branches a form, error duplicate" do
      audit_count = AuditTrail.count
      form_count = Form.all.count
      post :branch_create,  { form: { :identifier => "BRANCH", :label => "New Branch" }, :form_id => "F-ACME_DM1BRANCH", :form_namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      form = assigns(:form)
      expect(form.errors.count).to eq(1)
      expect(flash[:error]).to be_present
      expect(response).to redirect_to("/forms/branch?id=F-ACME_DM1BRANCH&namespace=http%3A%2F%2Fwww.assero.co.uk%2FMDRForms%2FACME%2FV1")
    end

    it "creates"
    
    it "updates"

    it "destroy" do
      @request.env['HTTP_REFERER'] = 'http://test.host/forms'
      audit_count = AuditTrail.count
      form_count = Form.all.count
      token_count = Token.all.count
      delete :destroy, { :id => "F-ACME_CLONE", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(Form.all.count).to eq(form_count - 1)
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(Token.count).to eq(token_count)
    end

    it "show" do
      get :show, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(response).to render_template("show")
    end

    it "view " do
      get :view, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(response).to render_template("view")
    end

    it "export_ttl" do
      get :export_ttl, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
    end

    it "export_json" do
      get :export_json, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
    end

    it "export_odm" do
      get :export_odm, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
    end
    
    it "presents acrf as pdf" do
      request.env['HTTP_ACCEPT'] = "application/pdf"
      get :acrf, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(response.content_type).to eq("application/pdf")
    end

    it "presents acrf as pdf" do
      get :acrf, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(response).to render_template("acrf")
    end

    it "presents acrf as pdf" do
      request.env['HTTP_ACCEPT'] = "application/pdf"
      get :crf, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(response.content_type).to eq("application/pdf")
    end

    it "presents acrf as pdf" do
      get :crf, { :id => "F-ACME_DM101", :namespace => "http://www.assero.co.uk/MDRForms/ACME/V1" }
      expect(response).to render_template("crf")
    end

  end

  describe "Unauthorized User" do
    
    login_reader

    it "prevents access to a reader, placeholder new" do
      get :placeholder_new
      expect(response).to redirect_to("/")
    end

    it "prevents access to a reader, placeholder create" do
      get :placeholder_create
      expect(response).to redirect_to("/")
    end

    it "prevents access to a reader, edit" do
      get :edit, id: 1
      expect(response).to redirect_to("/")
    end

    it "prevents access to a reader, update" do
      put :update, id: 1
      expect(response).to redirect_to("/")
    end

    it "prevents access to a reader, destroy" do
      delete :destroy, id: 1
      expect(response).to redirect_to("/")
    end

  end

end