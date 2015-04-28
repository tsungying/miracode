class OrdersController < ApplicationController
	before_action :ensure_order_has_item
	before_action :authenticate_user!	
	before_action :own_order, only: [:edit, :update]

  def edit
  	@order = Order.find(params[:id])
  	@order.user_info(current_user)
  end

  def update
  	@order = Order.find(params[:id])
  	if @order.update_attributes(order_params)
  		redirect_to carts_url
  	else
  		render :edit
  	end

  end

  private

  	def ensure_order_has_item	
  		if current_order.order_items.empty?
  			flash[:empty_cart] = "請選購商品後再進行結帳！"
  			redirect_to carts_url
  		end
  	end

  	def order_params
  		params.require(:order).permit(:name, :phone, :address)
  	end

  	def own_order
  		unless session[:order_id] == current_order.id
  			redirect_to root_url
  		end
  	end
end
