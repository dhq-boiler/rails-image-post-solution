# frozen_string_literal: true

module RailsImagePostSolution
  class OpenaiVisionService
    # Perform image content moderation using OpenAI Vision API

    def initialize
      api_key = RailsImagePostSolution.configuration&.openai_api_key || ENV["OPENAI_API_KEY"]
      @client = OpenAI::Client.new(access_token: api_key) if api_key.present?
    end

    # Analyze image to detect R18/R18G content
    # @param attachment [ActiveStorage::Attachment] Image to analyze
    # @return [Hash] Analysis result { flagged: Boolean, categories: Hash, confidence: Float, raw_response: Hash }
    def moderate_image(attachment)
      # Skip if OpenAI API key is not configured
      return safe_result unless @client

      # Get image URL (generate temporary URL)
      image_url = get_image_url(attachment)
      return safe_result unless image_url

      # Call OpenAI Vision API
      response = call_vision_api(image_url)

      # Parse response
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error "OpenAI Vision API error: #{e.message}"
      safe_result # Fail safe on error (no flag)
    end

    private

    def get_image_url(attachment)
      # Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: false)
      # Use Base64 encoding as local URLs don't work in development environment
      return nil unless attachment.blob

      # Encode image as Base64
      image_data = attachment.blob.download
      base64_image = Base64.strict_encode64(image_data)
      "data:#{attachment.blob.content_type};base64,#{base64_image}"
    rescue StandardError => e
      Rails.logger.error "Failed to get image data: #{e.message}"
      nil
    end

    def call_vision_api(image_url)
      @client.chat(
        parameters: {
          model: "gpt-4o-mini", # Model capable of image analysis
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text: moderation_prompt
                },
                {
                  type: "image_url",
                  image_url: {
                    url: image_url
                  }
                }
              ]
            }
          ],
          max_tokens: 500
        }
      )
    end

    def moderation_prompt
      <<~PROMPT
        Analyze this image and determine if it falls into any of the following categories:

        1. R18 (Adult Content): Contains sexual expression or nudity
        2. R18G (Grotesque Content): Contains violent, cruel, or gory imagery
        3. Illegal Content: Illegal drugs, inappropriate use of weapons, etc.

        Please respond in the following JSON format:
        {
          "flagged": true/false,
          "categories": {
            "r18": true/false,
            "r18g": true/false,
            "illegal": true/false
          },
          "confidence": 0.0-1.0,
          "reason": "Brief explanation of the determination"
        }

        **Important**: Respond only in JSON format, do not include any other text.
      PROMPT
    end

    def parse_response(response)
      content = response.dig("choices", 0, "message", "content")
      return safe_result unless content

      # Parse JSON response
      result = JSON.parse(content)

      {
        flagged: result["flagged"] || false,
        categories: result["categories"] || {},
        confidence: result["confidence"] || 0.0,
        reason: result["reason"],
        raw_response: response
      }
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse OpenAI response: #{e.message}, Content: #{content}"
      safe_result
    end

    def safe_result
      {
        flagged: false,
        categories: {},
        confidence: 0.0,
        reason: nil,
        raw_response: nil
      }
    end
  end
end