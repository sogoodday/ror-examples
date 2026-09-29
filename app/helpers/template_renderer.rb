module TemplateRenderer
  def render_template(path:, locals:)
    view = ActionView::Base.with_empty_template_cache.new(lookup_context, locals, nil)
    view.class.include(Rails.application.routes.url_helpers)
    view.class.include(EmailTemplatesHelper)
    ActionView::Renderer.new(lookup_context).render(view, { inline: File.read(path) })
  end
end
