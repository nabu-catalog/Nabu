class ItemsController < ApplicationController
  include HasReturnToLastSearch

  before_filter :tidy_params, :only => [:create, :update, :bulk_update]
  load_and_authorize_resource :collection, :find_by => :identifier, :except => [:return_to_last_search, :search, :advanced_search, :bulk_update, :bulk_edit, :new_report, :send_report, :report_sent]
  load_and_authorize_resource :item, :find_by => :identifier, :through => :collection, :except => [:return_to_last_search, :search, :advanced_search, :bulk_update, :bulk_edit, :new_report, :send_report, :report_sent]
  authorize_resource :only => [:advanced_search, :bulk_update, :bulk_edit, :new_report, :send_report, :report_sent]

  def search
    if params[:clear]
      params.delete(:search)
      redirect_to search_items_path
      return
    end

    @search = Item.solr_search do
      fulltext params[:search].gsub(/-/, ' ') if params[:search]

      facet :content_language_ids, :country_ids
      facet :collector_id, :limit => 100

      with(:collector_id, params[:collector_id]) if params[:collector_id].present?
      with(:content_language_ids, params[:language_id]) if params[:language_id].present?
      with(:country_ids, params[:country_id]) if params[:country_id].present?

      with(:private, false) unless current_user && current_user.admin?
      sort_column(Item).each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end

    @page_title = 'Nabu - Item Search'
    respond_to do |format|
      format.html
      if can? :search_csv, Item
        format.csv do
          fields = [:full_identifier, :title, :external, :description, :url, :collector_sortname, :operator_name, :csv_item_agents, :university_name, :language, :dialect, :csv_subject_languages, :csv_content_languages, :csv_countries, :region, :csv_data_categories, :discourse_type_name, :originated_on, :originated_on_narrative, :north_limit, :south_limit, :west_limit, :east_limit, :access_condition_name, :access_narrative]
          send_data @search.results.to_csv({:headers => fields, :only => fields}, :col_sep => ','), :type => "text/csv; charset=utf-8; header=present"
        end
      end
    end
  end

  def advanced_search
    @page_title = 'Nabu - Advanced Item Search'
    do_search
  end

  def new
    @page_title = 'Nabu - Add New Item'

    #For creating duplicate items
    if params[:id]
      existing = Item.find(params[:id])
      attributes = existing.attributes.select do |attr, value|
        Item.column_names.include?(attr.to_s)
      end

      @item.assign_attributes(attributes, :without_protection => true)

      # loop through and clone the association contents as well, otherwise it gets emptied out
      Item::DUPLICATABLE_ASSOCIATIONS.each do |assoc|
        existing.send(assoc).each { |a| @item.send(assoc) << a }
      end
    end

  end

  def show
    @page_title = "Nabu - #{@item.title}"
    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    if params[:sort]
      @files = @files.order("#{params[:sort]} #{params[:direction]}")
    else
      @files = @files.order(:filename)
    end

    respond_to do |format|
      format.html
      format.xml do
        if params[:xml_type]
          render :template => "items/show.#{params[:xml_type]}", formats: [:xml], handlers: [:haml]
        else
          render :template => "items/show", formats: [:xml], handlers: [:haml]
        end
      end
    end
  end

  def create
    @item.assign_attributes(params[:item].except(:item_agents_attributes))

    if @item.save
      # update xml file of the item
      save_item_catalog_file(@item)

      flash[:notice] = 'Item was successfully created.'
      redirect_to [@collection, @item]
    else
      @page_title = 'Nabu - Add New Item'
      render :action => 'new'
    end
  end

  def edit
    @page_title = 'Nabu - Edit Item'
  end

  def destroy
    response = ItemDestructionService.new(@item, params[:delete_essences]).destroy

    flash[:notice] = response[:messages][:notice]
    flash[:error] = response[:messages][:error]

    if response[:success]
      unless params[:delete_essences]
        undo_link = view_context.link_to("undo", revert_version_path(@item.versions.last), :method => :post, :class => 'undo')
        flash[:notice] = flash[:notice] + " (#{undo_link})"
      end
      redirect_to @collection
    else
      redirect_to [@collection, @item]
    end
  end

  def inherit_details
    if @item.inherit_details_from_collection(params[:override_existing])
      flash[:notice] = 'Successfully inherited attributes from collection'
    else
      flash[:alert] = 'Failed to inherit attributes from collection'
    end

    redirect_to [@collection, @item]
  end

  def update
    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    if @item.update_attributes(params[:item])
      # update xml file of the item
      save_item_catalog_file(@item)

      flash[:notice] = 'Item was successfully updated.'
      redirect_to [@collection, @item]
    else
      @page_title = 'Nabu - Edit Item'
      render :action => "edit"
    end
  end

  def bulk_edit
    @item = Item.new
    @item.collection = Collection.new
    @page_title = 'Nabu - Items Bulk Update'

    do_search
  end


  def bulk_update
    @items = Item.accessible_by(current_ability).where :id => params[:item_ids].split(' ')

    params[:item].delete_if {|k, v| v.blank?}

    # Collect the fields we are appending to
    appendable = {}
    params[:item].each_pair do |k, v|
      if k =~ /^bulk_edit_append_(.*)/
        appendable[$1] = params[:item].delete $1 if v == "1"
        params[:item].delete k
      end
    end

    invalid_record = false
    @items.each do |item|
      if item.nil? # I don't think this should be able to be nil
        next
      end

      appendable.each_pair do |k, v|
        if item.send(k).nil?
          params[:item][k.to_sym] = v unless v.blank?
        else
          params[:item][k.to_sym] = item.send(k) + v unless v.blank?
        end
      end
      unless item.update_attributes(params[:item])
        invalid_record = true
        @item = item
        break
      end
      # save updated item info to xml file
      save_item_catalog_file(item)
    end

    appendable.each_pair do |k, v|
      params[:item][k.to_sym] = nil
      params[:item]["bulk_edit_append_#{k}"] = v
    end

    if invalid_record
      do_search
      @page_title = 'Nabu - Items Bulk Update'
      render :action => 'bulk_edit'
    else
      flash[:notice] = 'Items were successfully updated.'
      redirect_to bulk_update_items_path + "?#{params[:original_search_params]}"
    end
  end

  def display
    send_file @item.path, :disposition => 'inline', :type => 'text/xml'
  end

  def new_report
    @page_title = 'Nabu - Depositor Item Report Request'
  end

  def report_sent
    @page_title = 'Nabu - Depositor Item Report Request'
  end

  def send_report
    @date_from = params["date_from"]
    @date_to = params["date_to"]

    downloads_report_service = DownloadsReportService.new(@date_from, @date_to, current_user)

    @send_result = downloads_report_service.send_report

    redirect_to report_sent_items_path, flash: { send_result: @send_result }
  end

  private

  def tidy_params
    if params[:item]
      params[:item][:item_agents_attributes] ||= {}
      params[:item][:item_agents_attributes].each_pair do |id, iaa|
        name = iaa['user_id']
        if name =~ /^NEWCONTACT:/
          iaa['user_id'] = create_contact(name)
        end
      end
      if params[:item][:collector_id] =~ /^NEWCONTACT:/
        params[:item][:collector_id] = create_contact(params[:item][:collector_id])
      end

      if params[:existing_id].present?
        agent_attrs = params[:item].delete(:item_agents_attributes)
        new_agents = agent_attrs.select {|k,v| v[:id].nil? }
        agent_ids = agent_attrs.reject {|k,v| v[:id].nil? || v['_destroy'].to_s != '0' }.map {|k,v| v['id'] }

        params[:item][:item_agents_attributes] = {}
        i = 0
        ItemAgent.where(id: agent_ids).each do |x|
          params[:item][:item_agents_attributes][i.to_s] = {user_id: x.user_id, agent_role_id: x.agent_role_id}
          i += 1
        end

        new_agents.each do |k,v|
          params[:item][:item_agents_attributes][i.to_s] = {user_id: v['user_id'].to_i, agent_role_id: v['agent_role_id'].to_i}
          i += 1
        end
      end
    end
  end

  def do_search
    @fields = Sunspot::Setup.for(Item).fields
    @text_fields = Sunspot::Setup.for(Item).all_text_fields
    @search = Item.solr_search do
      # Full text search
      Sunspot::Setup.for(Item).all_text_fields.each do |field|
        next if params[field.name].blank?
        keywords params[field.name], :fields => [field.name]
      end

      # Exact search
      Sunspot::Setup.for(Item).fields.each do |field|
        next if params[field.name].blank?
        case field.type
        when Sunspot::Type::IntegerType
          with field.name, params[field.name]
        when Sunspot::Type::BooleanType
          with field.name, params[field.name] =~ /^true|1$/ ? true : false
        when Sunspot::Type::TimeType
          with(field.name).between (Time.parse(params[field.name]).beginning_of_day)..(Time.parse(params[field.name]).end_of_day)
        else
          p "WARNING can't search: #{field.type} #{field.name}"
        end
      end

      # GEO Is special
      if params[:north_limit]
        all_of do
          with(:north_limit).less_than    params[:north_limit]
          with(:north_limit).greater_than params[:south_limit]

          with(:south_limit).less_than    params[:north_limit]
          with(:south_limit).greater_than params[:south_limit]

          if params[:west_limit] <= params[:east_limit]
            with(:west_limit).greater_than params[:west_limit]
            with(:west_limit).less_than    params[:east_limit]

            with(:east_limit).greater_than params[:west_limit]
            with(:east_limit).less_than    params[:east_limit]
          else
            any_of do
              all_of do
                with(:west_limit).greater_than params[:west_limit]
                with(:west_limit).less_than    180
              end
              all_of do
                with(:west_limit).less_than    params[:east_limit]
                with(:west_limit).greater_than(-180)
              end
            end
            any_of do
              all_of do
                with(:east_limit).greater_than params[:west_limit]
                with(:east_limit).less_than    180
              end
              all_of do
                with(:east_limit).less_than    params[:east_limit]
                with(:east_limit).greater_than(-180)
              end
            end
          end
        end
      end

      with(:private, false) unless current_user && current_user.admin?
      sort_column(Item).each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end

  def find_by_full_identifier
    if params[:id]
      collection_identifier, item_identifier = params[:id].split(/-/)
      @collection = Collection.find_by_identifier collection_identifier
      @item = @collection.items.find_by_identifier item_identifier
    elsif params[:collection_id]
      @collection = Collection.find_by_identifier params[:collection_id]
    end
  end

  def save_item_catalog_file(item)
    return if item.nil?
    # render the template here because you can't access render in the service
    data = render_to_string :template => 'items/catalog_export.xml.haml', locals: {item: item}

    ItemCatalogService.new(item).save_file(data)
  end
end
