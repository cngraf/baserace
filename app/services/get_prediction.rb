require 'aws-sdk'
require 'pry'

class GetPrediction

  ML_MODEL_ID = Rails.application.secrets.ml_model_id

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

    @headers = "row_id,minutes,radiant_1nw_hero_id,radiant_1nw_net_worth,radiant_2nw_hero_id,radiant_2nw_net_worth,radiant_3nw_hero_id,radiant_3nw_net_worth,radiant_4nw_hero_id,radiant_4nw_net_worth,radiant_5nw_hero_id,radiant_5nw_net_worth,dire_1nw_hero_id,dire_1nw_net_worth,dire_2nw_hero_id,dire_2nw_net_worth,dire_3nw_hero_id,dire_3nw_net_worth,dire_4nw_hero_id,dire_4nw_net_worth,dire_5nw_hero_id,dire_5nw_net_worth".split(',')

    @record = @headers.zip(@row).to_h

    @request = {
      ml_model_id: ML_MODEL_ID,
      predict_endpoint: @url,
      record: @record
    }
  end

  def call
    prediction = @client.predict(@request).prediction
    "Radiant wins #{prediction.predicted_scores.first.last.round(3)}\% of the time."
  end
end