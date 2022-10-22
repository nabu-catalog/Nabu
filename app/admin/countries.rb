ActiveAdmin.register Country do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"
  actions :all, :except => [:destroy]

  permit_params :name, :code

  # Don't filter by countries_languages, languages, or latlon boundaries
  filter :code
  filter :name
end
