class VariablesExtension < Radiant::Extension
  version "0.2"
  description "Adds the ability to set and evaluate variables (including adding variables to snippets)"
  url ""

  def activate
    raise "The Variables Extension requires the Conditional Tags extension to be loaded first" unless defined?(ConditionalTags)
    ConditionalTags::CustomElement.send :include, Variables::Evaluator
    Page.send :include, Variables::PageTags
  end
end