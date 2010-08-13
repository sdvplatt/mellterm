class Admin::CompaniesController < Admin::BaseController
  before_filter :require_admin
  
  def index
    @companies = Company.all
  end
  
  def show
    @company = Company.find(params[:id])
  end
  
  def new
    @company = Company.new
  end
  
  def create
    @company = Company.new(params[:company])
    if @company.save
      flash[:notice] = "Successfully created company."
      redirect_to admin_companies_url
    else
      render :action => 'new'
    end
  end
  
  def edit
    @company = Company.find(params[:id])
  end
  
  def update
    @company = Company.find(params[:id])
    if @company.update_attributes(params[:company])
      flash[:notice] = "Successfully updated company."
      redirect_to admin_companies_url
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @company = Company.find(params[:id])
    @company.destroy
    flash[:notice] = "Successfully destroyed company."
    redirect_to admin_companies_url
  end
end
