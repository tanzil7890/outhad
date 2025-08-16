# Shopify Integration Guide for Outhad Platform

## Table of Contents
1. [Overview](#overview)
2. [Project Structure Analysis](#project-structure-analysis)
3. [Shopify API Research](#shopify-api-research)
4. [Source Connector Implementation](#source-connector-implementation)
5. [Destination Connector Implementation](#destination-connector-implementation)
6. [Configuration Files](#configuration-files)
7. [Testing Implementation](#testing-implementation)
8. [Registration and Rollout](#registration-and-rollout)
9. [Development Workflow](#development-workflow)
10. [Best Practices](#best-practices)

## Overview

This guide provides a comprehensive step-by-step approach to implement both Shopify source and destination connectors for the Outhad ETL platform. Based on analysis of existing integrations and Shopify's 2024 API documentation, this guide covers the complete implementation process.

### What You'll Build
- **Shopify Source**: Extract data from Shopify stores (products, orders, customers, etc.)
- **Shopify Destination**: Load data into Shopify stores (create/update products, customers, etc.)

## Project Structure Analysis

### Outhad Integration Framework

The Outhad platform uses a modular integration framework with the following structure:

```
integrations/lib/outhad/integrations/
├── core/                           # Base classes and utilities
│   ├── source_connector.rb        # Base source connector
│   ├── destination_connector.rb   # Base destination connector
│   ├── base_connector.rb          # Common functionality
│   ├── http_client.rb             # HTTP utilities
│   └── rate_limiter.rb            # Rate limiting
├── source/                        # Source connectors
│   └── [connector_name]/
│       ├── client.rb              # Main implementation
│       ├── config/
│       │   ├── meta.json          # Metadata
│       │   └── spec.json          # Configuration schema
│       └── icon.svg               # Connector icon
├── destination/                   # Destination connectors
│   └── [connector_name]/
│       ├── client.rb              # Main implementation
│       ├── config/
│       │   ├── meta.json          # Metadata
│       │   ├── spec.json          # Configuration schema
│       │   └── catalog.json       # Available streams/tables
│       └── icon.svg               # Connector icon
└── rollout.rb                     # Enabled connectors registry
```

### Key Base Classes

1. **SourceConnector**: Inherits from `BaseConnector`
   - `check_connection(connection_config)`: Test connection
   - `discover(connection_config)`: Schema discovery
   - `read(sync_config)`: Data extraction

2. **DestinationConnector**: Inherits from `BaseConnector`
   - `check_connection(connection_config)`: Test connection
   - `discover(connection_config)`: Available streams
   - `write(sync_config, records, action)`: Data loading

## Shopify API Research

### API Overview (2024)

Shopify provides multiple APIs:

1. **Admin REST API** (Legacy - being phased out)
2. **Admin GraphQL API** (Primary, feature-complete)
3. **Storefront API** (Public data access)

**Important**: As of 2024, Shopify is transitioning to GraphQL as the primary API. New apps must use GraphQL by April 1, 2025.

### Authentication Methods

1. **Private Apps** (Recommended for ETL)
   - Admin-generated access tokens
   - Direct API access
   - No OAuth required

2. **Public Apps**
   - OAuth 2.0 flow
   - Dynamic token generation
   - App store distribution

### Key Data Objects

| Object | Description | GraphQL Type |
|--------|-------------|--------------|
| Products | Store inventory items | `Product` |
| ProductVariants | Product variations | `ProductVariant` |
| Orders | Customer purchases | `Order` |
| Customers | Store customers | `Customer` |
| Collections | Product groupings | `Collection` |
| Inventory | Stock levels | `InventoryLevel` |
| Fulfillments | Order shipping | `Fulfillment` |
| Metafields | Custom data | `Metafield` |

### Rate Limiting

- **GraphQL**: Query cost system (points per field)
- **REST**: Request-based limits (deprecated)
- **Recommended**: Use official Ruby gem for automatic handling

### Pagination

GraphQL uses cursor-based pagination with `after` and `first` parameters.

## Source Connector Implementation

### Step 1: Create Directory Structure

```bash
mkdir -p integrations/lib/outhad/integrations/source/shopify/config
mkdir -p integrations/spec/outhad/integrations/source/shopify
```

### Step 2: Implement Client Class

Create `integrations/lib/outhad/integrations/source/shopify/client.rb`:

```ruby
# frozen_string_literal: true

require 'shopify_api'

module Outhad::Integrations::Source
  module Shopify
    include Outhad::Integrations::Core

    class Client < SourceConnector
      prepend Outhad::Integrations::Core::RateLimiter

      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        initialize_client(connection_config)
        test_connection
        success_status
      rescue StandardError => e
        failure_status(e)
      end

      def discover(connection_config = nil)
        catalog = build_catalog(load_catalog)
        catalog.to_outhad_message
      rescue StandardError => e
        handle_exception(e, {
          context: "SHOPIFY:SOURCE:DISCOVER:EXCEPTION",
          type: "error"
        })
      end

      def read(sync_config)
        @sync_config = sync_config
        connection_config = sync_config.source.connection_specification
        initialize_client(connection_config)
        
        stream_name = sync_config.stream.name
        
        case stream_name
        when "products"
          read_products
        when "orders"
          read_orders
        when "customers"
          read_customers
        when "collections"
          read_collections
        else
          raise "Unsupported stream: #{stream_name}"
        end
      rescue StandardError => e
        handle_exception(e, {
          context: "SHOPIFY:SOURCE:READ:EXCEPTION",
          type: "error",
          sync_id: @sync_config.sync_id,
          sync_run_id: @sync_config.sync_run_id
        })
      end

      private

      def initialize_client(config)
        config = config.with_indifferent_access
        
        ShopifyAPI::Context.setup(
          api_key: config[:api_key],
          api_secret_key: config[:api_secret],
          host: config[:host],
          scope: "read_products,read_orders,read_customers,read_inventory",
          is_embedded: false,
          api_version: "2024-07",
          is_private: true
        )

        @session = ShopifyAPI::Auth::Session.new(
          shop: config[:shop_domain],
          access_token: config[:access_token]
        )
        
        @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
      end

      def test_connection
        query = <<~GRAPHQL
          query {
            shop {
              id
              name
            }
          }
        GRAPHQL
        
        response = @client.query(query: query)
        raise "Connection failed" if response.body["errors"]
      end

      def read_products
        query = build_products_query
        paginate_and_extract(query, "products") do |product|
          transform_product(product)
        end
      end

      def read_orders
        query = build_orders_query
        paginate_and_extract(query, "orders") do |order|
          transform_order(order)
        end
      end

      def read_customers
        query = build_customers_query
        paginate_and_extract(query, "customers") do |customer|
          transform_customer(customer)
        end
      end

      def read_collections
        query = build_collections_query
        paginate_and_extract(query, "collections") do |collection|
          transform_collection(collection)
        end
      end

      def paginate_and_extract(query, resource_name)
        records = []
        cursor = nil
        
        loop do
          paginated_query = add_pagination(query, cursor)
          response = @client.query(query: paginated_query)
          
          handle_graphql_errors(response)
          
          data = response.body.dig("data", resource_name)
          edges = data["edges"]
          
          break if edges.empty?
          
          edges.each do |edge|
            node = edge["node"]
            transformed_record = yield(node)
            records << RecordMessage.new(
              data: transformed_record,
              emitted_at: Time.now.to_i
            ).to_outhad_message
          end
          
          page_info = data["pageInfo"]
          break unless page_info["hasNextPage"]
          cursor = edges.last["cursor"]
        end
        
        records
      end

      def build_products_query
        <<~GRAPHQL
          query($first: Int!, $after: String) {
            products(first: $first, after: $after) {
              edges {
                cursor
                node {
                  id
                  title
                  handle
                  description
                  vendor
                  productType
                  tags
                  status
                  createdAt
                  updatedAt
                  variants(first: 250) {
                    edges {
                      node {
                        id
                        title
                        sku
                        price
                        compareAtPrice
                        inventoryQuantity
                        weight
                        weightUnit
                      }
                    }
                  }
                  images(first: 10) {
                    edges {
                      node {
                        id
                        url
                        altText
                      }
                    }
                  }
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
            }
          }
        GRAPHQL
      end

      def build_orders_query
        <<~GRAPHQL
          query($first: Int!, $after: String) {
            orders(first: $first, after: $after) {
              edges {
                cursor
                node {
                  id
                  name
                  email
                  createdAt
                  updatedAt
                  totalPriceSet {
                    shopMoney {
                      amount
                      currencyCode
                    }
                  }
                  subtotalPriceSet {
                    shopMoney {
                      amount
                      currencyCode
                    }
                  }
                  totalTaxSet {
                    shopMoney {
                      amount
                      currencyCode
                    }
                  }
                  financialStatus
                  fulfillmentStatus
                  customer {
                    id
                    email
                    firstName
                    lastName
                  }
                  lineItems(first: 250) {
                    edges {
                      node {
                        id
                        title
                        quantity
                        variant {
                          id
                          sku
                        }
                        originalUnitPriceSet {
                          shopMoney {
                            amount
                            currencyCode
                          }
                        }
                      }
                    }
                  }
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
            }
          }
        GRAPHQL
      end

      def build_customers_query
        <<~GRAPHQL
          query($first: Int!, $after: String) {
            customers(first: $first, after: $after) {
              edges {
                cursor
                node {
                  id
                  email
                  firstName
                  lastName
                  phone
                  createdAt
                  updatedAt
                  ordersCount
                  totalSpentV2 {
                    amount
                    currencyCode
                  }
                  addresses {
                    id
                    firstName
                    lastName
                    company
                    address1
                    address2
                    city
                    province
                    country
                    zip
                    phone
                  }
                  tags
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
            }
          }
        GRAPHQL
      end

      def build_collections_query
        <<~GRAPHQL
          query($first: Int!, $after: String) {
            collections(first: $first, after: $after) {
              edges {
                cursor
                node {
                  id
                  title
                  handle
                  description
                  updatedAt
                  productsCount
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
            }
          }
        GRAPHQL
      end

      def add_pagination(query, cursor = nil)
        variables = { first: 50 }
        variables[:after] = cursor if cursor
        
        {
          query: query,
          variables: variables
        }
      end

      def handle_graphql_errors(response)
        if response.body["errors"]
          errors = response.body["errors"].map { |e| e["message"] }.join(", ")
          raise "GraphQL errors: #{errors}"
        end
      end

      def transform_product(product)
        {
          id: product["id"],
          title: product["title"],
          handle: product["handle"],
          description: product["description"],
          vendor: product["vendor"],
          product_type: product["productType"],
          tags: product["tags"],
          status: product["status"],
          created_at: product["createdAt"],
          updated_at: product["updatedAt"],
          variants: product.dig("variants", "edges")&.map { |e| transform_variant(e["node"]) } || [],
          images: product.dig("images", "edges")&.map { |e| transform_image(e["node"]) } || []
        }
      end

      def transform_variant(variant)
        {
          id: variant["id"],
          title: variant["title"],
          sku: variant["sku"],
          price: variant["price"],
          compare_at_price: variant["compareAtPrice"],
          inventory_quantity: variant["inventoryQuantity"],
          weight: variant["weight"],
          weight_unit: variant["weightUnit"]
        }
      end

      def transform_image(image)
        {
          id: image["id"],
          url: image["url"],
          alt_text: image["altText"]
        }
      end

      def transform_order(order)
        {
          id: order["id"],
          name: order["name"],
          email: order["email"],
          created_at: order["createdAt"],
          updated_at: order["updatedAt"],
          total_price: order.dig("totalPriceSet", "shopMoney", "amount"),
          currency: order.dig("totalPriceSet", "shopMoney", "currencyCode"),
          subtotal_price: order.dig("subtotalPriceSet", "shopMoney", "amount"),
          total_tax: order.dig("totalTaxSet", "shopMoney", "amount"),
          financial_status: order["financialStatus"],
          fulfillment_status: order["fulfillmentStatus"],
          customer: transform_order_customer(order["customer"]),
          line_items: order.dig("lineItems", "edges")&.map { |e| transform_line_item(e["node"]) } || []
        }
      end

      def transform_order_customer(customer)
        return nil unless customer
        
        {
          id: customer["id"],
          email: customer["email"],
          first_name: customer["firstName"],
          last_name: customer["lastName"]
        }
      end

      def transform_line_item(item)
        {
          id: item["id"],
          title: item["title"],
          quantity: item["quantity"],
          variant_id: item.dig("variant", "id"),
          sku: item.dig("variant", "sku"),
          price: item.dig("originalUnitPriceSet", "shopMoney", "amount"),
          currency: item.dig("originalUnitPriceSet", "shopMoney", "currencyCode")
        }
      end

      def transform_customer(customer)
        {
          id: customer["id"],
          email: customer["email"],
          first_name: customer["firstName"],
          last_name: customer["lastName"],
          phone: customer["phone"],
          created_at: customer["createdAt"],
          updated_at: customer["updatedAt"],
          orders_count: customer["ordersCount"],
          total_spent: customer.dig("totalSpentV2", "amount"),
          currency: customer.dig("totalSpentV2", "currencyCode"),
          addresses: customer["addresses"]&.map { |addr| transform_address(addr) } || [],
          tags: customer["tags"]
        }
      end

      def transform_address(address)
        {
          id: address["id"],
          first_name: address["firstName"],
          last_name: address["lastName"],
          company: address["company"],
          address1: address["address1"],
          address2: address["address2"],
          city: address["city"],
          province: address["province"],
          country: address["country"],
          zip: address["zip"],
          phone: address["phone"]
        }
      end

      def transform_collection(collection)
        {
          id: collection["id"],
          title: collection["title"],
          handle: collection["handle"],
          description: collection["description"],
          updated_at: collection["updatedAt"],
          products_count: collection["productsCount"]
        }
      end

      def load_catalog
        read_json(File.join(__dir__, "config", "catalog.json"))
      end
    end
  end
end
```

### Step 3: Create Configuration Files

#### Meta Configuration
Create `integrations/lib/outhad/integrations/source/shopify/config/meta.json`:

```json
{
  "data": {
    "name": "Shopify",
    "title": "Shopify",
    "connector_type": "source",
    "category": "E-commerce",
    "documentation_url": "https://docs.outhad.ai/guides/sources/e-commerce/shopify",
    "github_issue_label": "source-shopify",
    "icon": "icon.svg",
    "license": "MIT",
    "release_stage": "alpha",
    "support_level": "community",
    "tags": ["language:ruby", "outhad", "e-commerce"]
  }
}
```

#### Connection Specification
Create `integrations/lib/outhad/integrations/source/shopify/config/spec.json`:

```json
{
  "documentation_url": "https://docs.outhad.ai/guides/sources/e-commerce/shopify",
  "stream_type": "static",
  "connection_specification": {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "Shopify",
    "type": "object",
    "required": ["shop_domain", "access_token"],
    "properties": {
      "shop_domain": {
        "type": "string",
        "title": "Shop Domain",
        "description": "Your Shopify store domain (e.g., mystore.myshopify.com)",
        "examples": ["mystore.myshopify.com"],
        "pattern": "^[a-zA-Z0-9][a-zA-Z0-9-]*\\.myshopify\\.com$",
        "order": 0
      },
      "access_token": {
        "type": "string",
        "title": "Access Token",
        "description": "Admin API access token from your Shopify store",
        "outhad_secret": true,
        "order": 1
      },
      "api_version": {
        "type": "string",
        "title": "API Version",
        "description": "Shopify API version to use",
        "default": "2024-07",
        "enum": ["2024-07", "2024-04", "2024-01"],
        "order": 2
      },
      "start_date": {
        "type": "string",
        "title": "Start Date",
        "description": "UTC date and time in the format YYYY-MM-DDTHH:MM:SSZ. Only data after this date will be replicated.",
        "examples": ["2023-01-01T00:00:00Z"],
        "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$",
        "format": "date-time",
        "order": 3
      }
    }
  }
}
```

#### Catalog Definition
Create `integrations/lib/outhad/integrations/source/shopify/config/catalog.json`:

```json
{
  "streams": [
    {
      "name": "products",
      "json_schema": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "title": { "type": "string" },
          "handle": { "type": "string" },
          "description": { "type": "string" },
          "vendor": { "type": "string" },
          "product_type": { "type": "string" },
          "tags": { "type": "array", "items": { "type": "string" } },
          "status": { "type": "string" },
          "created_at": { "type": "string", "format": "date-time" },
          "updated_at": { "type": "string", "format": "date-time" },
          "variants": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "id": { "type": "string" },
                "title": { "type": "string" },
                "sku": { "type": "string" },
                "price": { "type": "string" },
                "compare_at_price": { "type": "string" },
                "inventory_quantity": { "type": "integer" },
                "weight": { "type": "number" },
                "weight_unit": { "type": "string" }
              }
            }
          },
          "images": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "id": { "type": "string" },
                "url": { "type": "string" },
                "alt_text": { "type": "string" }
              }
            }
          }
        }
      }
    },
    {
      "name": "orders",
      "json_schema": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "name": { "type": "string" },
          "email": { "type": "string" },
          "created_at": { "type": "string", "format": "date-time" },
          "updated_at": { "type": "string", "format": "date-time" },
          "total_price": { "type": "string" },
          "currency": { "type": "string" },
          "subtotal_price": { "type": "string" },
          "total_tax": { "type": "string" },
          "financial_status": { "type": "string" },
          "fulfillment_status": { "type": "string" },
          "customer": {
            "type": "object",
            "properties": {
              "id": { "type": "string" },
              "email": { "type": "string" },
              "first_name": { "type": "string" },
              "last_name": { "type": "string" }
            }
          },
          "line_items": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "id": { "type": "string" },
                "title": { "type": "string" },
                "quantity": { "type": "integer" },
                "variant_id": { "type": "string" },
                "sku": { "type": "string" },
                "price": { "type": "string" },
                "currency": { "type": "string" }
              }
            }
          }
        }
      }
    },
    {
      "name": "customers",
      "json_schema": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "email": { "type": "string" },
          "first_name": { "type": "string" },
          "last_name": { "type": "string" },
          "phone": { "type": "string" },
          "created_at": { "type": "string", "format": "date-time" },
          "updated_at": { "type": "string", "format": "date-time" },
          "orders_count": { "type": "integer" },
          "total_spent": { "type": "string" },
          "currency": { "type": "string" },
          "addresses": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "id": { "type": "string" },
                "first_name": { "type": "string" },
                "last_name": { "type": "string" },
                "company": { "type": "string" },
                "address1": { "type": "string" },
                "address2": { "type": "string" },
                "city": { "type": "string" },
                "province": { "type": "string" },
                "country": { "type": "string" },
                "zip": { "type": "string" },
                "phone": { "type": "string" }
              }
            }
          },
          "tags": { "type": "array", "items": { "type": "string" } }
        }
      }
    },
    {
      "name": "collections",
      "json_schema": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "title": { "type": "string" },
          "handle": { "type": "string" },
          "description": { "type": "string" },
          "updated_at": { "type": "string", "format": "date-time" },
          "products_count": { "type": "integer" }
        }
      }
    }
  ]
}
```

## Destination Connector Implementation

### Step 1: Create Directory Structure

```bash
mkdir -p integrations/lib/outhad/integrations/destination/shopify/config
mkdir -p integrations/spec/outhad/integrations/destination/shopify
```

### Step 2: Implement Destination Client

Create `integrations/lib/outhad/integrations/destination/shopify/client.rb`:

```ruby
# frozen_string_literal: true

require 'shopify_api'

module Outhad
  module Integrations
    module Destination
      module Shopify
        include Outhad::Integrations::Core

        class Client < DestinationConnector
          prepend Outhad::Integrations::Core::RateLimiter

          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            test_connection
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_outhad_message
          rescue StandardError => e
            handle_exception(e, {
              context: "SHOPIFY:DESTINATION:DISCOVER:EXCEPTION",
              type: "error"
            })
          end

          def write(sync_config, records, action = "create")
            @sync_config = sync_config
            @action = sync_config.stream.action || action
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception(e, {
              context: "SHOPIFY:DESTINATION:WRITE:EXCEPTION",
              type: "error",
              sync_id: @sync_config.sync_id,
              sync_run_id: @sync_config.sync_run_id
            })
          end

          private

          def initialize_client(config)
            config = config.with_indifferent_access
            
            ShopifyAPI::Context.setup(
              api_key: config[:api_key],
              api_secret_key: config[:api_secret],
              host: config[:host],
              scope: "write_products,write_customers,write_orders",
              is_embedded: false,
              api_version: "2024-07",
              is_private: true
            )

            @session = ShopifyAPI::Auth::Session.new(
              shop: config[:shop_domain],
              access_token: config[:access_token]
            )
            
            @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
          end

          def test_connection
            query = <<~GRAPHQL
              query {
                shop {
                  id
                  name
                }
              }
            GRAPHQL
            
            response = @client.query(query: query)
            raise "Connection failed" if response.body["errors"]
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0
            
            records.each do |record_object|
              record = extract_data(record_object, stream.json_schema[:properties])
              
              begin
                case stream.name
                when "products"
                  result = process_product(record)
                when "customers"
                  result = process_customer(record)
                else
                  raise "Unsupported stream: #{stream.name}"
                end
                
                write_success += 1
                log_message_array << log_request_response("info", [stream.name, record], result)
              rescue StandardError => e
                write_failure += 1
                log_message_array << log_request_response("error", [stream.name, record], e.message)
                handle_exception(e, {
                  context: "SHOPIFY:DESTINATION:PROCESS_RECORD:EXCEPTION",
                  type: "error",
                  sync_id: @sync_config.sync_id,
                  sync_run_id: @sync_config.sync_run_id
                })
              end
            end
            
            tracking_message(write_success, write_failure, log_message_array)
          end

          def process_product(record)
            case @action
            when "create"
              create_product(record)
            when "update"
              update_product(record)
            when "upsert"
              upsert_product(record)
            else
              raise "Unsupported action: #{@action}"
            end
          end

          def create_product(record)
            mutation = build_product_create_mutation(record)
            response = @client.query(query: mutation)
            handle_graphql_errors(response)
            response.body.dig("data", "productCreate", "product")
          end

          def update_product(record)
            mutation = build_product_update_mutation(record)
            response = @client.query(query: mutation)
            handle_graphql_errors(response)
            response.body.dig("data", "productUpdate", "product")
          end

          def upsert_product(record)
            # Try to find existing product by handle or external ID
            existing_product = find_product(record)
            
            if existing_product
              record["id"] = existing_product["id"]
              update_product(record)
            else
              create_product(record)
            end
          end

          def find_product(record)
            handle = record["handle"]
            return nil unless handle
            
            query = <<~GRAPHQL
              query($handle: String!) {
                productByHandle(handle: $handle) {
                  id
                  handle
                }
              }
            GRAPHQL
            
            response = @client.query(
              query: query,
              variables: { handle: handle }
            )
            
            response.body.dig("data", "productByHandle")
          end

          def build_product_create_mutation(record)
            input = build_product_input(record)
            
            {
              query: <<~GRAPHQL,
                mutation productCreate($input: ProductInput!) {
                  productCreate(input: $input) {
                    product {
                      id
                      title
                      handle
                    }
                    userErrors {
                      field
                      message
                    }
                  }
                }
              GRAPHQL
              variables: { input: input }
            }
          end

          def build_product_update_mutation(record)
            input = build_product_input(record)
            input[:id] = record["id"]
            
            {
              query: <<~GRAPHQL,
                mutation productUpdate($input: ProductInput!) {
                  productUpdate(input: $input) {
                    product {
                      id
                      title
                      handle
                    }
                    userErrors {
                      field
                      message
                    }
                  }
                }
              GRAPHQL
              variables: { input: input }
            }
          end

          def build_product_input(record)
            input = {}
            
            input[:title] = record["title"] if record["title"]
            input[:handle] = record["handle"] if record["handle"]
            input[:description] = record["description"] if record["description"]
            input[:vendor] = record["vendor"] if record["vendor"]
            input[:productType] = record["product_type"] if record["product_type"]
            input[:tags] = record["tags"] if record["tags"]
            input[:status] = record["status"]&.upcase if record["status"]
            
            # Handle variants
            if record["variants"] && record["variants"].any?
              input[:variants] = record["variants"].map do |variant|
                build_variant_input(variant)
              end
            end
            
            # Handle images
            if record["images"] && record["images"].any?
              input[:images] = record["images"].map do |image|
                { src: image["url"], altText: image["alt_text"] }
              end
            end
            
            input
          end

          def build_variant_input(variant)
            input = {}
            
            input[:title] = variant["title"] if variant["title"]
            input[:sku] = variant["sku"] if variant["sku"]
            input[:price] = variant["price"] if variant["price"]
            input[:compareAtPrice] = variant["compare_at_price"] if variant["compare_at_price"]
            input[:inventoryQuantities] = [
              {
                availableQuantity: variant["inventory_quantity"] || 0,
                locationId: "gid://shopify/Location/1" # Default location
              }
            ] if variant["inventory_quantity"]
            input[:weight] = variant["weight"] if variant["weight"]
            input[:weightUnit] = variant["weight_unit"]&.upcase if variant["weight_unit"]
            
            input
          end

          def process_customer(record)
            case @action
            when "create"
              create_customer(record)
            when "update"
              update_customer(record)
            when "upsert"
              upsert_customer(record)
            else
              raise "Unsupported action: #{@action}"
            end
          end

          def create_customer(record)
            mutation = build_customer_create_mutation(record)
            response = @client.query(query: mutation)
            handle_graphql_errors(response)
            response.body.dig("data", "customerCreate", "customer")
          end

          def update_customer(record)
            mutation = build_customer_update_mutation(record)
            response = @client.query(query: mutation)
            handle_graphql_errors(response)
            response.body.dig("data", "customerUpdate", "customer")
          end

          def upsert_customer(record)
            existing_customer = find_customer(record)
            
            if existing_customer
              record["id"] = existing_customer["id"]
              update_customer(record)
            else
              create_customer(record)
            end
          end

          def find_customer(record)
            email = record["email"]
            return nil unless email
            
            query = <<~GRAPHQL
              query($email: String!) {
                customers(first: 1, query: $email) {
                  edges {
                    node {
                      id
                      email
                    }
                  }
                }
              }
            GRAPHQL
            
            response = @client.query(
              query: query,
              variables: { email: "email:#{email}" }
            )
            
            customers = response.body.dig("data", "customers", "edges")
            customers&.first&.dig("node")
          end

          def build_customer_create_mutation(record)
            input = build_customer_input(record)
            
            {
              query: <<~GRAPHQL,
                mutation customerCreate($input: CustomerInput!) {
                  customerCreate(input: $input) {
                    customer {
                      id
                      email
                      firstName
                      lastName
                    }
                    userErrors {
                      field
                      message
                    }
                  }
                }
              GRAPHQL
              variables: { input: input }
            }
          end

          def build_customer_update_mutation(record)
            input = build_customer_input(record)
            input[:id] = record["id"]
            
            {
              query: <<~GRAPHQL,
                mutation customerUpdate($input: CustomerInput!) {
                  customerUpdate(input: $input) {
                    customer {
                      id
                      email
                      firstName
                      lastName
                    }
                    userErrors {
                      field
                      message
                    }
                  }
                }
              GRAPHQL
              variables: { input: input }
            }
          end

          def build_customer_input(record)
            input = {}
            
            input[:email] = record["email"] if record["email"]
            input[:firstName] = record["first_name"] if record["first_name"]
            input[:lastName] = record["last_name"] if record["last_name"]
            input[:phone] = record["phone"] if record["phone"]
            input[:tags] = record["tags"] if record["tags"]
            
            # Handle addresses
            if record["addresses"] && record["addresses"].any?
              input[:addresses] = record["addresses"].map do |address|
                build_address_input(address)
              end
            end
            
            input
          end

          def build_address_input(address)
            {
              firstName: address["first_name"],
              lastName: address["last_name"],
              company: address["company"],
              address1: address["address1"],
              address2: address["address2"],
              city: address["city"],
              province: address["province"],
              country: address["country"],
              zip: address["zip"],
              phone: address["phone"]
            }.compact
          end

          def handle_graphql_errors(response)
            if response.body["errors"]
              errors = response.body["errors"].map { |e| e["message"] }.join(", ")
              raise "GraphQL errors: #{errors}"
            end
            
            # Check for user errors in mutations
            data = response.body["data"]
            if data
              data.values.each do |result|
                if result.is_a?(Hash) && result["userErrors"] && result["userErrors"].any?
                  user_errors = result["userErrors"].map { |e| "#{e['field']}: #{e['message']}" }.join(", ")
                  raise "User errors: #{user_errors}"
                end
              end
            end
          end

          def load_catalog
            read_json(File.join(__dir__, "config", "catalog.json"))
          end
        end
      end
    end
  end
end
```

### Step 3: Create Destination Configuration Files

#### Meta Configuration
Create `integrations/lib/outhad/integrations/destination/shopify/config/meta.json`:

```json
{
  "data": {
    "name": "Shopify",
    "title": "Shopify",
    "connector_type": "destination",
    "category": "E-commerce",
    "documentation_url": "https://docs.outhad.ai/guides/destinations/e-commerce/shopify",
    "github_issue_label": "destination-shopify",
    "icon": "icon.svg",
    "license": "MIT",
    "release_stage": "alpha",
    "support_level": "community",
    "tags": ["language:ruby", "outhad", "e-commerce"]
  }
}
```

#### Connection Specification
Create `integrations/lib/outhad/integrations/destination/shopify/config/spec.json`:

```json
{
  "documentation_url": "https://docs.outhad.ai/guides/destinations/e-commerce/shopify",
  "stream_type": "static",
  "connection_specification": {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "Shopify",
    "type": "object",
    "required": ["shop_domain", "access_token"],
    "properties": {
      "shop_domain": {
        "type": "string",
        "title": "Shop Domain",
        "description": "Your Shopify store domain (e.g., mystore.myshopify.com)",
        "examples": ["mystore.myshopify.com"],
        "pattern": "^[a-zA-Z0-9][a-zA-Z0-9-]*\\.myshopify\\.com$",
        "order": 0
      },
      "access_token": {
        "type": "string",
        "title": "Access Token",
        "description": "Admin API access token with write permissions",
        "outhad_secret": true,
        "order": 1
      },
      "api_version": {
        "type": "string",
        "title": "API Version",
        "description": "Shopify API version to use",
        "default": "2024-07",
        "enum": ["2024-07", "2024-04", "2024-01"],
        "order": 2
      }
    }
  }
}
```

#### Catalog Definition
Create `integrations/lib/outhad/integrations/destination/shopify/config/catalog.json`:

```json
{
  "streams": [
    {
      "name": "products",
      "action": "create",
      "json_schema": {
        "type": "object",
        "required": ["title"],
        "properties": {
          "id": { "type": "string" },
          "title": { "type": "string" },
          "handle": { "type": "string" },
          "description": { "type": "string" },
          "vendor": { "type": "string" },
          "product_type": { "type": "string" },
          "tags": { "type": "array", "items": { "type": "string" } },
          "status": { 
            "type": "string",
            "enum": ["active", "archived", "draft"]
          },
          "variants": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "title": { "type": "string" },
                "sku": { "type": "string" },
                "price": { "type": "string" },
                "compare_at_price": { "type": "string" },
                "inventory_quantity": { "type": "integer" },
                "weight": { "type": "number" },
                "weight_unit": { 
                  "type": "string",
                  "enum": ["g", "kg", "lb", "oz"]
                }
              }
            }
          },
          "images": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "url": { "type": "string", "format": "uri" },
                "alt_text": { "type": "string" }
              },
              "required": ["url"]
            }
          }
        }
      }
    },
    {
      "name": "customers",
      "action": "create",
      "json_schema": {
        "type": "object",
        "required": ["email"],
        "properties": {
          "id": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "first_name": { "type": "string" },
          "last_name": { "type": "string" },
          "phone": { "type": "string" },
          "tags": { "type": "array", "items": { "type": "string" } },
          "addresses": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "first_name": { "type": "string" },
                "last_name": { "type": "string" },
                "company": { "type": "string" },
                "address1": { "type": "string" },
                "address2": { "type": "string" },
                "city": { "type": "string" },
                "province": { "type": "string" },
                "country": { "type": "string" },
                "zip": { "type": "string" },
                "phone": { "type": "string" }
              }
            }
          }
        }
      }
    }
  ]
}
```

## Testing Implementation

### Step 1: Create Test Files

Create `integrations/spec/outhad/integrations/source/shopify/client_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Outhad::Integrations::Source::Shopify::Client do
  let(:connection_config) do
    {
      shop_domain: "test-store.myshopify.com",
      access_token: "test_token",
      api_version: "2024-07"
    }
  end

  let(:client) { described_class.new }

  describe '#check_connection' do
    context 'with valid credentials' do
      it 'returns success status' do
        # Mock successful API response
        allow_any_instance_of(ShopifyAPI::Clients::Graphql::Admin)
          .to receive(:query)
          .and_return(double(body: { "data" => { "shop" => { "id" => "1", "name" => "Test Store" } } }))

        result = client.check_connection(connection_config)
        expect(result[:status]).to eq("succeeded")
      end
    end

    context 'with invalid credentials' do
      it 'returns failure status' do
        allow_any_instance_of(ShopifyAPI::Clients::Graphql::Admin)
          .to receive(:query)
          .and_raise(StandardError.new("Unauthorized"))

        result = client.check_connection(connection_config)
        expect(result[:status]).to eq("failed")
      end
    end
  end

  describe '#discover' do
    it 'returns catalog with streams' do
      result = client.discover(connection_config)
      catalog = JSON.parse(result)
      
      expect(catalog["streams"]).to be_an(Array)
      expect(catalog["streams"].map { |s| s["name"] }).to include("products", "orders", "customers", "collections")
    end
  end

  describe '#read' do
    let(:sync_config) do
      double(
        source: double(connection_specification: connection_config),
        stream: double(name: "products"),
        sync_id: "sync_123",
        sync_run_id: "run_456"
      )
    end

    context 'when reading products' do
      it 'returns product records' do
        mock_response = {
          "data" => {
            "products" => {
              "edges" => [
                {
                  "cursor" => "cursor1",
                  "node" => {
                    "id" => "gid://shopify/Product/1",
                    "title" => "Test Product",
                    "handle" => "test-product",
                    "description" => "A test product",
                    "vendor" => "Test Vendor",
                    "productType" => "Test Type",
                    "tags" => ["test"],
                    "status" => "ACTIVE",
                    "createdAt" => "2024-01-01T00:00:00Z",
                    "updatedAt" => "2024-01-01T00:00:00Z",
                    "variants" => { "edges" => [] },
                    "images" => { "edges" => [] }
                  }
                }
              ],
              "pageInfo" => {
                "hasNextPage" => false,
                "hasPreviousPage" => false
              }
            }
          }
        }

        allow_any_instance_of(ShopifyAPI::Clients::Graphql::Admin)
          .to receive(:query)
          .and_return(double(body: mock_response))

        records = client.read(sync_config)
        expect(records).to be_an(Array)
        expect(records.first).to include("data", "emitted_at")
      end
    end
  end
end
```

Create `integrations/spec/outhad/integrations/destination/shopify/client_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Outhad::Integrations::Destination::Shopify::Client do
  let(:connection_config) do
    {
      shop_domain: "test-store.myshopify.com",
      access_token: "test_token",
      api_version: "2024-07"
    }
  end

  let(:client) { described_class.new }

  describe '#check_connection' do
    context 'with valid credentials' do
      it 'returns success status' do
        allow_any_instance_of(ShopifyAPI::Clients::Graphql::Admin)
          .to receive(:query)
          .and_return(double(body: { "data" => { "shop" => { "id" => "1", "name" => "Test Store" } } }))

        result = client.check_connection(connection_config)
        expect(result[:status]).to eq("succeeded")
      end
    end
  end

  describe '#write' do
    let(:sync_config) do
      double(
        destination: double(connection_specification: connection_config),
        stream: double(
          name: "products",
          action: "create",
          json_schema: { properties: { title: { type: "string" } } }
        ),
        sync_id: "sync_123",
        sync_run_id: "run_456"
      )
    end

    let(:records) do
      [
        {
          "data" => {
            "title" => "Test Product",
            "handle" => "test-product",
            "description" => "A test product"
          },
          "emitted_at" => Time.now.to_i
        }
      ]
    end

    context 'when writing products' do
      it 'creates products successfully' do
        mock_response = {
          "data" => {
            "productCreate" => {
              "product" => {
                "id" => "gid://shopify/Product/1",
                "title" => "Test Product",
                "handle" => "test-product"
              },
              "userErrors" => []
            }
          }
        }

        allow_any_instance_of(ShopifyAPI::Clients::Graphql::Admin)
          .to receive(:query)
          .and_return(double(body: mock_response))

        result = client.write(sync_config, records, "create")
        tracking = JSON.parse(result)
        
        expect(tracking["success"]).to eq(1)
        expect(tracking["failed"]).to eq(0)
      end
    end
  end
end
```

### Step 2: Add Gemfile Dependencies

Add to `integrations/Gemfile`:

```ruby
gem 'shopify_api', '~> 13.0'
```

Then run:

```bash
cd integrations
bundle install
```

### Step 3: Run Tests

```bash
cd integrations
bundle exec rspec spec/outhad/integrations/source/shopify/client_spec.rb
bundle exec rspec spec/outhad/integrations/destination/shopify/client_spec.rb
```

## Registration and Rollout

### Step 1: Add Icons

Add Shopify SVG icons:
- `integrations/lib/outhad/integrations/source/shopify/icon.svg`
- `integrations/lib/outhad/integrations/destination/shopify/icon.svg`

### Step 2: Register in Rollout

Edit `integrations/lib/outhad/integrations/rollout.rb`:

```ruby
ENABLED_SOURCES = %w[
  # ... existing sources ...
  Shopify
].freeze

ENABLED_DESTINATIONS = %w[
  # ... existing destinations ...
  Shopify
].freeze
```

### Step 3: Test Integration

```bash
# Test source connector
cd integrations
bundle exec rspec spec/outhad/integrations/source/shopify/

# Test destination connector
bundle exec rspec spec/outhad/integrations/destination/shopify/

# Run all tests
bundle exec rspec
```

## Development Workflow

### Step 1: Test with Hot Reloading

With the hot reloading system in place, you can:

1. Make changes to connector files
2. Changes automatically reload in the running container
3. Test via API without container restart

### Step 2: Verify in UI

1. Start the stack: `docker-compose up`
2. Access UI at `http://localhost:8000`
3. Verify Shopify appears in source/destination lists
4. Test connection configuration

### Step 3: API Testing

Test via connector definitions API:

```bash
curl -X GET "http://localhost:3000/api/v1/connector_definitions" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Workspace-Id: YOUR_WORKSPACE_ID"
```

## Best Practices

### 1. Error Handling

- Always wrap API calls in try-catch blocks
- Provide meaningful error messages
- Log errors with context for debugging

### 2. Rate Limiting

- Use the built-in `RateLimiter` prepend
- Respect Shopify's rate limits
- Implement exponential backoff for retries

### 3. Data Transformation

- Keep transformations simple and predictable
- Handle null/missing fields gracefully
- Validate data before sending to destination

### 4. Security

- Never log sensitive data (access tokens, etc.)
- Use `outhad_secret: true` for sensitive fields
- Validate input data

### 5. Performance

- Use pagination for large datasets
- Limit field selection in GraphQL queries
- Process records in batches

### 6. Testing

- Write comprehensive unit tests
- Mock external API calls
- Test error scenarios
- Validate data transformations

### 7. Documentation

- Document configuration requirements
- Provide clear examples
- Include troubleshooting guides

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify access token permissions
   - Check API version compatibility
   - Ensure shop domain format is correct

2. **Rate Limiting**
   - Reduce pagination size
   - Add delays between requests
   - Use GraphQL instead of REST

3. **Data Validation Errors**
   - Check required fields
   - Validate data types
   - Handle enum values correctly

4. **Hot Reloading Not Working**
   - Check file paths are correct
   - Verify rollout.rb registration
   - Restart container if needed

### Debugging Tips

1. **Enable Debug Logging**
   ```ruby
   Rails.logger.debug "Debug message"
   ```

2. **Check API Responses**
   ```ruby
   puts response.body.inspect
   ```

3. **Validate GraphQL Queries**
   Use Shopify's GraphiQL explorer to test queries

4. **Monitor Rate Limits**
   Check response headers for rate limit info

This comprehensive guide provides everything needed to implement Shopify source and destination connectors in the Outhad platform, following the established patterns and best practices of the existing codebase.