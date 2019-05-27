require 'redcarpet'

# This file fixes the mismatch between how github handles links to other
# markdown files in the project vs. how yardoc handles them.

module YARD
  module Templates
    module Helpers
      module HtmlHelper
        class MDLinkRenderer < Redcarpet::Render::HTML
          def link(link, title, contents)
            if link.=~(/\.md(?:#\w+)?$/)
              %(<a href="/docs/file/#{link}">#{contents}</a>)
            elsif title
              %(<a href="#{link}" title="#{title}"></a>)
            else
              %(<a href="#{link}">#{contents}</a>)
            end
          end
        end
      end
    end
  end
end
class CompatMarkdown
  attr_reader :to_html

  def initialize(text)
    renderer = YARD::Templates::Helpers::HtmlHelper::MDLinkRenderer.new
    markdown = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true, gh_blockcode: true, fenced_code_blocks: true, autolink: true)
    @to_html = markdown.render(text)
  end
end

helper = YARD::Templates::Helpers::MarkupHelper
helper.clear_markup_cache
helper::MARKUP_PROVIDERS[:markdown].unshift const: 'CompatMarkdown'
