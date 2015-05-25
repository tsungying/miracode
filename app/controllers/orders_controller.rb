class OrdersController < ApplicationController
	before_action :ensure_order_has_item, only: [:new, :create]
	before_action :authenticate_user!	    
	# before_action :own_order, only: [:edit, :update]  

  def index
    @orders = valid_order.order(id: :desc).page(params[:page])
  end

  def new
    @order = current_user.orders.new
  end

  def create
    @order = current_user.orders.new(order_params_on_create)
    @order.add_cart_info(current_cart)
    if @order.save
      OrderMailer.pending(@order).deliver
      session[:cart_id] = nil
      flash[:placed_order] = '訂單建立成功！感謝您的購買，歡迎您再次蒞臨！'
      redirect_to @order
    else
      render 'new'
    end
  end

  def show
    @order = valid_order.find_by_id(params[:id])
    redirect_to root_url unless @order

    # 產生結帳表單
    if @order.order_status_id == 1
      get_checkout_params(@order) 
    end

    # 產生ATM匯款資訊
    if @order.order_status_id == 5
      @order_payment_info = @order.get_payment_info
    end

  end

  def update
    order = current_user.orders.find_by_id(params[:id])
    if order && order.cancel
      flash[:cancel_order_result] = "訂單已成功取消！"
    else
      flash[:cancel_order_result] = "無效的操作！"
    end
    redirect_to :back
  end

  private

  	def ensure_order_has_item	
  		if current_cart.order_items.empty?
  			flash[:empty_cart] = "請選購商品後再進行結帳！"
  			redirect_to carts_url
  		end
  	end

    def order_params_on_create
      params.require(:order).permit(:name, :cellphone, :address, :payment_id)
    end

  	def order_params_on_update
  		params.require(:order).permit(:merchant_trade_no)
  	end

    def valid_order
      current_user.orders.where(order_status: (1..5).to_a)
    end

    def get_checkout_params(order)
      client = Allpay::Client.new(mode: :production)
      payment_type = %w[Credit WebATM ATM]

      # 不論選擇哪種結帳方式都需要傳送的欄位
      fields = {
        TotalAmount: order.total,
        TradeDesc: 'Miracode',
        ItemName: "合計共#{order.cart.total_quantity}件商品",
        ReturnURL: notifications_url, # 付款完成通知回傳網址
        ClientBackURL: order_url(order),
        ChoosePayment: payment_type[order.payment_id-1]
      }

      # ATM=3 額外增加的欄位
      if order.payment_id == 3
        fields[:PaymentInfoURL] = atm_payment_infos_url
      end
      
      @params = client.generate_checkout_params(fields) 
      order.update_attributes(merchant_trade_no: @params[:MerchantTradeNo])
      return @params
    end    

end
