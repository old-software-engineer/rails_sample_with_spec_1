class AdHocReport < ActiveRecord::Base

	# Standard Active Record model

	# Create Report
  # Note: Not named create so as not to override
  #
  # @param filename [String] the report definiton file
  # @return [AdHocReport] the created object, contains errors, zero indicates success
  def self.create_report(params)
    object = self.new
    params[:files].reject!(&:blank?)
    filename = params[:files][0]
		definition = YAML.load_file(filename)
	  if check_definition(definition)
      new_filename = AdHocReportFiles.report_sparql_filename(definition[:label])
      if !AdHocReportFiles.exists?(new_filename)
        object.label = definition[:label]
  		  object.background_id = 0
	   	  object.active = false
	 	    object.sparql_file = AdHocReportFiles.report_sparql_filename(definition[:label])
        object.results_file = AdHocReportFiles.report_results_filename(definition[:label])
        AdHocReportFiles.save(object.sparql_file, definition) # Save the definition in the correct location
        object.save
      else
        object.errors.add(:base, "Report was not created. The report already exists")
      end
    else
      object.errors.add(:base, "Report was not created. The SPARQL file did not contain the correct format")
    end
    return object
  rescue Errno::ENOENT
    object.errors.add(:base, "Report was not created. The report definition file did not exist")
    return object
  rescue Psych::SyntaxError 
    object.errors.add(:base, "Report was not created. The SPARQL file contained a syntax error")
    return object
  end

  # Destroy Report
  # Note: Not named destroy so as not to override
  #
  # @return [Null] no return
  def destroy_report
    result = AdHocReportFiles.delete(self.sparql_file)
    result = AdHocReportFiles.delete(self.results_file)
    self.destroy
  end

  # Run A Report
  #
  # @return [Null] no return
  def run
    self.last_run = Time.now
    dt_hash = { columns: [], data: [] }
    AdHocReportFiles.save(self.results_file, dt_hash)
    job = Background.create
    self.background_id = job.id
    self.active = true
    self.save
    job.ad_hoc_report(self)
  end

  # Report Running
  #
  # @return [Boolean] true if running, false otherwise
  def running?
    result = false
    if self.background_id != -1
      job = Background.find(self.background_id)
      result = !job.complete 
    end
    self.active = result
    self.background_id = -1 if !result
    self.save
    return result
  end

  # Report Columns
  #
  # @return [Hash] the column hash
  def columns
    definition = AdHocReportFiles.read(self.sparql_file)
    return definition[:columns] if self.class.check_definition(definition)
    return {}
  end

  # To CSV
  #
  # @return [Object] the CSV serialization
  def to_csv
    dt_result = AdHocReportFiles.read(self.results_file)
    if dt_result.blank?
      dt_result = { columns: [["No Results Error"]], data: [["No Results Error"]] }
    end
    csv_data = CSV.generate do |csv|
      headers = []
      dt_result[:columns].each { |x| headers << x.first }
      csv << headers
      dt_result[:data].each do |x|
        csv << x
      end
    end
    return csv_data
  end

private

  # Check the file structure
  def self.check_definition(definition)
    return false if definition.blank?
    result = definition.key?(:type) &&
      definition.key?(:label) &&
      definition.key?(:columns) &&
      definition.key?(:query) &&
      definition[:type] == "Ad Hoc Report Definition"
    return result
  rescue => e
    return false
  end

end
