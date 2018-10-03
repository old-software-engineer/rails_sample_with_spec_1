require 'rails_helper'

describe BiomedicalConceptsController do

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
      load_schema_file_into_triple_store("CDISCBiomedicalConcept.ttl")
      load_test_file_into_triple_store("iso_namespace_real.ttl")
      load_test_file_into_triple_store("CT_V42.ttl")
      load_test_file_into_triple_store("BCT.ttl")
      load_test_file_into_triple_store("BC.ttl")
      clear_iso_concept_object
      clear_iso_namespace_object
      clear_iso_registration_authority_object
      clear_iso_registration_state_object
    end

    after :all do
      user = User.where(:email => "lock@example.com").first
      user.destroy
    end

    it "lists all unique templates, HTML" do
      get :index
      expect(assigns[:bcs].count).to eq(13)
      expect(response).to render_template("index")
    end
    
    it "lists all unique templates, JSON" do  
      request.env['HTTP_ACCEPT'] = "application/json"
      get :index
      expect(response.content_type).to eq("application/json")
      expect(response.code).to eq("200")
    #write_text_file_2(response.body, sub_dir, "bc_controller_index.txt")
      expected = read_text_file_2(sub_dir, "bc_controller_index.txt")
      expect(response.body).to eq(expected)
    end

    it "lists all released items" do
      request.env['HTTP_ACCEPT'] = "application/json"
      get :list
      expect(response.content_type).to eq("application/json")
      expect(response.code).to eq("200")
    #write_yaml_file(response.body, sub_dir, "bc_controller_list.yaml")
      expected = read_yaml_file(sub_dir, "bc_controller_list.yaml")
      expect(response.body).to eq(expected)
    end

    it "shows the history" do
      ra = IsoRegistrationAuthority.find_by_short_name("ACME")
      get :history, { :biomedical_concept => { :identifier => "BC C49677", :scope_id => ra.namespace.id }}
      expect(response).to render_template("history")
    end

    it "shows the history, redirects when empty" do
      ra = IsoRegistrationAuthority.find_by_short_name("ACME")
      get :history, { :biomedical_concept => { :identifier => "BC C49678x", :scope_id => ra.namespace.id }}
      expect(response).to redirect_to("/biomedical_concepts")
    end

    it "creates the new BC" do
      item = BiomedicalConceptTemplate.find("BCT-Obs_PQR", "http://www.assero.co.uk/MDRBCTs/V1")
      audit_count = AuditTrail.count
      bc_count = BiomedicalConcept.all.count
      post :create, { :biomedical_concept => { :uri => item.uri.to_s, :identifier => "NEW BC", :label => "New BC" }}
      bc = assigns(:bc)
      expect(bc.errors.count).to eq(0)
      expect(BiomedicalConcept.all.count).to eq(bc_count + 1) 
      expect(flash[:success]).to be_present
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(response).to redirect_to("/biomedical_concepts")
    end

    it "creates the new BC, error" do
      item = BiomedicalConceptTemplate.find("BCT-Obs_PQR", "http://www.assero.co.uk/MDRBCTs/V1")
      audit_count = AuditTrail.count
      bc_count = BiomedicalConcept.all.count
      post :create, { :biomedical_concept => { :uri => "", :identifier => "NEW BC", :label => "New BC" }}
      expect(response).to redirect_to("/biomedical_concepts/new")
    end

    it "edit, no next version" do
      get :edit, { :id => "BC-ACME_NEWBC", :biomedical_concept => {:namespace => "http://www.assero.co.uk/MDRBCs/ACME/V1" }}
      result = assigns(:bc)
      token = assigns(:token)
      expect(token.user_id).to eq(@user.id)
      expect(token.item_uri).to eq("http://www.assero.co.uk/MDRBCs/ACME/V1#BC-ACME_NEWBC") # Note no new version, no copy.
      expect(result.identifier).to eq("NEW BC")
      expect(response).to render_template("edit")
    end

    it "edit BC, next version" do
      get :edit, { :id => "BC-ACME_BC_C25347", :biomedical_concept => {:namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      result = assigns(:bc)
      token = assigns(:token)
      expect(token.user_id).to eq(@user.id)
      expect(token.item_uri).to eq("http://www.assero.co.uk/MDRBCs/ACME/V2#BC-ACME_BCC25347") # Note no new version, no copy.
      expect(result.identifier).to eq("BC C25347")
      expect(response).to render_template("edit")
    end
    
    it "edits BC, already locked" do
      @request.env['HTTP_REFERER'] = 'http://test.host/biomedical_concepts'
      bc = BiomedicalConcept.find("BC-ACME_NEWBC", "http://www.assero.co.uk/MDRBCs/ACME/V1") 
      token = Token.obtain(bc, @lock_user)
      get :edit, { :id => "BC-ACME_NEWBC", :biomedical_concept => {:namespace => "http://www.assero.co.uk/MDRBCs/ACME/V1" }}
      expect(flash[:error]).to be_present
      expect(response).to redirect_to("/biomedical_concepts")
    end

    it "initiates the cloning of a BC" do
      get :clone, { :id => "BC-ACME_BC_C25347", :biomedical_concept => {:namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      bc = assigns(:bc)
      expect(bc.id).to eq("BC-ACME_BC_C25347")
      expect(response).to render_template("clone")
    end

    it "clones a BC" do
      audit_count = AuditTrail.count
      bc_count = BiomedicalConcept.unique.count
      params = 
      { 
        biomedical_concept: 
        { 
          :identifier => "CLONE", 
          :label => "New Clone" , 
          :bc_id => "BC-ACME_BC_C25347", 
          :bc_namespace => "http://www.assero.co.uk/MDRBCs/V1" 
        }
      }
      post :clone_create, params
      bc = assigns(:bc)
      expect(bc.errors.count).to eq(0)
      expect(BiomedicalConcept.unique.count).to eq(bc_count + 1) 
      expect(flash[:success]).to be_present
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(response).to redirect_to("/biomedical_concepts")
    end

    it "clones a BC, error duplicate" do
      audit_count = AuditTrail.count
      bc_count = BiomedicalConcept.all.count
      params = 
      { 
        biomedical_concept: 
        { 
          :identifier => "CLONE", 
          :label => "New Clone" , 
          :bc_id => "BC-ACME_BC_C25347", 
          :bc_namespace => "http://www.assero.co.uk/MDRBCs/V1" 
        }
      }
      post :clone_create, params
      bc = assigns(:bc)
      expect(bc.errors.count).to eq(1)
      expect(flash[:error]).to be_present
      expect(response).to redirect_to("/biomedical_concepts/BC-ACME_BC_C25347/clone?namespace=http%3A%2F%2Fwww.assero.co.uk%2FMDRBCs%2FV1")
    end

    it "edit lock"

    it "edit multiple"

    it "destroy" do
      @request.env['HTTP_REFERER'] = 'http://test.host/biomedical_concepts'
      audit_count = AuditTrail.count
      bc_count = BiomedicalConcept.all.count
      token_count = Token.all.count
      delete :destroy, { :id => "BC-ACME_CLONE", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/ACME/V1" }}
      expect(BiomedicalConcept.all.count).to eq(bc_count - 1)
      expect(AuditTrail.count).to eq(audit_count + 1)
      expect(Token.count).to eq(token_count)
    end
    
    it "upgrade" do
      get :upgrade, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      expect(flash[:error]).to be_present
      expect(response).to redirect_to("/biomedical_concepts/history?biomedical_concept%5Bidentifier%5D=BC+C49678&biomedical_concept%5Bscope_id%5D=NS-ACME")
    end

    it "allows the BC to be viewed" do
      get :show, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      expect(response).to render_template("show")
    end

    it "export_ttl" do
      get :export_ttl, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
    end

    it "export_json" do
      get :export_json, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
    end

  end

  describe "Reader User" do
    
    login_reader

    def sub_dir
      return "controllers"
    end

    it "creates the new BC" do
      post :create, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      expect(response).to redirect_to("/")
    end

    it "edits an BC" do
      get :edit, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      expect(response).to redirect_to("/")
    end
    
    it "initiates the cloning of a BC" do
      get :clone, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      expect(response).to redirect_to("/")
    end

    it "clones a BC" do
      post :clone_create, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      expect(response).to redirect_to("/")
    end

    it "create" do 
      post :create, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      expect(response).to redirect_to("/")
    end
    
    it "destroy" do
      delete :destroy, { :id => "BC-ACME_BC_C49678", :biomedical_concept => { :namespace => "http://www.assero.co.uk/MDRBCs/V1" }}
      expect(response).to redirect_to("/")
    end
    
  end

end