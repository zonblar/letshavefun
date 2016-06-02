require "json"
require "date"

# your code

def rental_prices
   # parsing the json
   file = File.read('data.json')
   input_hash = JSON.parse(file)
   # defining the ouptu array where we'll stock the hash objects
   output_array = []
   # iterating over the rentals array of the input hash to return json with id and price
   input_hash["rentals"].each do |rental|
   # iterating over the cars array of the input hash to get the associated car for each rental
     associated_car = {}
     input_hash["cars"].each do |car|
      if car["id"] == rental["car_id"]
         associated_car = car
      end
     end
     # calculs intermédiaires
     ending = Date.parse(rental["end_date"])
     starting = Date.parse(rental["start_date"])
     number_of_days = (1+(ending - starting).to_i)
     new_price_per_day = refined_price_per_day(number_of_days, associated_car["price_per_day"])
     price = new_price_per_day + rental["distance"] * associated_car["price_per_km"]
     commission = 0.7
     insurance_fee_commission = 0.15
     insurance_fee = price * insurance_fee_commission
     assistance_fee = number_of_days * 100
     drivy_fee = price * (1 - commission) - insurance_fee - assistance_fee
     deductible_reduction = deductible_reduction_computing(rental["deductible_reduction"], number_of_days)

     output_array << {
      "id": rental["id"],
      "price": price.round(-1),
      "options": {
        "deductible_reduction": deductible_reduction
        },
      "commission":{
        "insurance_fee": insurance_fee.round(-1),
        "assistance_fee": assistance_fee.round(-1),
        "drivy_fee": drivy_fee.round(-1)
        }
      }

   end

   output_hash = { "rentals": output_array }
 end

 def refined_price_per_day(number_of_days, price_per_day)
  decrease_after_one_day = 0.9
  decrease_after_four_days = 0.7
  decrease_after_ten_days = 0.5

  case number_of_days
    when 1
      price_per_day = price_per_day
    when 2..4
     price_per_day =  price_per_day + (number_of_days - 1 ) * price_per_day * decrease_after_one_day
    when 5..10
      price_per_day = price_per_day +
                      3 * price_per_day * decrease_after_one_day +
                      (number_of_days - 4 ) * price_per_day * decrease_after_four_days
    else
      price_per_day = price_per_day +
                      3 * price_per_day * decrease_after_one_day +
                      6 * price_per_day * decrease_after_four_days +
                      (number_of_days - 10 ) * price_per_day * decrease_after_ten_days
  end

  price_per_day

 end

 def deductible_reduction_computing(choice, number_of_days)
  charge = 400
   choice ? charge * number_of_days : 0
 end

 puts rental_prices
