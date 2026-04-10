module ApplicationHelper
  include Chartkick::Helper
  def nav_link(label, path, **options)
    active = current_page?(path) || request.path.start_with?(path == authenticated_root_path ? "/dashboard" : path)
    classes = active ? "px-3 py-2 rounded-md text-sm font-medium text-indigo-600 bg-indigo-50" \
                     : "px-3 py-2 rounded-md text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-100"
    link_to label, path, class: classes, **options
  end

  def money(amount)
    number_to_currency(amount, unit: "$", precision: 2)
  end

  def money_class(amount)
    amount.negative? ? "text-red-600" : "text-gray-900"
  end
end
