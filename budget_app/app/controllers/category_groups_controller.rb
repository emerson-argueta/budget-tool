class CategoryGroupsController < ApplicationController
  before_action :set_group, only: [:edit, :update, :destroy]

  def new
    @category_group = CategoryGroup.new
  end

  def create
    @category_group = CategoryGroup.new(group_params)
    @category_group.position = CategoryGroup.maximum(:position).to_i + 1

    if @category_group.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("modal", "<turbo-frame id='modal'></turbo-frame>"),
            turbo_stream.replace("flash", partial: "shared/flash", locals: { notice: "Group \"#{@category_group.name}\" created." })
          ]
        end
        format.html { redirect_to budget_path(Date.today.strftime("%Y-%m")), notice: "Group created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category_group.update(group_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("modal", "<turbo-frame id='modal'></turbo-frame>"),
            turbo_stream.replace("flash", partial: "shared/flash", locals: { notice: "Group updated." })
          ]
        end
        format.html { redirect_to budget_path(Date.today.strftime("%Y-%m")), notice: "Group updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category_group.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("group_#{@category_group.id}"),
          turbo_stream.replace("flash", partial: "shared/flash", locals: { notice: "Group deleted." })
        ]
      end
      format.html { redirect_to budget_path(Date.today.strftime("%Y-%m")), notice: "Group deleted." }
    end
  end

  private

  def set_group
    @category_group = CategoryGroup.find(params[:id])
  end

  def group_params
    params.require(:category_group).permit(:name)
  end
end
