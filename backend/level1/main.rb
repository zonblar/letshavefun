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
     ending = Date.parse(rental["end_date"])
     starting = Date.parse(rental["start_date"])
      output_array << {
        "id": rental["id"],
        "price": (1+(ending - starting).to_i) * associated_car["price_per_day"] + rental["distance"] * associated_car["price_per_km"]
        }
   end

   output_hash = { "rentals": output_array }
 end

puts rental_prices
