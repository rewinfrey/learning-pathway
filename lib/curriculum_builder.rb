require 'csv'

class CurriculumBuilder
  attr_reader :domain_order_file_path, :student_tests_file_path

  # Ideally this constant would be configurable outside of this class
  # or passed in as an extra input parameter to the constructor.
  # This is the only assumed hard coded value for parsing the
  # domain_order.csv
  DOMAIN_POSITION = 0

  # Ideally this constant map would also be configurable outside of this
  # class or passed in as an extra input paramaeter, too.
  # Using this constant map, it becomes feasible to arbitrarily
  # order domains. Preschool, subdomains, or categorical domains
  # become possible to use in domain orders, without needing any code change.
  DOMAIN_TO_INTEGER = {
    "K" => 0
  }

  def initialize(domain_order_file_path, student_tests_file_path)
    @domain_order_file_path = domain_order_file_path
    @studnet_tests_file_path = student_tests_file_path
  end

  def plan
    []
  end

  def domain_transition_map
    @domain_transition_map ||= generate_domain_transition_map
  end

  def domain_order_map
    @domain_order_map ||= generate_domain_order_map
  end

  private

  def generate_domain_transition_map
    domains = []
    # Unfortunately Ruby's Enumerator module #reduce or #each_with_index has problems with the IO stream when used with CSV.foreach
    CSV.foreach(domain_order_file_path) { |domain_standard_row| domains << domain_standard_row[DOMAIN_POSITION] }

    sorted_domains = domains.sort do |x, y|
      x = domain_to_integer(x)
      y = domain_to_integer(y)
      x <=> y
    end

    sorted_domains.each_with_index.reduce({}) do |transition_map, (domain, index)|
      transition_map[domain] = sorted_domains[index + 1]
      transition_map
    end
  end

  def generate_domain_order_map
    domain_order = CSV.read(domain_order_file_path)
    domain_order.each_with_index.reduce({}) do |domain_order_map, (domain_row, domain_order_index)|
      domain = domain_for_row(domain_row)
      domain_row.each_with_index do |domain_or_standard, domain_or_standard_index|
        # ignore the domain designation in each row
        next if domain?(domain_or_standard)

        standard = domain_or_standard

        # I did not want to make hard assumptions about the location
        # of the domain in each row of a given domain order csv file.
        if next_standard = next_standard_for_row(domain_row, domain_or_standard_index.next)
          domain_order_map["#{domain}.#{standard}"] = "#{domain}.#{next_standard}"
        elsif next_domain = domain_transition_map[domain]
          next_domain_row = next_domain_row_for_domain(next_domain, domain_order, domain_order_index)
          domain_order_map["#{domain}.#{standard}"] = "#{next_domain}.#{next_standard_for_row(next_domain_row, 0)}"
        else
          domain_order_map["#{domain}.#{standard}"] = nil
        end
      end
      domain_order_map
    end
  end

  def domain?(item)
    domain_transition_map.has_key?(item)
  end

  def domain_for_row(domain_standard_row)
    domain_standard_row.find { |domain_or_standard| domain?(domain_or_standard) }
  end

  def next_standard_for_row(domain_standard_row, index)
    domain_standard_row[(index)..-1].find { |domain_or_standard| !domain?(domain_or_standard) }
  end

  def next_domain_row_for_domain(target_domain, domain_order, domain_order_index)
    domain_order[domain_order_index..-1].find { |domain_row| domain_for_row(domain_row) == target_domain }
  end

  def domain_to_integer(domain)
    DOMAIN_TO_INTEGER.fetch(domain, domain).to_i
  end
end
