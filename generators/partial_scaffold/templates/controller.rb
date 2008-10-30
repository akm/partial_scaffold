class <%= controller_class_name %>Controller < ApplicationController
  include PartialScaffold::RenderPartialOnXhr

  # GET /<%= table_name %>
  # GET /<%= table_name %>.xml
  def index
    @<%= controller_plural_name %> = <%= class_name %>.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @<%= controller_plural_name %> }
    end
  end

  # GET /<%= table_name %>/1
  # GET /<%= table_name %>/1.xml
  def show
    @<%= controller_singular_name %> = <%= class_name %>.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @<%= controller_singular_name %> }
    end
  end

  # GET /<%= table_name %>/new
  # GET /<%= table_name %>/new.xml
  def new
    @<%= controller_singular_name %> = <%= class_name %>.new
<% if route_primary_key_name -%>
    @<%= controller_singular_name %>.<%= route_primary_key_name %> = params[:<%= route_primary_key_name %>]
<% end -%>

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @<%= controller_singular_name %> }
    end
  end

  # GET /<%= table_name %>/1/edit
  def edit
    @<%= controller_singular_name %> = <%= class_name %>.find(params[:id])
  end

  # POST /<%= table_name %>
  # POST /<%= table_name %>.xml
  def create
    @<%= controller_singular_name %> = <%= class_name %>.new(params[:<%= controller_singular_name %>])

    respond_to do |format|
      if @<%= controller_singular_name %>.save
        flash[:notice] = '<%= class_name %> was successfully created.'
        format.html { redirect_to(:controller => '<%= controller_name %>', :action => 'show', :id => @<%= controller_singular_name %>.id) }
        format.xml  { render :xml => @<%= controller_singular_name %>, :status => :created, :location => @<%= controller_singular_name %> }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @<%= controller_singular_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /<%= table_name %>/1
  # PUT /<%= table_name %>/1.xml
  def update
    @<%= controller_singular_name %> = <%= class_name %>.find(params[:id])

    respond_to do |format|
      if @<%= controller_singular_name %>.update_attributes(params[:<%= controller_singular_name %>])
        flash[:notice] = '<%= class_name %> was successfully updated.'
        format.html { redirect_to(:controller => '<%= controller_name %>', :action => 'show', :id => @<%= controller_singular_name %>.id) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @<%= controller_singular_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /<%= table_name %>/1
  # DELETE /<%= table_name %>/1.xml
  def destroy
    @<%= controller_singular_name %> = <%= class_name %>.find(params[:id])
    @<%= controller_singular_name %>.destroy

    respond_to do |format|
      if @<%= controller_singular_name %>.errors.empty?
        format.html {
          request.xhr? ? 
            render(:text => nil) :
            redirect_to(:controller => '<%= controller_name %>', :action => 'index')
        }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @<%= controller_singular_name %>.errors, :status => :unprocessable_entity }
      end
    end
  end
end
