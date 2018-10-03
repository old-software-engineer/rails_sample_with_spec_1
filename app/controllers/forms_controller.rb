class FormsController < ApplicationController
  
  before_action :authenticate_user!
  
  C_CLASS_NAME = "FormsController"

  def new
    authorize Form
    @form = Form.new
  end

  def index
    authorize Form
    @forms = Form.unique
    respond_to do |format|
      format.html 
      format.json do
        results = {}
        results[:data] = []
        @forms.each do |item|
          results[:data] << item
        end
        render json: results
      end
    end
  end
  
  def history
    authorize Form
    @identifier = params[:identifier]
    @scope_id = params[:scope_id]
    @forms = Form.history(params)
    redirect_to forms_path if @forms.count == 0
  end

  def placeholder_new
    authorize Form, :new?
    @form = Form.new
  end
  
  def placeholder_create
    authorize Form, :create?
    @form = Form.create_placeholder(the_params)
    if @form.errors.empty?
      flash[:success] = 'Form was successfully created.'
      AuditTrail.create_item_event(current_user, @form, "Form created.")
      redirect_to forms_path
    else
      flash[:error] = @form.errors.full_messages.to_sentence
      redirect_to placeholder_new_forms_path
    end
  end
  
  def edit
    authorize Form
    @form = Form.find(params[:id], params[:namespace])
    @token = get_token(@form)
    if @form.new_version?
	    new_form = Form.create(@form.to_operation)
    	@form = Form.find(new_form.id, new_form.namespace)
    	@token.release
	    @token = get_token(@form)
  		@operation = @form.update_operation
  	else
  		@operation = @form.to_operation
  	end
  	@close_path = history_forms_path(identifier: @form.identifier, scope_id: @form.owner_id)
  end

  def clone
    authorize Form
    @form = Form.find(params[:id], params[:namespace])
  end

  def clone_create
    authorize Form, :create?
    base_form = Form.find(params[:form_id], params[:form_namespace])
    identifier = base_form.identifier # Preserve for audit log
    operation = base_form.to_clone
    managed_item = operation[:managed_item]
    managed_item[:scoped_identifier][:identifier] = the_params[:identifier]
    managed_item[:label] = the_params[:label]
    @form = Form.create(operation)
    if @form.errors.empty?
      AuditTrail.create_item_event(current_user, @form, "Form cloned from #{identifier}.")
      flash[:success] = 'Form was successfully created.'
      redirect_to forms_path
    else
      flash[:error] = @form.errors.full_messages.to_sentence
      redirect_to clone_forms_path(:id => params[:form_id], :namespace => params[:form_namespace])
    end
  end

  def branch
    authorize Form
    @form = Form.find(params[:id], params[:namespace])
  end

  def branch_create
    authorize Form, :create?
    base_form = Form.find(params[:form_id], params[:form_namespace])
    identifier = base_form.identifier # Preserve for audit log
    operation = base_form.to_clone
    managed_item = operation[:managed_item]
    managed_item[:scoped_identifier][:identifier] = the_params[:identifier]
    managed_item[:label] = the_params[:label]
    @form = Form.create(operation)
    if @form.errors.empty?
      @form.add_branch_parent(params[:form_id], params[:form_namespace]) 
      AuditTrail.create_item_event(current_user, @form, "Form branched from #{identifier}.")
      flash[:success] = 'Form was successfully created.'
      redirect_to forms_path
    else
      flash[:error] = @form.errors.full_messages.to_sentence
      redirect_to branch_forms_path(:id => params[:form_id], :namespace => params[:form_namespace])
    end
  end

  def create
    authorize Form
    @form = Form.create_simple(the_params)
    if @form.errors.empty?
      AuditTrail.create_item_event(current_user, @form, "Form created.")
      flash[:success] = 'Form was successfully created.'
      redirect_to forms_path
    else
      flash[:error] = @form.errors.full_messages.to_sentence
      redirect_to new_form_path
    end
  end

  def update
    authorize Form
    form = Form.find(params[:id], params[:namespace], false)
    token = Token.find_token(form, current_user)
    if !token.nil?
      @form = Form.update(params[:form])
      if @form.errors.empty?
        AuditTrail.update_item_event(current_user, @form, "Form updated.") if token.refresh == 1
        render :json => { :data => @form.to_operation}, :status => 200
      else
        render :json => { :errors => @form.errors.full_messages}, :status => 422
      end
    else
      render :json => {:errors => ["The changes were not saved as the edit lock has timed out."]}, :status => 422
    end
  end

  def destroy
    authorize Form
    form = Form.find(params[:id], params[:namespace], false)
    token = Token.obtain(form, current_user)
    if !token.nil?
      form.destroy
      AuditTrail.delete_item_event(current_user, form, "Form deleted.")
      token.release
    else
      flash[:error] = "The item is locked for editing by another user."
    end
    redirect_to request.referer
  end

  def show 
    authorize Form
    @form = Form.find(params[:id], params[:namespace])
    @close_path = history_forms_path(identifier: @form.identifier, scope_id: @form.owner_id)
  end
  
  def view 
    authorize Form
    @form = Form.find(params[:id], params[:namespace])
    @close_path = history_forms_path(identifier: @form.identifier, scope_id: @form.owner_id)
  end
  
  def export_ttl
    authorize Form
    @form = IsoManaged::find(params[:id], params[:namespace])
    send_data to_turtle(@form.triples), filename: "#{@form.owner}_#{@form.identifier}.ttl", type: 'application/x-turtle', disposition: 'inline'
  end
  
  def export_json
    authorize Form
    @form = Form.find(params[:id], params[:namespace])
    send_data @form.to_json.to_json, filename: "#{@form.owner}_#{@form.identifier}.json", :type => 'application/json; header=present', disposition: "attachment"
  end

  def export_odm
    authorize Form, :export_json?
    @form = Form.find(params[:id], params[:namespace])
    send_data @form.to_xml, filename: "#{@form.owner}_#{@form.identifier}_ODM.xml", :type => 'application/xhtml+xml; header=present', disposition: "attachment"
  end

  def acrf
    authorize Form, :view?
    @form = Form.find(params[:id], params[:namespace])
    @close_path = request.referer
    respond_to do |format|
      format.html do
        @html = Reports::CrfReport.new.create(@form, {:annotate => true, :full => false}, current_user)
      end
      format.pdf do
        @html = Reports::CrfReport.new.create(@form, {:annotate => true, :full => true}, current_user)
        render pdf: "#{@form.owner}_#{@form.identifier}_CRF.pdf", page_size: current_user.paper_size
      end
    end
  end

  def crf
    authorize Form, :view?
    @form = Form.find(params[:id], params[:namespace])
    @close_path = request.referer
    respond_to do |format|
      format.html do
        @html = Reports::CrfReport.new.create(@form, {:annotate => false, :full => false}, current_user)
      end
      format.pdf do
        @html = Reports::CrfReport.new.create(@form, {:annotate => false, :full => true}, current_user)
        render pdf: "#{@form.owner}_#{@form.identifier}_CRF.pdf", page_size: current_user.paper_size
      end
    end
  end

private

  def the_params
    params.require(:form).permit(:namespace, :freeText, :identifier, :label, :children => {}, :bcs => [])
  end

end
