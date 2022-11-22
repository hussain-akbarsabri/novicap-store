# frozen_string_literal: true

require 'json'

class Checkout
  PRODUCTS = 'products'
  DISCOUNTS = 'discounts'

  def initialize
    @products = fetch_api_data(PRODUCTS)
    @discounts = active_discounts(fetch_api_data(DISCOUNTS))
    @cart = []
  end

  def scan(product_code)
    return false if product_code.empty?

    product = @products.detect { |product| product['code'] == product_code.upcase }
    @cart << product if product
    product
  end

  def total
    puts discount_price
  end

  private

  def fetch_api_data(file_name)
    products_data_file = File.open "data/#{file_name}.json"
    JSON.parse(products_data_file) || []
  end

  def active_discounts(discounts)
    discounts.select { |discount| discount['active'] }
  end

  def discount_price
    discount_price = []
    grouped_cart_items = @cart.group_by { |cart_item| cart_item['code'] }
    return false if grouped_cart_items.empty?

    grouped_cart_items.each_key do |cart_item_name|
      products = grouped_cart_items[cart_item_name]
      discount = @discounts.detect { |discount| discount['product'] == cart_item_name }
      discount_price << if discount
                          discounted_price(discount, products)
                        else
                          products.map { |product| product['price'] }.sum
                        end
    end
    discount_price.sum
  end

  def discounted_price(discount, products)
    case discount['name']
    when '2-for-1'
      products[0..(products.count / 2).ceil].map { |product| product['price'] }.sum
    when 'bulk-purchase'
      adjustment = products.count >= 3 ? products.count : 0
      products.map { |product| product['price'] }.sum - adjustment
    end
  end
end
