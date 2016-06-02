require "json"
require "date"

# your code
def json_parsing
  # parsing the json
   file = File.read('data.json')
   input_hash = JSON.parse(file)
end

def rental_prices(input_hash)
   #here the input_hash will be the json_parsing one

   # defining the ouptut array where we'll stock the hash objects
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
     # we use the method we created down there
     new_price_per_day = refined_price_per_day(number_of_days, associated_car["price_per_day"])
     price = new_price_per_day + rental["distance"] * associated_car["price_per_km"]
     commission = 0.7
     insurance_fee_commission = 0.15
     insurance_fee = price * insurance_fee_commission
     assistance_fee = number_of_days * 100
     drivy_fee = price * (1 - commission) - insurance_fee - assistance_fee
     # we use the method we created down there
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

 def money_repartition(distribution_hash)
  # the new hash will be based on the rental_prices method
  # here we got : distribution_hash = rental_prices(json_parsing).values[0]
  owner_commission = 0.7
  repartition_array = []

  distribution_hash.each do |rental|
    repartition_array << {
      "id": rental[:id],
      "actions": [
        {
          "who": "driver",
          "type": "debit",
          "amount": rental[:price] + rental[:options][:deductible_reduction]
        },
        {
          "who": "owner",
          "type": "credit",
          "amount": rental[:price] * owner_commission
        },
        {
          "who": "insurance",
          "type": "credit",
          "amount": rental[:commission][:insurance_fee]
        },
        {
          "who": "assistance",
          "type": "credit",
          "amount": rental[:commission][:assistance_fee]
        },
        {
          "who": "drivy",
          "type": "credit",
          "amount": rental[:commission][:drivy_fee] + rental[:options][:deductible_reduction]
        }
      ]
    }
  end

  final_repartition = { "rentals": repartition_array }
 end

 def new_rental_hash(input_hash)
  # here we got input_hash = json_parsing
  # Comparing the rental_modifications hash and rental_hash by ids to see the difference
   input_hash["rental_modifications"].each do |rental_modification|
    input_hash["rentals"].each do |rental|
      if rental["id"] == rental_modification["rental_id"]
        # replacing each different end point
        if rental_modification["end_date"]
          rental["end_date"] = rental_modification["end_date"]
        end
        if rental_modification["start_date"]
          rental["start_date"] = rental_modification["start_date"]
        end
        if rental_modification["distance"]
          rental["distance"] = rental_modification["distance"]
        end
      end
    end
   end

   new_input_hash = input_hash
 end

 def new_rental_prices(input_hash)
  # here we got input_hash = new_rental_hash(json_parsing)
  rental_prices(input_hash)
 end

 def new_money_repartition
  money_repartition(new_rental_prices(new_rental_hash(json_parsing)).values[0])
 end

 def modified_hash(input_hash)
  # old money repartition hash
  old_money_repartition = money_repartition(rental_prices(input_hash).values[0])
  # new money repartition hash
  new_money_repartition

  output_array = []
  rental_modification_id = 1

  # comparing new and old money repartition hashes and making changes accordingly
  new_money_repartition[:rentals].each do |new_rental|
    old_money_repartition[:rentals].each do |old_rental|
      if new_rental[:id] == old_rental[:id] && new_rental[:actions][0][:amount] != old_rental[:actions][0][:amount]
        output_array << {
      "id": rental_modification_id,
      "rental_id": new_rental[:id],
      "actions": [
        {
          "who": "driver",
          "type": (new_rental[:actions][0][:amount] - old_rental[:actions][0][:amount]) > 0 ? "debit" : "credit",
          "amount": (new_rental[:actions][0][:amount] - old_rental[:actions][0][:amount]).abs
        },
        {
          "who": "owner",
          "type": (new_rental[:actions][1][:amount] - old_rental[:actions][1][:amount]) > 0 ? "debit" : "credit",
          "amount": (new_rental[:actions][1][:amount] - old_rental[:actions][1][:amount]).abs
        },
        {
          "who": "insurance",
          "type": (new_rental[:actions][2][:amount] - old_rental[:actions][2][:amount]) > 0 ? "debit" : "credit",
          "amount": (new_rental[:actions][2][:amount] - old_rental[:actions][2][:amount]).abs
        },
        {
          "who": "assistance",
          "type": (new_rental[:actions][3][:amount] - old_rental[:actions][3][:amount]) > 0 ? "debit" : "credit",
          "amount": (new_rental[:actions][3][:amount] - old_rental[:actions][3][:amount]).abs
        },
        {
          "who": "drivy",
          "type": (new_rental[:actions][4][:amount] - old_rental[:actions][4][:amount]) > 0 ? "debit" : "credit",
          "amount": (new_rental[:actions][4][:amount] - old_rental[:actions][4][:amount]).abs
        }
      ]
    }
    rental_modification_id += 1
      end
    end
  end

  output_hash = { "rental_modifications": output_array }

 end

puts modified_hash(json_parsing)
