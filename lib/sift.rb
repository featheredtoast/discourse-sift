require 'excon'
require 'json'

class Sift
    class Error < StandardError; end

    class Risk
        attr_accessor :risk, :response

       def initialize(risk:, response:, general:, bullying:, fighting:, pii:, sexting:, vulgar:, drugs:, items:, alarm:, fraud:, hate:, religious:, website:, grooming:, threats:, realname:, radicalization:, subversive:, sentiment: )
           @risk = risk,
           @response = response
           @general = general
           @bullying = bullying
           @fighting = fighting
           @pii = pii
           @sexting = sexting
           @vulgar = vulgar
           @drugs = drugs
           @items = items
           @alarm = alarm
           @fraud = fraud
           @hate = hate
           @religious = religious
           @website = website
           @grooming = grooming
           @threats = threats
           @realname = realname
           @radicalization = radicalization
           @subversive = subversive
           @sentiment = sentiment
       end

       def over_any_max_risk
           if
               SiteSetting.sift_general_deny_level.to_i < @general ||
               SiteSetting.sift_bullying_deny_level.to_i < @bullying ||
               SiteSetting.sift_fighting_deny_level.to_i < @fighting ||
               SiteSetting.sift_pii_deny_level.to_i < @pii ||
               SiteSetting.sift_sexting_deny_level.to_i < @sexting ||
               SiteSetting.sift_vulgar_deny_level.to_i < @vulgar ||
               SiteSetting.sift_drugs_deny_level.to_i < @drugs ||
               SiteSetting.sift_items_deny_level.to_i < @items ||
               SiteSetting.sift_alarm_deny_level.to_i < @alarm ||
               SiteSetting.sift_fraud_deny_level.to_i < @fraud ||
               SiteSetting.sift_hate_deny_level.to_i < @hate ||
               SiteSetting.sift_religious_deny_level.to_i < @religious ||
               SiteSetting.sift_website_deny_level.to_i < @website ||
               SiteSetting.sift_grooming_deny_level.to_i < @grooming ||
               SiteSetting.sift_threats_deny_level.to_i < @threats ||
               SiteSetting.sift_realname_deny_level.to_i < @realname ||
               SiteSetting.sift_radicalization_deny_level.to_i < @radicalization ||
               SiteSetting.sift_subversive_deny_level.to_i < @subversive ||
               SiteSetting.sift_sentiment_deny_level.to_i < @sentiment

               true
           else
             false
           end
       end

    end

    class Client

        def initialize(base_url:, api_key:, api_url:, end_point:)
            @base_url = base_url
            @api_key =  api_key
            @api_url = api_url
            @end_point = end_point
        end

        def self.with_client(base_url:, api_key:, api_url:, end_point:)
          client = self.new(base_url: base_url, api_key: api_key, api_url: api_url,  end_point: end_point)
          yield client if block_given?
        end

        def submit_for_classification(to_classify)
          Rails.logger.error('sift_debug: Before inspect...')
          Rails.logger.error("sift_debug: #{to_classify.inspect}")
          Rails.logger.error("sift_debug: #{to_classify.topic.inspect}")
          Rails.logger.error("sift_debug: ...After inspect")
          response = post(@end_point, to_classify)
          if response.nil? || response.status != 200
            #if there is an error reaching Community Sift, escalate to human moderation

            data = {
              'risk' => 0,
              'response' => false,
              'topics' => {}
            }.to_json
            response = Excon::Response.new(:body => data)
          end

          validate_classification(response)
        end

        private

        def validate_classification(response)
            # TODO: Handle errors better?  Currently any issues with connection including incorrect API key leads to
            #       every post needing moderation
            hash = JSON.parse(response.body)

            result_risk = Sift::Risk.new(
                    risk:           (if hash['risk'].nil?; 0; else; hash['risk'].to_i; end;),
                    response:       !!hash['response'],
                    general:        (if hash['topics']['0'].nil?; 0; else; hash['topics']['0'].to_i; end;),
                    bullying:       (if hash['topics']['1'].nil?; 0; else; hash['topics']['1'].to_i; end;),
                    fighting:       (if hash['topics']['2'].nil?; 0; else; hash['topics']['2'].to_i; end;),
                    pii:            (if hash['topics']['3'].nil?; 0; else; hash['topics']['3'].to_i; end;),
                    sexting:        (if hash['topics']['4'].nil?; 0; else; hash['topics']['4'].to_i; end;),
                    vulgar:         (if hash['topics']['5'].nil?; 0; else; hash['topics']['5'].to_i; end;),
                    drugs:          (if hash['topics']['6'].nil?; 0; else; hash['topics']['6'].to_i; end;),
                    items:          (if hash['topics']['7'].nil?; 0; else; hash['topics']['7'].to_i; end;),
                    alarm:          (if hash['topics']['8'].nil?; 0; else; hash['topics']['8'].to_i; end;),
                    fraud:          (if hash['topics']['9'].nil?; 0; else; hash['topics']['9'].to_i; end;),
                    hate:           (if hash['topics']['10'].nil?; 0; else; hash['topics']['10'].to_i; end;),
                    religious:      (if hash['topics']['11'].nil?; 0; else; hash['topics']['11'].to_i; end;),
                    website:        (if hash['topics']['13'].nil?; 0; else; hash['topics']['13'].to_i; end;),
                    grooming:       (if hash['topics']['14'].nil?; 0; else; hash['topics']['14'].to_i; end;),
                    threats:        (if hash['topics']['15'].nil?; 0; else; hash['topics']['15'].to_i; end;),
                    realname:       (if hash['topics']['16'].nil?; 0; else; hash['topics']['16'].to_i; end;),
                    radicalization: (if hash['topics']['17'].nil?; 0; else; hash['topics']['17'].to_i; end;),
                    subversive:     (if hash['topics']['18'].nil?; 0; else; hash['topics']['18'].to_i; end;),
                    sentiment:      (if hash['topics']['19'].nil?; 0; else; hash['topics']['19'].to_i; end;)
                )

            result_risk
        end

        def post(target, to_classify)
          # Assume topic_id and player_id are no more than 1000 chars
          # Send a maximum of 31000 chars which is the default for
          # maximum post length site settings.
          #
          request_text = to_classify.raw.strip[0..30999]
          # If this is the first post, also classify the Topic title
          # TODO: Is this the best way to check for a new/editied topic?
          #   Testing shows that the post is always post_number 1 for new
          #   topics, and edits just to Title of topic also pass the post here
          # TODO: Should title be classified separately rather than pre-pending
          #   to the post text?
          if to_classify.post_number == 1
            request_text = to_classify.topic.title + " " + request_text
          end
          request_url = "#{@api_url}/#{target}"
          request_body= {
            'room' => "#{to_classify.topic.id}",
            'player' => "#{to_classify.user.id}",
            'text' =>  "#{request_text}"
          }.to_json

          # TODO: look at using persistent connections.
          # TODO: Need to handle errors (e.g. incorrect API key)
          response = begin
                       result = Excon.post(request_url,
                                           body: request_body,
                                           headers: {
                                             'Content-Type' => 'application/json',
                                           },
                                           :user => 'discourse-plugin',
                                           :password => @api_key
                                          )
                       result
                     rescue
                       nil
                     end
          response
        end
    end
end
            
        
