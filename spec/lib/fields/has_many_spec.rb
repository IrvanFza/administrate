require "rails_helper"
require "administrate/field/has_many"
require "support/constant_helpers"
require "support/mock_relation"

describe Administrate::Field::HasMany do
  describe "#html_controller" do
    it "returns select" do
      page = :show
      items = double
      field = Administrate::Field::HasMany.new(:items, items, page)

      html_controller = field.html_controller

      expect(html_controller).to eq("select")
    end
  end

  describe "#partial_prefixes" do
    it "returns a partial based on the page being rendered" do
      page = :show
      items = double
      field = Administrate::Field::HasMany.new(:items, items, page)

      prefixes = field.partial_prefixes

      expect(prefixes).to eq(["fields/has_many", "fields/associative", "fields/base"])
    end
  end

  describe "#associated_collection" do
    it "returns an index page for the dashboard of the associated attribute" do
      customer = build(:customer)
      field = Administrate::Field::HasMany.new(
        :orders,
        Order.all,
        :show,
        resource: customer
      )

      page = field.associated_collection

      expect(page).to be_instance_of(Administrate::Page::Collection)
    end
  end

  describe "class_name option" do
    let(:dashboard_double) { double(collection_attributes: []) }

    before do
      stub_const("FooDashboard", Class.new)
      allow(FooDashboard).to receive(:new).and_return(dashboard_double)
    end

    it "determines what dashboard is used to present the association" do
      association = Administrate::Field::HasMany
        .with_options(class_name: "Foo")
      field = association.new(:customers, [], :show)
      collection = field.associated_collection
      attributes = collection.attribute_names

      expect(dashboard_double).to have_received(:collection_attributes)
      expect(attributes).to eq([])
    end
  end

  describe "#more_than_limit?" do
    it "returns true if record count > limit" do
      limit = Administrate::Field::HasMany::DEFAULT_LIMIT
      value = MockRelation.new([:a] * (limit + 1))

      association = Administrate::Field::HasMany
      field = association.new(:customers, value, :show)

      expect(field.more_than_limit?).to eq(true)
    end

    it "returns false if record count <= limit" do
      limit = Administrate::Field::HasMany::DEFAULT_LIMIT
      value = MockRelation.new([:a] * limit)

      association = Administrate::Field::HasMany
      field = association.new(:customers, value, :show)

      expect(field.more_than_limit?).to eq(false)
    end

    context "when there are no records" do
      it "returns false" do
        customer = build(:customer)
        value = nil

        field = Administrate::Field::HasMany.new(
          :orders,
          value,
          :show,
          resource: customer
        )

        expect(field.more_than_limit?).to eq(false)
      end
    end
  end

  describe "#resources" do
    it "limits the number of records shown" do
      limit = Administrate::Field::HasMany::DEFAULT_LIMIT
      customer = create(:customer, :with_orders, order_count: 10)
      value = customer.orders

      field = Administrate::Field::HasMany.new(
        :orders,
        value,
        :show,
        resource: customer
      )

      expect(field.resources.size).to eq(limit)
    end

    context "when there are no records" do
      it "returns an empty collection" do
        customer = build(:customer)
        value = nil

        field = Administrate::Field::HasMany.new(
          :orders,
          value,
          :show,
          resource: customer
        )

        expect(field.resources).to eq([])
      end
    end

    context "with `limit` option" do
      it "limits the number of items returned" do
        customer = create(:customer, :with_orders)
        value = customer.orders

        association = Administrate::Field::HasMany.with_options(limit: 1)
        field = association.new(:orders, value, :show, resource: customer)

        expect(field.resources).to be_one
      end
    end

    context "with `sort_by` option" do
      it "returns the resources in correct order" do
        customer = create(:customer, :with_orders)
        options = {sort_by: :address_line_two}
        association = Administrate::Field::HasMany.with_options(options)
        field = association.new(
          :orders,
          customer.orders,
          :show,
          resource: customer
        )

        correct_order = customer.orders.sort_by(&:address_line_two).map(&:id)
        reversed_order = customer.orders.sort do |a, b|
          b.address_line_two <=> a.address_line_two
        end

        expect(field.resources.map(&:id)).to eq correct_order
        expect(field.resources.map(&:id)).to_not eq reversed_order.map(&:id)
      end
    end

    context "with `direction` option" do
      it "returns the resources in correct order" do
        customer = create(:customer, :with_orders)
        options = {sort_by: :address_line_two, direction: :desc}
        association = Administrate::Field::HasMany.with_options(options)
        field = association.new(
          :orders,
          customer.orders,
          :show,
          resource: customer
        )

        reversed_order = customer.orders.sort_by(&:address_line_two).map(&:id)
        correct_order = customer.orders.sort do |a, b|
          b.address_line_two <=> a.address_line_two
        end

        expect(field.resources.map(&:id)).to eq correct_order.map(&:id)
        expect(field.resources.map(&:id)).to_not eq reversed_order
      end
    end
  end

  describe "#selected_options" do
    it "returns a collection of keys to use for the association" do
      associated_resource1 = double(
        "AssociatedResource1",
        associated_resource_key: "associated-1"
      )
      associated_resource2 = double(
        "AssociatedResource2",
        associated_resource_key: "associated-2"
      )
      attribute_value = MockRelation.new(
        [
          associated_resource1,
          associated_resource2
        ]
      )

      primary_resource = double(
        "Resource",
        class: double(
          "ResourceClass",
          reflect_on_association: double(
            "ResourceReflection",
            association_primary_key: "associated_resource_key"
          )
        )
      )

      association = Administrate::Field::HasMany
      field = association.new(
        :customers,
        attribute_value,
        :show,
        resource: primary_resource
      )

      expect(field.selected_options).to eq(["associated-1", "associated-2"])
    end

    context "when there are no records" do
      it "returns an empty collection" do
        customer = build(:customer)
        value = nil

        field = Administrate::Field::HasMany.new(
          :orders,
          value,
          :show,
          resource: customer
        )

        expect(field.selected_options).to be_nil
      end
    end
  end
end
