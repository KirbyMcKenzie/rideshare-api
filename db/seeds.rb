Driver.destroy_all

[
  "1001 Ocean Drive, Miami Beach, FL 33139",
  "1205 Mariposa Ave, Coral Gables, FL 33146",
  "3400 Pan American Dr, Miami, FL 33133",
  "8755 NW 36th St, Doral, FL 33178"
].each do |address|
  Driver.create!(home_address: address)
end
