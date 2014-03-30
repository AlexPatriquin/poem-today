require 'open-uri'

class NewsPoem

  def initialize(user)
    @user = user
  end

  def build_collection
    @matches = []

    call_nyt_api
    parse_nyt_api

    add_to_keyword_collection
    match_keywords_to_poems
    save_poems_to_results
    @matches
  end

  def call_nyt_api
    uri = "http://api.nytimes.com/svc/mostpopular/v2/mostemailed/all-sections/1.json?api-key=#{ENV["NYT_APIKEY"]}"
    parsed_uri = URI.parse(uri)
    response = Net::HTTP.get_response(parsed_uri)
    @payload = JSON.parse(response.body)
  end

  def parse_nyt_api
    titles = []
    abstracts = []
    number_of_articles = 3
    @payload["results"][1..number_of_articles].each do |article|
      titles << article["title"]
      # abstracts << article["abstract"]
    end
    @summary_words = titles + abstracts
  end

  def add_to_keyword_collection
    @keywords = []
    source = :news
    @summary_words.join(' ').downcase.gsub(/’s|[^a-z\s]/,'').split.uniq.each do |keyword|
      frequency = call_wordnik_api(keyword)
      @keywords << Keyword.new(keyword, frequency, source) if frequency < 1000
    end 
  end

  def call_wordnik_api(keyword)
    start_year = 2000
    end_year = 2012 #latest
    uri = "http://api.wordnik.com/v4/word.json/#{keyword}/frequency?useCanonical=true&startYear=#{start_year}&endYear=#{end_year}&api_key=#{ENV["WORDNIK_API_KEY"]}"
    parsed_uri = URI.parse(uri)
    response = Net::HTTP.get_response(parsed_uri)
    JSON.parse(response.body)["totalCount"]
  end

  def match_keywords_to_poems  
    @keywords.each do |keyword|
      keyword.poems << Poem.search_by_subject(keyword.text).map    { |poem| { :id => poem.id, :match_type => :subject    }}
      keyword.poems << Poem.search_by_title(keyword.text).map      { |poem| { :id => poem.id, :match_type => :title      }}
      keyword.poems << Poem.search_by_first_line(keyword.text).map { |poem| { :id => poem.id, :match_type => :first_line }}
      keyword.poems << Poem.search_by_content(keyword.text).map    { |poem| { :id => poem.id, :match_type => :content    }}
      keyword.poems.flatten!
    end
  end

  def save_poems_to_results
    @keywords.each do |keyword|
      keyword.poems.each do |poem|
        poem_hash                      = {}
        poem_hash[:poem_id]            = poem[:id]
        poem_hash[:match_type]         = poem[:match_type]        
        poem_hash[:keyword_text]       = keyword.text
        poem_hash[:keyword_frequency]  = keyword.frequency
        poem_hash[:keyword_source]     = keyword.source
        @matches << poem_hash
      end
    end
  end

end