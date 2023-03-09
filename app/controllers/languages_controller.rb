class LanguagesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @languages = @languages.includes(:countries).order('languages.name').where('languages.name like ? OR languages.code like ?', "%#{params[:q]}%", "%#{params[:q]}%").limit(10)
    # TODO Does ths code path even get hit anymore with the split that happens in select2?
    if params[:country_ids]
      country_ids = params[:country_ids].split(/,/)
      # TODO there should be a better way of doing this
      @languages = @languages.where(:countries_languages => {:country_id => country_ids})
    end

    @languages = @languages.to_a

    # These are fake languages which we always want in the list
    @languages << Language.find_by_code('mul')
    @languages << Language.find_by_code('und')
    @languages << Language.find_by_code('zxx')

    respond_with @languages
  end

  def show
    respond_with @language
  end

  def language_params
    params.require(:language)
      .permit(:name, :code, :retired, :north_limit, :south_limit, :west_limit, :east_limit, :countries_languages_attributes)
  end
end
