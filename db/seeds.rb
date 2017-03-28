# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

# Officials
# =========

Official.delete_all

Dir[File.expand_path('../../data/meta/officials/*.yml', __FILE__)].each do |official_path|
  data = YAML::load_file(official_path)
  addresses = data.fetch('address', []).map do |address|
    address.values_at(%w{line_1 line_2 city}).join(' ') + ', ' +
     address.values_at(%w{state zip}).join('  ')
  end
  puts "Official #{data['slug']}"
  Official.create! data.slice(*%w{slug name party phones urls emails channels}).merge(
    addresses: addresses,
    third_party_photo_url: data['photoUrl']
  )
end


# Terms
# =====

Term.delete_all

Dir[File.expand_path('../../data/meta/terms/*.yml', __FILE__)].each do |term_path|
  data = YAML::load_file(term_path)
  puts "Term #{term_path}"

  data[:official_slugs].each do |official_slug|
    Term.create!(
      name: data[:name],
      division_slug: data[:division_slug],
      official_slug: official_slug
    )
  end
end
