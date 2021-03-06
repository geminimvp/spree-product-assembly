module Spree
  LineItem.class_eval do
    scope :assemblies, -> { joins(product: :parts).uniq }

    has_many :part_line_items, dependent: :destroy

    def selected_parts=(parts)
      return unless parts.present?
      selected_parts = parts.split(",").map(&:to_i)
      selected_parts.each do |variant|
        part_line_item = self.part_line_items.find_or_initialize_by(
          line_item: self,
          variant_id: variant,
          quantity: 1
        )
      end
    end

    def any_units_shipped?
      inventory_units.any? { |unit| unit.shipped? }
    end

    # The parts that apply to this particular LineItem. Usually `product#parts`,
    # but provided as a hook if you want to override and customize the parts for
    # a specific LineItem.
    def parts
      product.parts
    end

    def has_parts?
      parts.present?
    end

    def insufficient_parts_selected?
      has_parts? && part_line_items.count != product_or_variant_parts
    end

    # The number of the specified variant that make up this LineItem. By
    # default, calls `product#count_of`, but provided as a hook if you want to
    # override and customize the parts available for a specific LineItem. Note
    # that if you only customize whether a variant is included in the LineItem,
    # and don't customize the quantity of that part per LineItem, you shouldn't
    # need to override this method.
    def count_of(variant)
      product.count_of(variant)
    end

    def quantity_by_variant
      if has_parts?
        if part_line_items.any?
          quantity_with_part_line_items(quantity)
        else
          quantity_without_part_line_items(quantity)
        end
      else
        { variant => quantity }
      end
    end

    private

    def product_or_variant_parts
      product.required_part_count > 0 ? product.required_part_count : variant.parts_variants.sum(:count)
    end

    def update_inventory
      if (changed? || target_shipment.present?) &&
         order.has_checkout_step?("delivery")
        if product.assembly?
          OrderInventoryAssembly.new(self).verify(target_shipment)
        else
          OrderInventory.new(order, self).verify(target_shipment)
        end
      end
    end

    def quantity_with_part_line_items(quantity)
      part_line_items.group_by(&:variant_id).each_with_object({}) do |ap, hash|
        variant = Spree::Variant.find(ap.first)
        hash[variant] = ap.last.count * quantity
      end
    end

    def quantity_without_part_line_items(quantity)
      product.assemblies_parts.each_with_object({}) do |ap, hash|
        hash[ap.part] = ap.count * quantity
      end
    end
  end
end
