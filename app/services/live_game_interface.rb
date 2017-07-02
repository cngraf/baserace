require 'httparty'
require 'awesome_print'
require 'pry'

RADIANT = 'radiant'
DIRE    = 'dire'
TEAMS   = [RADIANT, DIRE]

class LiveGameInterface

  attr_reader :match_id

  def initialize(match_id)
    @match_id = match_id
  end

  def poll
    response = _request_live_match_data
    return RuntimeError, "couldn't get match - response code #{response[:code]}" unless response[:match]
    parsed_match_data = _parse_match_data(response[:match])
    GetPrediction.new(parsed_match_data).call if parsed_match_data
  end

  private

  def _request_live_match_data
    response = HTTParty.get(_url)
    return { code: response.code } unless response.code == 200
    { match: response['result']['games'].first }
  end

  def _parse_match_data(match_data)
    minutes = match_data['scoreboard']['duration'].to_i / 60

    result = []

    result << "#{@match_id}_#{minutes}"
    result << minutes

    TEAMS.each do |team|
      result << _parse_team_data(match_data, team)
    end

    result.flatten.join(',')
  end

  def _parse_team_data(match_data, team)
    return ArgumentError, "Team #{team} is not valid" unless TEAMS.include? team
    team_data = []
    match_data['scoreboard'][team]['players'].each do |player|
      team_data << player['hero_id']
      team_data << player['net_worth']
    end
    _sort_heroes_by_net_worth(team_data)
  end

  def _sort_heroes_by_net_worth(array)
    array.each_slice(2).to_a.sort { |a, b| b.last.to_i <=> a.last.to_i }
  end

  def _url
    @_url ||= "http://api.steampowered.com/IDOTA2Match_570/GetLiveLeagueGames/v1?key=#{_api_key}&match_id=#{@match_id}"
  end

  def _api_key
    Rails.application.secrets.steam_api_key
  end
end