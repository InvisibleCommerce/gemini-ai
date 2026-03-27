# frozen_string_literal: true

require_relative '../../ports/dsl/gemini-ai'
require_relative '../../components/errors'

RSpec.describe Gemini do
  it 'avoids unsupported services' do
    expect do
      described_class.new(
        credentials: {
          service: 'unknown-service'
        }
      )
    end.to raise_error(
      Gemini::Errors::UnsupportedServiceError,
      "Unsupported service: 'unknown-service'."
    )
  end

  it 'includes custom headers in requests' do
    captured_headers = nil

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post(//) do |env|
        captured_headers = env.request_headers
        [200, {}, '{}']
      end
    end

    client = described_class.new(
      credentials: {
        service: 'generative-language-api',
        api_key: 'test-key'
      },
      options: {
        model: 'gemini-2.0-flash',
        headers: {
          'X-Vertex-AI-LLM-Request-Type' => 'shared',
          'X-Vertex-AI-LLM-Shared-Request-Type' => 'priority'
        },
        connection: { adapter: [:test, stubs] }
      }
    )

    client.generate_content({ contents: { role: 'user', parts: { text: 'hi' } } })

    expect(captured_headers['X-Vertex-AI-LLM-Request-Type']).to eq('shared')
    expect(captured_headers['X-Vertex-AI-LLM-Shared-Request-Type']).to eq('priority')
  end

  it 'avoids conflicts with credential keys' do
    expect do
      described_class.new(
        credentials: {
          service: 'vertex-ai-api',
          api_key: 'key',
          file_path: 'path',
          file_contents: 'contents'
        }
      )
    end.to raise_error(
      Gemini::Errors::ConflictingCredentialsError,
      "You must choose either 'api_key', 'file_contents', or 'file_path'."
    )

    expect do
      described_class.new(
        credentials: {
          service: 'vertex-ai-api',
          file_path: 'path',
          file_contents: 'contents'
        }
      )
    end.to raise_error(
      Gemini::Errors::ConflictingCredentialsError,
      "You must choose either 'file_contents', or 'file_path'."
    )
  end
end
