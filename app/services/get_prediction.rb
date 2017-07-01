require 'aws-sdk'
require 'pry'

class GetPrediction

  ML_MODEL_ID = 'ml-CiaN2KJEIzD'

  def initialize(row)
    @row      = row.split(',').map(&:to_s)
    @staus    = nil
    @client   = Aws::MachineLearning::Client.new(region: 'us-east-1')
    @response = @client.create_realtime_endpoint(ml_model_id: ML_MODEL_ID)

    until @status == 'READY'
      @status = @response.realtime_endpoint_info.endpoint_status
      puts "Endpoint status: #{@status}"
      @response = @client.create_realtime_endpoint(ml_model_id: ML_MODEL_ID)
      sleep(1)
    end

    @url = @response.realtime_endpoint_info.endpoint_url

    @headers = File.open('assets/headers.csv').read.chomp.split(',').tap { |a| a.delete('radiant_win') }
    @record = @headers.zip(@row).to_h

    @request = {
      ml_model_id: ML_MODEL_ID,
      predict_endpoint: @url,
      record: @record
    }
  end

  def call
    prediction = @client.predict(@request).prediction
    puts "Radiant odds: #{prediction.predicted_scores.values.first.round(3)}"
    prediction
  end
end